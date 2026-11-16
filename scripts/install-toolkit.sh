#!/usr/bin/env bash
# Usage (from the toolkit repo): scripts/install-toolkit.sh <project-path> <n8n-port>
set -euo pipefail

TK="$(cd "$(dirname "$0")/.." && pwd)"
P="${1:?project path}"
PORT="${2:?n8n port, e.g. 5681}"
VERSION=$(cat "$TK/VERSION")

mkdir -p "$P"/{db/init,toolkit/workflows,scripts,docs/playbook,docs/incidents,docs/handover,workflows,runbooks,test-data}

cp "$TK"/db/*.sql "$P/db/init/"
cp "$TK"/workflows/*.json "$P/toolkit/workflows/"
cp "$TK"/scripts/{activate-prompt.sh,export-workflows.sh,scorecard.sh,import-workflows.sh} "$P/scripts/"
cp "$TK"/docs/*.md "$P/docs/playbook/"

[ -f "$P/docker-compose.yml" ] || sed "s/__N8N_PORT__/$PORT/g" "$TK/templates/docker-compose.yml" > "$P/docker-compose.yml"
[ -f "$P/.env.example" ] || sed "s/__N8N_PORT__/$PORT/g" "$TK/templates/env.example" > "$P/.env.example"

echo "$VERSION" > "$P/TOOLKIT_VERSION"
chmod +x "$P"/scripts/*.sh

echo "Installed AI Ops Toolkit v$VERSION into $P (n8n on port $PORT)"