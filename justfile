set dotenv-load := true

root_dir := justfile_directory()

deps:
    pnpm install

lint target="all":
    #!/usr/bin/env bash
    set -euox pipefail
    case "{{ target }}" in
      all)
        just lint justfile
        just lint config
        ;;
      justfile)
        just --fmt --unstable
        ;;
      config)
        npx prettier --write --cache "**/*.{json,yml,yaml,md}"
        ;;
      *)
        echo "Unknown target: {{ target }}"
        exit 1
        ;;
    esac

lint-file file:
    #!/usr/bin/env bash
    set -euo pipefail
    case "{{ file }}" in
      */justfile|*Justfile)
        just --fmt --unstable
        ;;
      *.json|*.yml|*.yaml|*.md)
        npx prettier --write --cache "{{ file }}"
        ;;
      *.ts|*.tsx)
        npx prettier --write --cache "{{ file }}"
        npx eslint --fix "{{ file }}" 2>/dev/null || true
        ;;
      *.go)
        gofmt -w "{{ file }}"
        go vet "{{ file }}" 2>/dev/null || true
        ;;
      *)
        echo "No lint rule for: {{ file }}"
        ;;
    esac

sync-agents:
    bash scripts/sync-agents.sh

typecheck-file file:
    #!/usr/bin/env bash
    set -euo pipefail
    dir=$(dirname "{{ file }}")
    while [[ "$dir" != "." && "$dir" != "/" ]]; do
      if [[ -f "$dir/tsconfig.json" ]]; then
        (cd "$dir" && npx tsc --noEmit --incremental)
        exit 0
      fi
      dir=$(dirname "$dir")
    done
    if [[ -f "tsconfig.json" ]]; then
      npx tsc --noEmit --incremental
    fi
