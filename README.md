# tavora-workspace

Tavora is nine repositories, one per component. This one holds the wiring that makes them
behave like a single checkout while you work, and nothing that ships.

Why it is split this way, and how a change spanning two repositories is handled, is in
[ADR 0007](https://github.com/tavora-vtt/tavora-docs/blob/main/adr/0007-repository-topology.md).

## Start here

```
git clone git@github.com:tavora-vtt/tavora-workspace.git
cd tavora-workspace
make bootstrap
```

That clones the other eight repositories as siblings and wires them together.

```
TavoraVTT/                 container, not a repository
  tavora-protocol/
  tavora-sdk/
  tavora-dice/
  tavora-server/
  tavora-web/
  tavora-system-dnd5e/
  tavora-system-wod5e/
  tavora-docs/
  tavora-workspace/        you are here
  go.work                  generated, ignored
  pnpm-workspace.yaml      generated, ignored
```

## Targets

| Target | Does |
| --- | --- |
| `make bootstrap` | Clone everything missing, then wire and install |
| `make clone` | Clone only |
| `make link` | Rewrite the workspace files and run `pnpm install` |
| `make status` | Branch and dirty-file count per repository |
| `make dev` | Server on 30000 and the web dev server on 5173, together |
| `make check` | Vet, test and type check across every repository |
| `make fmt` | `gofmt` the Go repositories |
| `make clean-workspace` | Remove the generated wiring, leave the repositories alone |

## The rule that keeps this honest

`go.work` and `pnpm-workspace.yaml` are written into the container directory, never into a
repository. A repository cloned on its own therefore builds against published versions,
which is the state a third-party contributor sees. If a change only works inside the
workspace, it is broken.

The two first-party game systems are the sharpest case: they must build from a clean clone
against published `@tavora/sdk` versions alone. CI enforces it in a container with no
access to the other checkouts, because that is the entire reason they are separate
repositories.
