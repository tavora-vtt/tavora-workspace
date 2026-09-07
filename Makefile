OWNER := tavora-vtt
ROOT  := $(abspath $(CURDIR)/..)

GO_REPOS   := tavora-protocol tavora-server
NODE_REPOS := tavora-protocol tavora-sdk tavora-dice tavora-web tavora-system-dnd5e tavora-system-wod5e
ALL_REPOS  := tavora-protocol tavora-sdk tavora-dice tavora-server tavora-web \
              tavora-system-dnd5e tavora-system-wod5e tavora-docs

.PHONY: help bootstrap clone link status dev check standalone fmt clean-workspace

help:
	@echo "bootstrap  clone every repository and wire the workspace"
	@echo "clone      clone anything missing from github.com/$(OWNER)"
	@echo "link       write go.work and the pnpm workspace, then install"
	@echo "status     one line of git status per repository"
	@echo "dev        run the server and the web dev server together"
	@echo "check      vet, test and type check everything"
	@echo "standalone verify every module builds without the workspace"

bootstrap: clone link
	@echo "workspace ready at $(ROOT)"

clone:
	@for repo in $(ALL_REPOS); do \
		if [ -d "$(ROOT)/$$repo/.git" ]; then \
			echo "have    $$repo"; \
		else \
			echo "clone   $$repo"; \
			git -C "$(ROOT)" clone --quiet git@github.com:$(OWNER)/$$repo.git || exit 1; \
		fi; \
	done

link:
	@scripts/write-workspace.sh "$(ROOT)"
	@cd "$(ROOT)" && pnpm install

status:
	@for repo in $(ALL_REPOS); do \
		if [ -d "$(ROOT)/$$repo/.git" ]; then \
			printf "%-22s %-14s %s\n" "$$repo" \
				"$$(git -C "$(ROOT)/$$repo" rev-parse --abbrev-ref HEAD)" \
				"$$(git -C "$(ROOT)/$$repo" status --porcelain | wc -l | xargs) changed"; \
		else \
			printf "%-22s %s\n" "$$repo" "missing"; \
		fi; \
	done

dev:
	@echo "server on :30000, web on :5173"
	@trap 'kill 0' EXIT; \
	(cd "$(ROOT)/tavora-server" && go run ./cmd/tavora) & \
	(cd "$(ROOT)/tavora-web" && pnpm dev) & \
	wait

check: standalone
	@echo "== go =="
	@cd "$(ROOT)/tavora-server" && go vet ./... && go test ./...
	@cd "$(ROOT)/tavora-protocol" && go vet ./... && go build ./...
	@echo "== typescript =="
	@cd "$(ROOT)" && pnpm -r --if-present run check
	@echo "== docs =="
	@cd "$(ROOT)/tavora-docs" && python3 tools/check-links.py && python3 tools/check-style.py

standalone:
	@echo "== standalone, as a clean clone sees it =="
	@for repo in $(GO_REPOS); do \
		printf "  %-20s " "$$repo"; \
		( cd "$(ROOT)/$$repo" && GOWORK=off go build ./... ) || { \
			echo "FAILS without the workspace, run 'GOWORK=off go mod tidy' in $$repo"; exit 1; }; \
		echo "ok"; \
	done

fmt:
	@cd "$(ROOT)/tavora-server" && gofmt -w .
	@cd "$(ROOT)/tavora-protocol" && gofmt -w .

clean-workspace:
	@rm -f "$(ROOT)/go.work" "$(ROOT)/go.work.sum" "$(ROOT)/pnpm-workspace.yaml" \
	       "$(ROOT)/package.json" "$(ROOT)/pnpm-lock.yaml"
	@rm -rf "$(ROOT)/node_modules"
	@echo "workspace wiring removed, repositories untouched"
