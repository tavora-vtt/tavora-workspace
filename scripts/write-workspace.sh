#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?usage: write-workspace.sh <container-directory>}"

GO_REPOS=(tavora-protocol tavora-server)
NODE_REPOS=(tavora-protocol tavora-sdk tavora-dice tavora-web tavora-system-dnd5e tavora-system-wod5e)

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

{
  echo "go 1.25.0"
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

printf 'wrote go.work with %d modules and pnpm-workspace.yaml with %d packages\n' \
  "${#go_members[@]}" "${#node_members[@]}"
