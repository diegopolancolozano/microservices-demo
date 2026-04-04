#!/usr/bin/env bash

set -euo pipefail

ensure_maven() {
	if command -v mvn >/dev/null 2>&1; then
		return
	fi

	echo "[vote] Maven not found. Installing Maven..."

	if command -v apt-get >/dev/null 2>&1; then
		if command -v sudo >/dev/null 2>&1; then
			sudo apt-get update
			sudo DEBIAN_FRONTEND=noninteractive apt-get install -y maven
		else
			apt-get update
			DEBIAN_FRONTEND=noninteractive apt-get install -y maven
		fi
		return
	fi

	echo "[vote] ERROR: Maven is required but no supported package manager was found."
	exit 1
}

ensure_maven

echo "[vote] Running Maven verify"
pushd vote >/dev/null
mvn -B -ntp clean verify
popd >/dev/null
