#!/usr/bin/env bash

set -euo pipefail

IMAGE_VOTE_TAGS="${IMAGE_VOTE_TAGS:-${IMAGE_VOTE:-}}"
IMAGE_RESULT_TAGS="${IMAGE_RESULT_TAGS:-${IMAGE_RESULT:-}}"
IMAGE_WORKER_TAGS="${IMAGE_WORKER_TAGS:-${IMAGE_WORKER:-}}"

: "${IMAGE_VOTE_TAGS:?IMAGE_VOTE_TAGS or IMAGE_VOTE is required}"
: "${IMAGE_RESULT_TAGS:?IMAGE_RESULT_TAGS or IMAGE_RESULT is required}"
: "${IMAGE_WORKER_TAGS:?IMAGE_WORKER_TAGS or IMAGE_WORKER is required}"

push_csv_tags() {
	local csv_tags="${1}"
	IFS=',' read -r -a tag_array <<<"${csv_tags}"
	for image_tag in "${tag_array[@]}"; do
		if [[ -n "${image_tag}" ]]; then
			docker push "${image_tag}"
		fi
	done
}

echo "Pushing images:"
echo "- ${IMAGE_VOTE_TAGS}"
echo "- ${IMAGE_RESULT_TAGS}"
echo "- ${IMAGE_WORKER_TAGS}"

push_csv_tags "${IMAGE_VOTE_TAGS}"
push_csv_tags "${IMAGE_RESULT_TAGS}"
push_csv_tags "${IMAGE_WORKER_TAGS}"
