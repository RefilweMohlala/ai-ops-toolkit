#!/usr/bin/env bash
# Imports the Ops workflows into the n8n that is running in THIS folder's docker-compose.yml.
#
# Usage (run from the folder that contains docker-compose.yml):
#   lab:      cd lab && ../scripts/import-workflows.sh ../workflows
#   project:  scripts/import-workflows.sh toolkit/workflows
#
# Why this exists: the workflow files refer to your credentials by ID, and every n8n
# generates its own IDs. This script looks up the IDs of the credentials named
# "Ops DB", "Anthropic" and "Gmail" in your running n8n, writes them into a TEMPORARY
# copy of the files (your originals are not changed), then imports that copy.
# It matches by credential NAME, so it also works on files exported from another n8n.
# Create the credentials in n8n first (exact names), then run this.
set -euo pipefail

SRC="${1:?folder containing the workflow .json files, e.g. ../workflows or toolkit/workflows}"
[ -f docker-compose.yml ] || { echo "Run this from the folder that contains docker-compose.yml." >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required." >&2; exit 1; }
ls "$SRC"/*.json >/dev/null 2>&1 || { echo "No .json files found in $SRC" >&2; exit 1; }

TMP="$(mktemp -d)"; CREDS="$(mktemp)"
trap 'rm -rf "$TMP" "$CREDS"' EXIT
cp "$SRC"/*.json "$TMP/"

echo "Reading credential IDs from n8n..."
docker compose exec -T n8n n8n export:credentials --all > "$CREDS"

python3 - "$CREDS" "$TMP" <<'PY'
import glob, json, os, sys

creds_file, folder = sys.argv[1], sys.argv[2]
raw = open(creds_file, encoding="utf-8").read()

# The n8n CLI may print log lines around the JSON, so find the JSON list inside the output.
decoder, creds = json.JSONDecoder(), None
for i, ch in enumerate(raw):
    if ch != "[":
        continue
    try:
        obj, _ = decoder.raw_decode(raw[i:])
    except ValueError:
        continue
    if isinstance(obj, list) and all(isinstance(c, dict) and "id" in c and "name" in c for c in obj):
        creds = obj
        break
if creds is None:
    sys.exit("Could not read the credential list from n8n. Is the n8n container running?")

ids = {c["name"]: c["id"] for c in creds}
required = ["Ops DB", "Anthropic"]
optional = ["Gmail"]
for name in required:
    if name not in ids:
        sys.exit(f'Credential "{name}" not found in n8n. Create it first (exact name), then re-run.')
    print(f"  {name}: found")
for name in optional:
    if name in ids:
        print(f"  {name}: found")
    else:
        print(f'  {name}: NOT found. Email nodes will need the credential selected by hand,\n'
              f'  or create it and re-run this script (re-importing replaces the workflows and\n'
              f'  switches them off, so activate them again afterwards).')

# Point every credential reference at the ID that n8n gave the credential with the same NAME.
# Works for the placeholder files and for files exported from another n8n.
for path in sorted(glob.glob(os.path.join(folder, "*.json"))):
    wf = json.load(open(path, encoding="utf-8"))
    for node in wf.get("nodes", []):
        for ref in node.get("credentials", {}).values():
            if ref.get("name") in ids:
                ref["id"] = ids[ref["name"]]
    with open(path, "w", encoding="utf-8") as f:
        json.dump(wf, f, indent=2, ensure_ascii=False)
PY

echo "Importing workflows..."
docker compose exec -T n8n sh -c 'rm -rf /home/node/toolkit-import && mkdir -p /home/node/toolkit-import'
docker compose cp "$TMP/." n8n:/home/node/toolkit-import/
docker compose exec -T n8n n8n import:workflow --separate --input=/home/node/toolkit-import/

echo
echo "Done. In the n8n editor, publish these four (Activate / Publish):"
echo "  Ops: Error Handler, Ops: Review Decision, Ops: Monitor, Ops: Retention"
