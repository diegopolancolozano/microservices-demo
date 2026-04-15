#!/usr/bin/env bash

set -euo pipefail

retry_command() {
	local attempts="$1"
	local delay_seconds="$2"
	shift 2

	local n=1
	until "$@"; do
		if [[ "$n" -ge "$attempts" ]]; then
			echo "[worker] Command failed after ${attempts} attempts: $*"
			return 1
		fi
		echo "[worker] Retry ${n}/${attempts} failed. Waiting ${delay_seconds}s..."
		sleep "$delay_seconds"
		n=$((n + 1))
	done
}

echo "[worker] Running Go validation"
pushd worker >/dev/null
retry_command 3 5 go mod download
retry_command 3 5 go test ./...
go vet ./...
go build ./...
popd >/dev/null
