#!/usr/bin/env bash

set -euo pipefail

ALL_SERVICES='["vote","result","worker"]'

BASE_REF="${1:-}"
HEAD_REF="${2:-}"

if [[ -z "${BASE_REF}" || -z "${HEAD_REF}" ]]; then
  if [[ "${GITHUB_EVENT_NAME:-}" == "pull_request" && -n "${GITHUB_BASE_REF:-}" ]]; then
    git fetch --no-tags --depth=1 origin "${GITHUB_BASE_REF}" >/dev/null 2>&1 || true
    BASE_REF="$(git merge-base HEAD "origin/${GITHUB_BASE_REF}")"
    HEAD_REF="HEAD"
  elif git rev-parse HEAD~1 >/dev/null 2>&1; then
    BASE_REF="HEAD~1"
    HEAD_REF="HEAD"
  else
    BASE_REF="HEAD"
    HEAD_REF="HEAD"
  fi
fi

if [[ "${BASE_REF}" == "${HEAD_REF}" ]]; then
  SERVICES_JSON="${ALL_SERVICES}"
else
  CHANGED_FILES="$(git diff --name-only "${BASE_REF}" "${HEAD_REF}" || true)"

  SERVICES=()
  if grep -qE '^vote/' <<<"${CHANGED_FILES}"; then SERVICES+=("vote"); fi
  if grep -qE '^result/' <<<"${CHANGED_FILES}"; then SERVICES+=("result"); fi
  if grep -qE '^worker/' <<<"${CHANGED_FILES}"; then SERVICES+=("worker"); fi
  if grep -qE '^scripts/ci/' <<<"${CHANGED_FILES}"; then SERVICES=("vote" "result" "worker"); fi
  if grep -qE '^\.github/workflows/' <<<"${CHANGED_FILES}"; then SERVICES=("vote" "result" "worker"); fi

  if [[ ${#SERVICES[@]} -eq 0 ]]; then
    SERVICES_JSON="${ALL_SERVICES}"
  else
    SERVICES_JSON='['
    for SERVICE in "${SERVICES[@]}"; do
      if [[ "${SERVICES_JSON}" != '[' ]]; then
        SERVICES_JSON+=','
      fi
      SERVICES_JSON+="\"${SERVICE}\""
    done
    SERVICES_JSON+=']'
  fi
fi

echo "Detected services matrix: ${SERVICES_JSON}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "services_matrix=${SERVICES_JSON}" >>"${GITHUB_OUTPUT}"
fi
