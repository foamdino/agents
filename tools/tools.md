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
- estate-card.sh — one repo's owner, class, deploy, archive verdict, and the repos that depend on it / it depends on (rest, msg, call, mvn, imp counts; ~4 s), from an estate DB; SQL in `estate-card.sql` — `estate-card.sh ~/thg-src/estate/db/current.db order-service` — sh, sqlite3 — added 2026-11-05
- endpoints.sh — one repo's inbound REST endpoints (verb, path with class prefix, Class.handler, file:line, profiles) plus its context path, from an estate DB's `wires` rest_in rows; SQL in `endpoints.sql`; paths built from constants come through truncated (see `--help`) — `endpoints.sh ~/thg-src/estate/db/current.db orderprocessingapi` — sh, sqlite3 — added 2026-11-10
- weekly-facts.sh — per-project status (active/warm/dormant), one author's commits on all branches, files changed since a date (uncommitted, or any file in non-git dirs), plan files; feeds the weekly review (`../weekly.md`) — `weekly-facts.sh --author me@example.com ~/projects/* ~/side/*` — sh, git — added 2026-11-06
- weekly-usage.sh — Claude plan usage since a date (peak % per 7-day window, 5-hour windows and how many hit 80%+, from the status line's log) and tokens per git repo (each reply charged to the repo of the directory it ran in) from Claude Code transcripts (sessions, replies, output, input, share); feeds the weekly review — `weekly-usage.sh ~/.claude/usage.tsv ~/.claude/projects` — sh, jq, fd — added 2026-11-16
- page-probe.sh — run a JS probe inside a local HTML page in headless Chrome (fresh profile, CSP meta stripped, relative assets kept via <base>); the probe gets log(), sleep(), $(sel[, root]) and $$(sel[, root]); prints the probe's log() lines and every JS error (load failures, uncaught, rejections, console.error); exit 1 on errors, 3 if the probe never finished — `page-probe.sh --hash 'tab=sim' ~/side/mor/mor.html probe.js` — sh, python3, Google Chrome — added 2026-11-09
- svg-shot.sh — render one standalone SVG to a PNG with headless Chrome at its viewBox (or width/height) size, on white; prints the PNG path (default $TMPDIR/svg-shot/<name>.png) — `svg-shot.sh ~/side/mor/docs/diagrams/payments.svg` — sh, Google Chrome — added 2026-11-10
- subst.py — apply exact-text replacements across files from a JSON list of {file, old, new}; each old must occur exactly once when its edit applies; all or nothing (nothing written on any failure), prints ok FILE:LINE per edit; --dry-run, --root — `python3 -I ~/.config/agents/tools/subst.py --root ~/side/mor edits.json` — python3 — added 2026-11-12
- guard-check.py — check each guard is covered by a test by reverting it: a JSON list of {name, file, old, new}; runs the tests on the unmodified tree first (must pass), then each mutation alone, restoring the file byte for byte; prints caught (with the FAIL lines), MISSED (tests still pass) or CRASH (failed with no FAIL line: a broken mutation or harness); exit 0 only if every case is caught; --fail-pattern (default ^FAIL), --root — `python3 -I ~/.config/agents/tools/guard-check.py --root ~/side/mor guards.json -- node tests/run.js` — python3 — added 2026-11-12
- estate-grep.sh — rg across an estate snapshot (only the DB's orgs; tests excluded by the estate is_test path rules, node_modules/target/build and the DB's `vendored` repos skipped), summarised per repo as FILES REPO OWNER LAST_COMMIT, or REPO PATH per file with --files; -i/-F before DB, --code for source and config files only (no lock files, data dumps, vendor/ or *.min.js), other rg args after -- — `estate-grep.sh -i --code ~/thg-src/estate/db/current.db ~/thg-src 'permanently_deleted' THG-Engagement -- -t java` — sh, rg, sqlite3 — added 2026-11-13
- vault-meta.sh — list Obsidian notes with no frontmatter (`missing`), and prepend frontmatter from a JSON plan (`apply`): type, projects, components, related; tags derived as project/<p> and component/<c> plus the plan's own; every entry checked before any write, no-frontmatter notes only, inode and body kept byte for byte; jq in `vault-meta.jq`. The agent writes the plan and the user runs `apply` (vault-guard blocks agents from writing outside `agent/`) — `vault-meta.sh apply ~/thoughts plan.json` — sh, jq, rg — added 2026-11-19

## Templates
Not tools: files to copy. Same index format.

- templates/report.html — the skeleton for every report: local single-page HTML (tokens, light/dark, tabs, KPI tiles, findings with confidence badges and Asks, options scored on Correct by Construction, a filterable source-map table driven by one JS array, Asks & method, footer legend); the header comment holds the rules (never publish; check with the probe) — `cp ~/.config/agents/templates/report.html ~/thg-src/estate/local/<topic>-YYYY-MM-DD.html` — none — added 2026-11-17
- templates/report-probe.js — page-probe.sh probe for those reports: clicks every tab and filter, fails if a tab doesn't show exactly its own section, logs visible rows — `page-probe.sh <report.html> ~/.config/agents/templates/report-probe.js` — page-probe.sh — added 2026-11-17
