#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:?usage: write-workspace.sh <container-directory>}"

go_members=()
for repo in tavora-protocol tavora-server; do
  [ -d "$ROOT/$repo" ] && go_members+=("$repo")
done

{
  echo "go 1.25.0"
  echo
  echo "use ("
  for repo in "${go_members[@]}"; do
    echo "	./$repo"
  done
  echo ")"
} > "$ROOT/go.work"

node_members=()
for repo in tavora-protocol tavora-sdk tavora-dice tavora-web tavora-system-dnd5e tavora-system-wod5e; do
  [ -f "$ROOT/$repo/package.json" ] && node_members+=("$repo")
done

{
  echo "packages:"
  for repo in "${node_members[@]}"; do
    echo "  - '$repo'"
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
.licenses/
IGNORE

echo "wrote go.work with ${#go_members[@]} modules and pnpm-workspace.yaml with ${#node_members[@]} packages"
