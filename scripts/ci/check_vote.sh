#!/usr/bin/env bash

set -euo pipefail

echo "[vote] Running Maven verify"
pushd vote >/dev/null
mvn -B -ntp clean verify
popd >/dev/null
