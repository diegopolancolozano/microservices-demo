#!/usr/bin/env bash

set -euo pipefail

IMAGE_VOTE="${IMAGE_VOTE:?IMAGE_VOTE is required}"
IMAGE_RESULT="${IMAGE_RESULT:?IMAGE_RESULT is required}"
IMAGE_WORKER="${IMAGE_WORKER:?IMAGE_WORKER is required}"

echo "Pushing images:"
echo "- ${IMAGE_VOTE}"
echo "- ${IMAGE_RESULT}"
echo "- ${IMAGE_WORKER}"

docker push "${IMAGE_VOTE}"
docker push "${IMAGE_RESULT}"
docker push "${IMAGE_WORKER}"
