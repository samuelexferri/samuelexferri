#!/usr/bin/env bash
set -euo pipefail

readme="${1:-README.md}"
start="<!--START_SECTION:github-data-->"
end="<!--END_SECTION:github-data-->"

# Needs GH_TOKEN with user scope to expose private repos and disk usage
user_json="$(gh api user)"

storage_mb="$(jq -r '(.disk_usage / 1024 * 10 | round) / 10' <<<"$user_json")"
public_repos="$(jq -r '.public_repos' <<<"$user_json")"
private_repos="$(jq -r '.total_private_repos' <<<"$user_json")"
if [ "$(jq -r '.hireable // false' <<<"$user_json")" = "true" ]; then
  hire="Opted to Hire"
else
  hire="Not Opted to Hire"
fi
updated="$(date -u '+%d/%m/%Y %H:%M:%S')"

block="$(mktemp)"
cat >"$block" <<BLOCK
**🐱 My GitHub Data**

> 📦 ${storage_mb} MB Used in GitHub's Storage
>
> 💼 ${hire}
>
> 📜 ${public_repos} Public Repositories
>
> 🔑 ${private_repos} Private Repositories

Last Updated on ${updated} UTC
BLOCK

grep -q "$start" "$readme" && grep -q "$end" "$readme" || { echo "Markers missing in $readme" >&2; exit 1; }

out="$(mktemp)"
awk -v start="$start" -v end="$end" -v block="$block" '
  $0 == start { print; while ((getline line < block) > 0) print line; skip = 1; next }
  $0 == end { skip = 0 }
  !skip { print }
' "$readme" >"$out"
cat "$out" >"$readme"
rm -f "$block" "$out"
