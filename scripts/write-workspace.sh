#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?usage: write-workspace.sh <container-directory>}"

GO_REPOS=(tavora-protocol tavora-server)
NODE_REPOS=(tavora-sdk tavora-dice tavora-web tavora-system-dnd5e tavora-system-wod5e)

go_members=()
for repo in "${GO_REPOS[@]}"; do
  if [ -f "$ROOT/$repo/go.mod" ]; then
    go_members+=("$repo")
  fi
done

node_members=()
for repo in "${NODE_REPOS[@]}"; do
  if [ -f "$ROOT/$repo/package.json" ]; then
    node_members+=("$repo")
  fi
done

go_version="1.25.0"
for repo in ${go_members[@]+"${go_members[@]}"}; do
  declared=$(awk '/^go [0-9]/ { print $2; exit }' "$ROOT/$repo/go.mod")
  if [ -n "$declared" ] && [ "$(printf '%s\n%s\n' "$go_version" "$declared" | sort -V | tail -1)" = "$declared" ]; then
    go_version="$declared"
  fi
done

{
  echo "go $go_version"
  echo
  echo "use ("
  for repo in ${go_members[@]+"${go_members[@]}"}; do
    printf '\t./%s\n' "$repo"
  done
  echo ")"
} > "$ROOT/go.work"

{
  echo "packages:"
  for repo in ${node_members[@]+"${node_members[@]}"}; do
    printf "  - '%s'\n" "$repo"
  done
} > "$ROOT/pnpm-workspace.yaml"

cat > "$ROOT/package.json" <<'JSON'
{
  "name": "tavora-workspace-root",
  "private": true,
  "type": "module"
}
JSON

cat > "$ROOT/.gitignore" <<'IGNORE'
go.work
go.work.sum
package.json
pnpm-workspace.yaml
pnpm-lock.yaml
node_modules/
IGNORE

printf 'wrote go.work (go %s) with %d modules and pnpm-workspace.yaml with %d packages\n' \
  "$go_version" "${#go_members[@]}" "${#node_members[@]}"
