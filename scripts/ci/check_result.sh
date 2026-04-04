#!/usr/bin/env bash

set -euo pipefail

echo "[result] Installing dependencies and running checks"
pushd result >/dev/null
npm ci
npm run ci:test
popd >/dev/null
