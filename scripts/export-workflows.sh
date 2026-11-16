#!/usr/bin/env bash
# Usage: scripts/export-workflows.sh <folder>   e.g. workflows/inherited or workflows/hardened
set -euo pipefail
cd "$(dirname "$0")/.."

TARGET="${1:?folder, e.g. workflows/hardened}"

docker compose exec -T n8n sh -c '
  rm -rf /home/node/.n8n/export &&
  mkdir -p /home/node/.n8n/export &&
  n8n export:workflow --all --separate --pretty --output=/home/node/.n8n/export/
'

rm -rf "$TARGET" && mkdir -p "$TARGET"
docker compose cp n8n:/home/node/.n8n/export/. "$TARGET/"
ls "$TARGET"