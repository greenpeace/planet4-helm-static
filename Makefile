SHELL := /bin/bash
.ONESHELL:

CHART_DIRECTORY ?= ../../planet4-helm-charts

CHART_BUCKET ?= gs://planet4-helm-charts
CHART_URL ?= https://planet4-helm-charts.storage.googleapis.com

CHART_NAME := $(shell basename "$(PWD)")

RELEASE_NAME ?= test-static

.PHONY: all
all: lint pull dep package index push

.PHONY: lint
lint:
	@helm lint .

.PHONY: dep
dep: lint
	@helm dependency update

.PHONY: pull
pull:
	@mkdir -p $(CHART_DIRECTORY)
	@pushd $(CHART_DIRECTORY) > /dev/null && \
	gsutil -m rsync -d $(CHART_BUCKET) . && \
	popd > /dev/null

.PHONY: package
package: lint
	@helm package .
	@mv $(CHART_NAME)-*.tgz $(CHART_DIRECTORY)

.PHONY: verify
verify: lint
	@helm verify $(CHART_DIRECTORY)

.PHONY: index
index: lint
	@pushd $(CHART_DIRECTORY) > /dev/null && \
	helm repo index . --url $(CHART_URL) && \
	popd > /dev/null

.PHONY: push
push:
	@pushd $(CHART_DIRECTORY) > /dev/null && \
	gsutil -m rsync -d . $(CHART_BUCKET) && \
	popd > /dev/null

.PHONY: deploy
deploy:
	helm upgrade --install $(RELEASE_NAME) . \
			--values values-local.yaml
