#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq

set -euo pipefail

namespace=${1:-}

if [ -z "$namespace" ]; then
	nix eval -f ./default.test.nix --show-trace --raw
else
	if [ -d "./src/$namespace" ]; then
		nix eval -f "./src/$namespace/default.test.nix" --show-trace --json | jq
	else
		echo "Namespace $namespace not found"
		exit 1
	fi
fi

