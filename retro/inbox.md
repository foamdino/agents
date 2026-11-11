# Retro inbox

Proposals from end-of-task retrospectives (`../retro.md`). Review in batches: action the
approved ones, delete the rest.

## 2026-10-29 — projects/llh
- [install] Install Node (`sudo pacman -S nodejs`) on this machine — evidence: `node tools/build-data.js` and `node tools/sim.js --check` could not run, so a generated data file was edited by hand and the dice change and replay determinism went unverified — effort: S
- [doc] Note that Claude in Chrome `file_upload` sends files as `application/octet-stream`, so sites that check the MIME type reject them; the fix is a capture-phase `change` listener that re-wraps the file with the right type via `DataTransfer` — evidence: three uploads were rejected as "file type isn't supported" before the cause was found — effort: S
- [rule] For a batch job through a third-party web tool, run one item end to end (upload → settings → export → file on disk) before anything else, to find gates early — evidence: the upload workaround and settings were done before discovering that export needs an account sign-in, which blocks the whole batch — effort: S
- [install] Install ImageMagick (`sudo pacman -S imagemagick`) so a batch of images can be reviewed as one `montage` contact sheet — evidence: naming 33 converted photos meant reading each 1200×904 PNG one at a time, which cost a lot of context for a quick visual check — effort: S
- [doc] Note that Chrome blocks repeated downloads started by page script (anchor `download` clicks) until the user allows "automatic downloads" for that site; the blocked saves are released once allowed, which can create `(1)` duplicates — evidence: three canvas saves silently vanished in a batch, and one duplicate had to be cleaned up after allowing — effort: S

## 2026-10-30 — projects/llh
- [tool] Add a `--stamina` report to the project's `tools/sim.js` (stamina by role at half-time and full time, the stamina tier of defenders playing late in each half, defence win rate early v late, injuries and subs per match) — evidence: the same measurement was written from scratch twice as in-browser JS during stamina tuning, and had to be carried across page reloads in sessionStorage — effort: S
- [doc] When testing a static page from `python3 -m http.server`, Chrome can serve stale JS from cache after an edit; force-refetch the scripts (`fetch(src, {cache: 'reload'})`) or add a query string before measuring — evidence: one 200-match measurement silently ran on the old card costs until a spot check showed tackle still costing 12 — effort: S

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

## 2026-11-05 — ~/side/muze (agent setup: obsidian-skills, estate card)
- [hook] vault-gate.sh: don't block when the turn since the last real prompt already wrote or edited a file under `~/thoughts/agent/` — evidence: the gate fired again right after turns that had just written the obsidian-skills and estate-card notes, costing a reply each time — effort: S
- [rule] AGENTS.md Tooling: zsh treats `?`, `*` and `[` in an unquoted argument as a glob and aborts on no match; single-quote URLs and patterns (`gh api 'repos/o/r/git/trees/HEAD?recursive=1'`) — evidence: the first `gh api …?recursive=1` call failed with "no matches found" (the 2026-11-04 session hit the same error with a file glob) — effort: S

## 2026-11-05 — ~/side/t2 (Valkey TLS, build.h)
- [rule] AGENTS.md Surgical Execution: edit source with the Edit tool, one call per site; no multi-line perl/sed substitutions over source files — evidence: the suite-table edits in nob.c were done with multi-line `perl -0pi` regexes, and the user asked for a build.h split partly "to remove the need for complex perl scripts" — effort: S
- [doc] vault.md Capture: a note's filename must not contain words the secret deny rules match (`token`, `key`, `password`), or the Write is refused — evidence: a note titled "...metadata token" was blocked by a Read deny rule and had to be renamed — effort: S

## 2026-11-06 — ~/side/muze (agent setup: weekly review)
- [rule] AGENTS.md Tooling: the session scratchpad directory may not exist yet; `mkdir -p` it before the first redirect into it — evidence: the first `weekly-facts.sh > <scratchpad>/facts.txt` failed with "no such file or directory" and had to be rerun — effort: S

