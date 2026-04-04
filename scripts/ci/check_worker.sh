#!/usr/bin/env bash

set -euo pipefail

echo "[worker] Running Go validation"
pushd worker >/dev/null
go test ./...
go vet ./...
go build -o /tmp/worker main.go
popd >/dev/null
