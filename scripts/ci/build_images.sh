#!/usr/bin/env bash

set -euo pipefail

TAG="${TAG:-dev-${GITHUB_SHA:-local}}"
REPO="${IMAGE_REPOSITORY:-${GITHUB_REPOSITORY:-local/microservices-demo}}"
REPO_LOWER="${REPO,,}"
REGISTRY="${REGISTRY:-ghcr.io}"

IMAGE_VOTE="${REGISTRY}/${REPO_LOWER}/vote:${TAG}"
IMAGE_RESULT="${REGISTRY}/${REPO_LOWER}/result:${TAG}"
IMAGE_WORKER="${REGISTRY}/${REPO_LOWER}/worker:${TAG}"

echo "Building images:"
echo "- ${IMAGE_VOTE}"
echo "- ${IMAGE_RESULT}"
echo "- ${IMAGE_WORKER}"

docker build -t "${IMAGE_VOTE}" vote
docker build -t "${IMAGE_RESULT}" result
docker build -t "${IMAGE_WORKER}" worker

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "image_vote=${IMAGE_VOTE}"
    echo "image_result=${IMAGE_RESULT}"
    echo "image_worker=${IMAGE_WORKER}"
  } >>"${GITHUB_OUTPUT}"
fi
