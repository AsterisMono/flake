#!/usr/bin/env bash
set -euo pipefail

origin="$1"

if [[ ! -L "$origin" ]]; then
  echo "Error: $origin is not a symbolic link."
  exit 1
fi

source=$(readlink -f "$origin")

if [[ ! -e "$source" ]]; then
  echo "Error: target $source does not exist."
  exit 1
fi

rm "$origin"
cp "$source" "$origin"