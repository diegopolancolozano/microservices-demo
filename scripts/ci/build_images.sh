#!/usr/bin/env bash

set -euo pipefail

TAG="${TAG:-dev-${GITHUB_SHA:-local}}"
REPO="${IMAGE_REPOSITORY:-${GITHUB_REPOSITORY:-local/microservices-demo}}"
REPO_LOWER="${REPO,,}"
REGISTRY="${REGISTRY:-ghcr.io}"
EXTRA_TAGS="${EXTRA_TAGS:-}"

IMAGE_VOTE="${REGISTRY}/${REPO_LOWER}/vote:${TAG}"
IMAGE_RESULT="${REGISTRY}/${REPO_LOWER}/result:${TAG}"
IMAGE_WORKER="${REGISTRY}/${REPO_LOWER}/worker:${TAG}"

VOTE_TAGS=("${IMAGE_VOTE}")
RESULT_TAGS=("${IMAGE_RESULT}")
WORKER_TAGS=("${IMAGE_WORKER}")

normalize_tag() {
  local raw="${1}"
  raw="${raw#${raw%%[![:space:]]*}}"
  raw="${raw%${raw##*[![:space:]]}}"
  echo "${raw}"
}

add_extra_tags() {
  local service="${1}"
  local primary_image="${2}"
  shift 2

  IFS=',' read -r -a extra_tags <<<"${EXTRA_TAGS}"
  for raw_tag in "${extra_tags[@]}"; do
    local extra_tag
    extra_tag="$(normalize_tag "${raw_tag}")"
    if [[ -z "${extra_tag}" ]]; then
      continue
    fi

    local extra_image="${REGISTRY}/${REPO_LOWER}/${service}:${extra_tag}"
    docker tag "${primary_image}" "${extra_image}"

    case "${service}" in
      vote) VOTE_TAGS+=("${extra_image}") ;;
      result) RESULT_TAGS+=("${extra_image}") ;;
      worker) WORKER_TAGS+=("${extra_image}") ;;
    esac
  done
}

join_by_comma() {
  local -n arr_ref=$1
  local out=""
  for item in "${arr_ref[@]}"; do
    if [[ -n "${out}" ]]; then
      out+=','
    fi
    out+="${item}"
  done
  echo "${out}"
}

echo "Building images:"
echo "- ${IMAGE_VOTE}"
echo "- ${IMAGE_RESULT}"
echo "- ${IMAGE_WORKER}"

docker build -t "${IMAGE_VOTE}" vote
docker build -t "${IMAGE_RESULT}" result
docker build -t "${IMAGE_WORKER}" worker

if [[ -n "${EXTRA_TAGS}" ]]; then
  echo "Applying extra tags: ${EXTRA_TAGS}"
  add_extra_tags "vote" "${IMAGE_VOTE}"
  add_extra_tags "result" "${IMAGE_RESULT}"
  add_extra_tags "worker" "${IMAGE_WORKER}"
fi

IMAGE_VOTE_TAGS="$(join_by_comma VOTE_TAGS)"
IMAGE_RESULT_TAGS="$(join_by_comma RESULT_TAGS)"
IMAGE_WORKER_TAGS="$(join_by_comma WORKER_TAGS)"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    echo "image_vote=${IMAGE_VOTE}"
    echo "image_result=${IMAGE_RESULT}"
    echo "image_worker=${IMAGE_WORKER}"
    echo "image_vote_tags=${IMAGE_VOTE_TAGS}"
    echo "image_result_tags=${IMAGE_RESULT_TAGS}"
    echo "image_worker_tags=${IMAGE_WORKER_TAGS}"
  } >>"${GITHUB_OUTPUT}"
fi
