# Planet 4 OpenResty Static Site Helm Chart

[![Planet4](https://cdn-images-1.medium.com/letterbox/300/36/50/50/1*XcutrEHk0HYv-spjnOej2w.png?source=logoAvatar-ec5f4e3b2e43---fded7925f62)](https://medium.com/planet4)

Builds on https://github.com/greenpeace/planet4-docker

Charts stored in Google Cloud Storage bucket gs://planet4-helm-charts

---

## Quickstart

Create and modify a `values-local.yaml` file, then deploy to cluster via:

```
# Add alias to remote repository
helm repo add p4 https://planet4-helm-charts.storage.googleapis.com

# Install/upgrade command
RELEASE_NAME=p4-release-name make deploy
```

---

## Updating repository with new chart version

```
make
```

The simple command `make` will:
-   Create a directory (../planet4-helm-charts by default) to store chart bucket contents
-   Pull contents of P4 Helm GCS bucket
-   Package the current directory as a new chart version
-   Move the packaged chart to the local chart directory
-   Update the index
-   Synchronise local chart directory with GCS bucket contents

For managing repository updates it is strongly recommended to use https://github.com/viglesiasce/helm-gcs
