SHELL := /bin/bash

.EXPORT_ALL_VARIABLES:

CHART_DIRECTORY ?= ../planet4-helm-charts

CHART_BUCKET ?= gs://planet4-helm-charts
CHART_URL ?= https://planet4-helm-charts.storage.googleapis.com

CHART_NAME := $(shell basename "$(PWD)")

SED_MATCH := [^a-zA-Z0-9._-]

# If BUILD_TAG is not set
ifeq ($(strip $(BUILD_TAG)),)
ifeq ($(CIRCLECI),true)
# Configure build variables based on CircleCI environment vars
BUILD_TAG ?= $(shell sed 's/$(SED_MATCH)/-/g' <<< "$(CIRCLE_TAG)")
else
# Not in CircleCI environment, try to set sane defaults
BUILD_TAG ?= $(shell git tag -l --points-at HEAD | tail -n1 | sed 's/$(SED_MATCH)/-/g')
endif
endif

# If BUILD_TAG is blank there's no tag on this commit
ifeq ($(strip $(BUILD_TAG)),)
# Default to branch name - this will lint but not package
BUILD_TAG := testing
endif

.PHONY: all
all: clean pull dep lint package index push update

init: .git/hooks/pre-commit
	@git update-index --assume-unchanged Chart.yaml
	@git update-index --assume-unchanged requirements.yaml

.git/hooks/pre-commit:
	@chmod 755 .githooks/*
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;

.PHONY: clean
clean: init
	@rm -f Chart.yaml requirements.yaml

.PHONY: lint
lint: lint-yaml lint-helm

.PHONY: lint-yaml
lint-yaml: Chart.yaml requirements.yaml
	@yamllint .circleci/config.yml
	@yamllint Chart.yaml
	@yamllint values.yaml
	@yamllint requirements.yaml

.PHONY: lint-helm
	@helm lint .

.PHONY: dep
dep: lint
	@helm dependency update

$(CHART_DIRECTORY):
	@mkdir -p $@

.PHONY: pull
pull: $(CHART_DIRECTORY)
	@gcloud storage rsync $(CHART_BUCKET) $(CHART_DIRECTORY) --delete-unmatched-destination-objects

.PHONY: rewrite rewrite-chart rewrite-requirements
rewrite: Chart.yaml requirements.yaml

Chart.yaml:
	@envsubst < Chart.yaml.in > Chart.yaml

requirements.yaml:
	@envsubst < requirements.yaml.in > requirements.yaml

.PHONY: package
package: lint Chart.yaml
	@[[ $(BUILD_TAG) =~ ^[0-9]+\.[0-9]+ ]] || { \
		>&2 echo "ERROR: Refusing to package non-semver release: '$(BUILD_TAG)'"; \
		exit 1; \
	}
	@helm package .
	@mv $(CHART_NAME)-*.tgz $(CHART_DIRECTORY)

.PHONY: verify
verify: lint
	@helm verify $(CHART_DIRECTORY)

.PHONY: index
index: lint $(CHART_DIRECTORY)
	@helm repo index $(CHART_DIRECTORY) --url $(CHART_URL)

.PHONY: push
push: package $(CHART_DIRECTORY)
	@gcloud storage rsync $(CHART_BUCKET) $(CHART_DIRECTORY) --delete-unmatched-destination-objects

.PHONY: update
update:
	@helm repo update
	@helm search repo p4 $(CHART_NAME)
