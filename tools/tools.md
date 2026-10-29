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

- hook-test.sh — run a Claude Code hook against a TSV of cases (expect, tool, value, cwd), print pass/fail, exit 1 on any failure — `hook-test.sh ~/.config/agents/hooks/bash-guard.sh ~/.config/agents/hooks/tests/bash-guard.tsv` — sh, jq — added 2026-10-29
