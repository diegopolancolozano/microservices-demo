#!/usr/bin/env bash

set -euo pipefail

retry_command() {
	local attempts="$1"
	local delay_seconds="$2"
	shift 2

	local n=1
	until "$@"; do
		if [[ "$n" -ge "$attempts" ]]; then
			echo "[vote] Command failed after ${attempts} attempts: $*"
			return 1
		fi
		echo "[vote] Retry ${n}/${attempts} failed. Waiting ${delay_seconds}s..."
		sleep "$delay_seconds"
		n=$((n + 1))
	done
}

ensure_maven() {
	if command -v mvn >/dev/null 2>&1; then
		return
	fi

	echo "[vote] Maven not found. Installing Maven..."

	if command -v apt-get >/dev/null 2>&1; then
		if command -v sudo >/dev/null 2>&1; then
			retry_command 3 5 sudo apt-get update
			retry_command 3 5 sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y maven
		else
			retry_command 3 5 apt-get update
			retry_command 3 5 env DEBIAN_FRONTEND=noninteractive apt-get install -y maven
		fi
		return
	fi

	echo "[vote] ERROR: Maven is required but no supported package manager was found."
	exit 1
}

ensure_maven

echo "[vote] Running Maven verify"
pushd vote >/dev/null
retry_command 3 8 mvn -B -ntp clean verify
popd >/dev/null
