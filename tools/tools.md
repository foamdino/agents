# Personal agent tools

Reusable scripts written during earlier tasks. Check this index before writing a new script
(see `AGENTS.md` → Tool Selection).

## Admission rules
- Promoted only with the user's approval.
- Inputs come in as arguments. No hard-coded paths, hosts, repo names or project data. Has `--help`.
- Standard library only (Python stdlib / POSIX sh). Any other dependency is confirmed with the user and listed in the index.
- Extend an existing tool before adding a near-duplicate.
- A helper specific to one project goes in that project's repo, not here.
- Run it by absolute path (`python3 -I ~/.config/agents/tools/<name>.py`).
- Prune entries that have gone stale. The `added` date is there to help with that.

## Index
One line per tool: `- name — what it does — example invocation — deps — added YYYY-MM-DD`

- hook-test.sh — run a Claude Code hook against a TSV of cases (expect, tool, value, cwd, env), print pass/fail, exit 1 on any failure — `hook-test.sh ~/.config/agents/hooks/bash-guard.sh ~/.config/agents/hooks/tests/bash-guard.tsv` — sh, jq — added 2026-10-29
- estate-card.sh — one repo's owner, class, deploy, archive verdict, and the repos that depend on it / it depends on (rest, msg, call, mvn, imp counts; ~4 s), from an estate DB; SQL in `estate-card.sql` — `estate-card.sh ~/thg-src/estate/db/out-all.db order-service` — sh, sqlite3 — added 2026-11-05
- endpoints.sh — one repo's inbound REST endpoints (verb, path with class prefix, Class.handler, file:line, profiles) plus its context path, from an estate DB's `wires` rest_in rows; SQL in `endpoints.sql`; paths built from constants come through truncated (see `--help`) — `endpoints.sh ~/thg-src/estate/db/out-all.db orderprocessingapi` — sh, sqlite3 — added 2026-11-10
- weekly-facts.sh — per-project status (active/warm/dormant), one author's commits on all branches, files changed since a date (uncommitted, or any file in non-git dirs), plan files; feeds the weekly review (`../weekly.md`) — `weekly-facts.sh --author me@example.com ~/projects/* ~/side/*` — sh, git — added 2026-11-06
- page-probe.sh — run a JS probe inside a local HTML page in headless Chrome (fresh profile, CSP meta stripped, relative assets kept via <base>); the probe gets log(), sleep(), $(sel[, root]) and $$(sel[, root]); prints the probe's log() lines and every JS error (load failures, uncaught, rejections, console.error); exit 1 on errors, 3 if the probe never finished — `page-probe.sh --hash 'tab=sim' ~/side/mor/mor.html probe.js` — sh, python3, Google Chrome — added 2026-11-09
- svg-shot.sh — render one standalone SVG to a PNG with headless Chrome at its viewBox (or width/height) size, on white; prints the PNG path (default $TMPDIR/svg-shot/<name>.png) — `svg-shot.sh ~/side/mor/docs/diagrams/payments.svg` — sh, Google Chrome — added 2026-11-10
