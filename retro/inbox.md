# Retro inbox

Proposals from end-of-task retrospectives (`../retro.md`). Review in batches: action the
approved ones, delete the rest.

## 2026-11-03 — ~/side/t2
- [doc] Add a Gotcha to t2's AGENTS.md: nob.c keeps a hand-written source list per test/bench binary, so when a `src/` module starts calling another module, every list that links the caller needs the callee (and its own deps); find them with `rg -F '"src/<caller>.c"' nob.c` — evidence: vfn.c gaining a call to ingest_render meant editing the itest and bench_valkey lists (plus ingest→fact→store and cJSON for the itest), found by reasoning, not by a failing build — effort: S

## 2026-11-04 — ~/side/muze (agent setup: vault hooks)
- [tool] `hook-test.sh`: run each case with `HOME` set to a temp dir, so Stop-hook tests don't append to the real `~/.claude/hooks/agent-audit.log` — evidence: testing vault-gate.sh needed a hand-made scratch HOME; retro-gate has no tests, possibly for the same reason — effort: S
- [doc] Claude Code docs pages have a `.md` form (`https://code.claude.com/docs/en/hooks.md`): fetch it once with curl into the scratchpad and `rg` for the section, rather than paging WebFetch — evidence: finding the Stop decision section of the 286k-char hooks page took three WebFetch calls with offsets — effort: S
- [rule] Run a live probe of a new deny hook as its own command, never chained after other work — evidence: a probe `rm` chained after the hook test suites made vault-guard deny the whole command, and the suites had to be rerun — effort: S

## 2026-11-03 — ~/side/t2 (review pass)
- [rule] t2 AGENTS.md, arena sizing: a sizing test must run the production path (the Valkey adapter), not only a local test double; record both peaks if both exist — evidence: test_consume's "quarter free" check passed at 4.7 MiB through the local store while the same round over vfn_ingest_facts peaked at 9.1 MB and overran the 8 MiB CONSUME_SCRATCH; found only by a one-off program during review — effort: S
- [doc] t2 AGENTS.md Gotchas: `build/cJSON.o` is the asan/ubsan object; an ad-hoc or scratch build against src/ links `build/cJSON-release.o` — evidence: the one-off worst-round program failed to link with dozens of undefined `___asan_*` symbols until switched — effort: S
- [tool] A one-command include check over a tree (e.g. a loop of `clangd --check=<file>` filtered to unused-include diagnostics) instead of one MCP get_diagnostics call per file — evidence: the header review took 23 separate per-file diagnostic calls for src/ and tests — effort: S

## 2026-11-04 — ~/side/t2 (store removal)
- [rule] t2 AGENTS.md Workflow: when a change deletes, renames or moves a `src/` module or `test/` program, finish with `rg -n '<old names>' docs AGENTS.md` and list each hit as fixed or kept as history — evidence: removing the store left stale names in 6 docs (core-flow §7/§8/§11.5/§11.6, design.md, todo.md, t2-message-correctness.md, dependencies.md headers table); it took three rg passes with growing patterns (store_, test_consume, local store) to find them all — effort: S

## 2026-11-04 — ~/side/t2 (curl build)
- [doc] t2 AGENTS.md Gotchas: colima shares only `$HOME` with containers, so a `colima nerdctl -- run -v` mount must be under `~` (e.g. the git-ignored `build/`), never the `/private/tmp` scratchpad — evidence: the Linux curl configure run failed with "can't cd to /w/src" because the scratchpad mount was empty inside the container — effort: S
- [rule] AGENTS.md Execution: never print a success message after `cmd | tail` — the pipeline's status is tail's; check the command's own status (`set -o pipefail`, or run it without the pipe) — evidence: a scratch link printed "links without Apple frameworks" right after the linker failed, and the failure was only spotted by reading the output — effort: S

## 2026-11-05 — ~/side/t2 (metadata token)
- [rule] AGENTS.md Execution: before handing over a new gate/lint script, run it on the clean tree and once per case it must block, with a deliberate breakage that gets reverted afterwards — evidence: the first check-https.sh blocked the clean tree (a TODO comment matched the pin pattern), and only the breakage runs showed that a removed pin went uncaught — effort: S
- [rule] Design conversations: for a new module, show the header and the key choices (state per call vs per init, named constants, helper names) before writing the .c — evidence: two full-file writes were rejected mid-slice (curl options belonged in init with #defines; the `b64token` name was mistaken for the b64 module) — effort: S
