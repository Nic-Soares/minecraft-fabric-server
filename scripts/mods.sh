#!/usr/bin/env bash
# Usage:
#   scripts/mods.sh update   resolves the latest build of each slug in mods.txt and rewrites mods.lock
#   scripts/mods.sh sync     installs exactly mods.lock into server/mods, verifying the sha512
set -euo pipefail
source "$(dirname "$0")/lib.sh"
LOCK="$ROOT/mods.lock"
DEST="$ROOT/server/mods"
UA="local-fabric-server/1.0"

update() {
  local tmp; tmp="$(mktemp)"
  trap 'rm -f "$tmp"' RETURN
  printf 'slug\tversion\tfilename\tsha512\turl\n' > "$tmp"
  grep -Ev '^[[:space:]]*(#|$)' "$ROOT/mods.txt" | sort | while read -r slug; do
    curl -fsS -A "$UA" \
      "https://api.modrinth.com/v2/project/$slug/version?loaders=%5B%22fabric%22%5D&game_versions=%5B%22$MC_VERSION%22%5D" \
    | SLUG="$slug" MC="$MC_VERSION" python3 -c '
import json, os, sys
vs = json.load(sys.stdin)
if not vs:
    sys.exit(os.environ["SLUG"] + ": no Fabric build for " + os.environ["MC"])
v = vs[0]; fs = v["files"]; f = next((x for x in fs if x["primary"]), fs[0])
print("\t".join([os.environ["SLUG"], v["version_number"], f["filename"], f["hashes"]["sha512"], f["url"]]))'
  done >> "$tmp"
  cp "$tmp" "$LOCK"
  echo "mods.lock updated. Review with: git diff mods.lock"
}

sync() {
  [[ -f "$LOCK" ]] || { echo "mods.lock does not exist. Run: scripts/mods.sh update" >&2; exit 1; }
  local stage="$ROOT/server/.mods.new"
  rm -rf "$stage"; mkdir -p "$stage"
  tail -n +2 "$LOCK" | while IFS=$'\t' read -r slug version file sha url; do
    curl -fsSL -A "$UA" -o "$stage/$file" "$url"
    echo "$sha  $stage/$file" | shasum -a 512 -c --status - \
      || { echo "$slug: sha512 mismatch" >&2; exit 1; }
    echo "ok  $slug $version"
  done
  rm -rf "$DEST"; mv "$stage" "$DEST"
  echo "server/mods synced with mods.lock"
}

case "${1:-}" in
  update) update ;;
  sync)   sync ;;
  *) echo "Usage: $0 update | sync" >&2; exit 2 ;;
esac