## 2026-11-06 — ~/side/t2 (Dockerfile)
- [tool] `nerdctl-build-proxy-ca` (or similar): build any Dockerfile locally with the corporate TLS-intercept CA added to every stage that fetches, from a git-ignored overlay under `~`, leaving the committed Dockerfile untouched — evidence: the first image build failed with curl exit 60; the overlay was improvised with awk into local/ (after the scratchpad copy wasn't visible to colima, the open 2026-11-04 item hit again) — effort: S
- [rule] AGENTS.md Execution: never `exec` a container's entrypoint binary to probe it; a long-running worker blocks the call. Inspect the image config or run a separate `--rm` container with a timeout — evidence: `nerdctl exec t2run /usr/local/bin/t2` started a second worker and hung the command for 120 s — effort: S
- [doc] t2 docs/dependencies.md "Bumping curl": after merging config/curl_config.h, build it with `./nob` on Linux too (the Docker builder), not only macOS — evidence: the Linux half had never been compiled under nob; the first image build failed on undeclared memrchr (_GNU_SOURCE comes from configure's CPPFLAGS, not the header) — effort: S

## 2026-11-09 — ~/side/t2 (review and fixes)
- [tool] `doc-refs`: list repo paths (`src/…`, `test/…`, `scripts/…`) named in docs/comments that do not exist, plus `name()` mentions with no definition left — evidence: the pre-git-init review improvised this as a shell loop (one zsh quoting failure first); it found the stale `src/store.c` and `ingest()` references a full read would have taken much longer to find — effort: S
- [doc] t2 AGENTS.md Code Style: `arena.h` keeps estate's bare `1`/`0` for `oom` because `arena` is an EXPECT_LEAF (no t2 deps, so no `t2.h`) — evidence: the review listed it as a style fix and the conflict surfaced only while editing; todo.md has carried it as an open finding since 2026-11-03 — effort: S

## 2026-11-09 — ~/side/mor (MoR simulation)
- [doc] implement-with-local-llm SKILL.md: the local llama.cpp server runs one slot, so concurrent prompts queue (check `curl localhost:8080/slots`); chain all prompts in one background job and wait for completion with a single background `until [ -s out ]` command rather than polling — evidence: three view prompts queued behind each other (the last one finished ~20 min after dispatch) and the wait was improvised twice, once as a foreground sleep loop — effort: S
- [done 2026-11-09: added to tools] `page-probe.sh <page.html> <probe.js>`: copy a file:// page to the scratchpad without its CSP, rewrite relative asset paths, inject a probe script plus window.onerror capture, run headless Chrome with --virtual-time-budget and print the probe output — evidence: built by hand with python string edits to click through tabs and catch JS errors; the first run printed nothing because a `\n` inside the generated JS became a raw newline — effort: S

## 2026-11-09 — ~/side/mor (catalogue, portal API, reconciliation)
- [rule] AGENTS.md Tooling: in Bash calls, don't combine a quoted heredoc with `$`-heavy JS/python; write the file with the Write tool and run it in a separate call — evidence: a combined python-heredoc + probe-script command was refused by the rm-safety parser ("could not be checked"), so the edits didn't run and had to be resent — effort: S
- [doc] mor readme/tests: when the sim adds random faults (recon surprises), any test that advances the clock through `/internal/clock` can pick up a fault; long-horizon regression tests should set `state.clock` and call the job they need directly — evidence: the lost-after-filing regression test broke because a simulated unnotified chargeback hit its payment first — effort: S

## 2026-11-09 — ~/side/mor (correct-by-construction refactor)
- [tool] implement-with-local-llm `ask_local_llm.sh`: make the hard-coded 900 s urlopen timeout an env var (e.g. `LOCAL_LLM_TIMEOUT`), and stream or print partial output on timeout — evidence: two large UI prompts (~30 KB in, ~500 lines out) timed out at 15 min with nothing saved, so the shell file had to be split up and finally written by hand — effort: S

## 2026-11-09 — ~/side/mor (stage 4: all-or-nothing transactions)
- [doc] mor tests/run.js: run the simulation invariants over 3+ seeds, not just 20260101 — evidence: a tax-return/ledger mismatch (credit note issued at the filing instant) had been there all along and only showed when rolling back declines shifted the random sequence onto another path — effort: S
- [doc] mor readme (tests): to check a regression test fails without its fix, preload a script that requires tests/load.js, patches the one function out (e.g. `MOR.engine.atomic = (s, f) => f(s)`), then requires tests/run.js — evidence: written by hand twice this session (neg_off.js, neg_refuse.js), and it is how the AGENTS.md "must fail without the fix" rule gets checked in this repo — effort: S

## 2026-11-09 — ~/side/mor (stage 5: derived totals)
- [tool] `cpuprof-top <file.cpuprofile> [function…]`: print the top self-time and inclusive-time functions from a `node --cpu-prof` profile, or the inclusive time of named functions — evidence: the same `node -e` parser of nodes/samples/timeDeltas was improvised four times across stages 4 and 5 to find the limiter, as the benchmark checklist requires — effort: S
- [doc] mor readme (tests): a refactor that should not change behaviour is checked by running the seeded sim on a copy of the core with the old files swapped in and comparing a hash of `state.balances`; at least 150 days, because 90 days never releases a reserve — evidence: the first 90-day comparison passed trivially with 0 releases on both sides — effort: S

## 2026-11-10 — ~/side/mor (estate review, connections tab)
- [doc] implement-with-local-llm SKILL.md: Muse Glimmer is a reasoning model; set a large `max_tokens` (or disable thinking) and read `reasoning_content` when `content` is empty — evidence: a 30k-token summary request returned an empty `content` after several minutes, so the docs were read by hand anyway — effort: S
- [done 2026-11-10: added to tools] `svg-shot <file.svg> [out.png]`: render one standalone SVG to PNG with headless Chrome at its viewBox size — evidence: improvised twice this session to check diagrams; it found arrowheads missing on multi-subpath `<path>`s and two overlapping labels — effort: S
- [done 2026-11-10: in mor readme.md] mor docs/diagrams convention: one `<path>` per arrow, because markers only draw at the ends of the whole path — evidence: connections.svg (and the existing architecture.svg client arrows) lost all but one arrowhead — effort: S

## 2026-11-10 — ~/side/mor (payments and risk ports)
- [tool] `guard-check <cases.tsv> -- <test cmd>`: for each row (file, exact old text, replacement), apply the edit, run the tests, print the FAIL lines (or "NO FAILURES"), and always restore the file. This checks the "regression test must fail without the fix" rule by text mutation; it is more general than the open preload-patch doc entry — evidence: an inline python mutate/run/restore loop was written for the stage 6 guards and again for 5 stage 7 guards — effort: S
- [doc] mor tests/run.js: add a sim invariant that the 90-day run reaches every state in each machine (`machines.js`), or lists the ones it is known not to reach — evidence: the risk "review" decision was computed for months but never reached in the sim (top score 40, threshold 45); it only surfaced when the new review-state invariant failed — effort: S

## 2026-11-10 — ~/side/mor (menus, Decision 8 start)
- [done 2026-11-10: page-probe.sh updated] page-probe.sh: make the probe's `$(sel, root)` honour a root argument (like most `$` helpers, including mor's `MOR.dom.$`), or reject a second argument with an error — evidence: a nav probe used `$('.tab', menu)`, silently got the first `.tab` in the document, and reported working menus as broken until the probe was rewritten with `querySelector` — effort: S

## 2026-11-10 — ~/thg-src (MoR-only API reference)
- [done 2026-11-10: added to tools as endpoints.sh, from wires rest_in; no @Operation text, no rg fallback] `endpoints <org/repo>`: list a repo's REST surface (verb, path, class:line, `@Operation` summary) from estate `methods.annotations` (class-level `@RequestMapping` prefix applied), with an `rg` fallback for repos not in the scan — evidence: `@*Mapping` was grepped by hand three times this session (heimdallr, OPAPI, OrderManager) to build an API reference; the estate DB already holds the annotations but has no query for them — effort: S
- [rule] vault.md Recall: run the vault recall before the first codebase search, even when the task looks like a pure source read — evidence: recall ran only at the Stop hook; an existing agent note and two of the user's MOR notes already described the OPAPI `/v3/order/transaction` path and would have skipped the heimdallr detour — effort: S

## 2026-11-10 — ~/side/mor (Decision 9: HS code port)
- [hook] vault-guard.sh: allow Bash edits (e.g. `sed -i`) to files under ~/thoughts/agent/, or say "use the Edit tool" in the refusal — evidence: a one-line `sed -i` on an agent note in ~/thoughts/agent/ was blocked with a message calling it "the user's own vault note"; the same change then went through Edit — effort: S
- [rule] AGENTS.md Design Conversations → Look First: before offering options for a new port, entity or service, `rg` the project's own docs for the concept's name to find earlier plans — evidence: the HS code options and build went ahead without seeing a planned "Classification" row in mor's port table (a different key, provider and failure rule); it was found only in the post-build doc sweep and had to go back to the user — effort: S
- [doc] mor readme (data model): a quote is deleted when it becomes an order; the order keeps the quote's lines (with `customs`), so tests read `order.lines`, not `state.quotes[order.quoteId]` — evidence: two test iterations failed reading a consumed quote — effort: S

## 2026-11-10 — ~/thg-src (estate decomposition check)
- [hook] estate scan / `db/import.sh`: warn when an org with repos under `<root>` has no rows in `teams.tsv` (or far fewer than the last scan) — evidence: a rate-limited `--teams-only` run silently dropped six orgs' team rows; every `repo_owner`-based report ran on that file for two weeks before the decomposition work happened to notice — effort: S
- [doc] estate docs (cloud-fit.md or AGENTS.md conventions): to list a system's repos, use `repo_factory.domain` / `repo_system`, never a repo-name `LIKE '%<system>%'` — evidence: a name filter put Personify/ecrm at 4 Java repos; the domain held 19 linked repos (33 deployables with team-domain), and the claim had to be retracted to the user — effort: S
- [tool] `sql-peek <script.sql> <db> "<query>"`: run a derived-table script and then a query in the same sqlite3 session, so its TEMP tables can be inspected without editing the script — evidence: `{ cat decomp.sql; echo "<query>"; } | sqlite3` was improvised 4 times to check the class-role and sample tables — effort: S
- [doc] estate docs (findings conventions): draw precision samples spread across repos, for example `ORDER BY exact_hash LIMIT n`, never by name order — evidence: the first 30-class role sample ordered by name suffix came from only 2 repos and had to be redrawn — effort: S
- [tool] extend `svg-shot` (or add `page-shot <file.html[#hash]> [out.png] [--size WxH] [--from Y --height H]`): screenshot an HTML page at a URL hash with headless Chrome and crop a band of it — evidence: headless Chrome plus `sips` cropping was improvised three times to check the Decomposition tab; one `sips --cropOffset` call silently returned the uncropped image, and the screenshots found three layout bugs that pagecheck.js could not — effort: S
