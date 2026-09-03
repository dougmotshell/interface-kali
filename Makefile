# harness-bootstrap >>>
# Neutral sensor interface. CI, pre-commit and the PostToolUse hook all call these
# targets, so nothing downstream knows your stack. Here the stack is bash + markdown:
# the sensors are syntax checks, dead-link checks and shellcheck.

.DEFAULT_GOAL := help
.PHONY: help test lint typecheck format lint-file format-file sync sync-check harness harness-gate harness-report

SHELLS = scripts/*.sh .claude/hooks/*.sh

help:  ## List the targets
	@grep -E '^[a-z-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-14s\033[0m %s\n", $$1, $$2}'

test:  ## SNS-01/05 — bash -n em todo script e links relativos de todo Markdown
	@for f in $(SHELLS); do bash -n "$$f" || exit 1; done; printf 'bash -n: ok\n'
	@python3 -c 'import re, pathlib, sys; \
bad = 0; \
files = [p for p in pathlib.Path(".").rglob("*.md") if ".git/" not in str(p)]; \
_ = [ (print("link morto:", p, "->", l), globals().__setitem__("bad", bad + 1)) \
      for p in files \
      for l in re.findall(r"\]\(([^)#]+)\)", p.read_text()) \
      if not l.startswith(("http", "mailto")) and not (p.parent / l).exists() ]; \
print("links: ok" if not bad else "links quebrados"); \
sys.exit(1 if bad else 0)'

lint:  ## SNS-02 — shellcheck em todo script (avisa e passa se não estiver instalado)
	@if command -v shellcheck >/dev/null 2>&1; then \
	  shellcheck -x $(SHELLS) && printf 'shellcheck: ok\n'; \
	else \
	  printf 'shellcheck ausente: sensor declarado, não executado (apt install shellcheck)\n'; \
	fi

typecheck:  ## SNS-03 — não se aplica: bash e markdown não têm tipos a checar
	@printf 'typecheck: não se aplica (bash + markdown). O sensor equivalente é `make test`.\n'

format:  ## SNS-04 — shfmt em todo script (avisa e passa se não estiver instalado)
	@if command -v shfmt >/dev/null 2>&1; then \
	  shfmt -w -i 2 -ci $(SHELLS) && printf 'shfmt: ok\n'; \
	else \
	  printf 'shfmt ausente: sensor declarado, não executado (apt install shfmt)\n'; \
	fi

# --- one file at a time: called by the PostToolUse hook, so keep these fast ---

lint-file:  ## Lint just $(FILE)
	@case "$(FILE)" in \
	  *.sh) bash -n "$(FILE)" && printf 'bash -n: ok\n'; \
	        command -v shellcheck >/dev/null 2>&1 && shellcheck -x "$(FILE)" || true ;; \
	  *.md) python3 -c 'import re, pathlib, sys; \
p = pathlib.Path(sys.argv[1]); \
morto = [l for l in re.findall(r"\]\(([^)#]+)\)", p.read_text()) \
         if not l.startswith(("http", "mailto")) and not (p.parent / l).exists()]; \
print("links: ok" if not morto else "links mortos: " + ", ".join(morto))' "$(FILE)" ;; \
	  *) : ;; \
	esac

format-file:  ## Format just $(FILE) in place
	@case "$(FILE)" in \
	  *.sh) command -v shfmt >/dev/null 2>&1 && shfmt -w -i 2 -ci "$(FILE)" || true ;; \
	  *) : ;; \
	esac

# --- AI surfaces -----------------------------------------------------------

sync:  ## Regenerate the AI surfaces from their authored sources
	python3 scripts/sync-ai-surfaces.py

sync-check:  ## Fail if a generated surface drifted from its source
	python3 scripts/sync-ai-surfaces.py --check

harness:  ## Score the harness (36 checks, 108 points, levels L0-L4)
	npx -y harness-score

harness-gate:  ## The same scan as a gate — fails below MIN_LEVEL (default 3)
	npx -y harness-score --min-level $(or $(MIN_LEVEL),3)

harness-report:  ## Write the scan as markdown and as JSON, for a PR or a baseline
	npx -y harness-score --md harness-report.md --json > harness-report.json
# harness-bootstrap <<<
