# Agent setup backlog

Ideas for making agent sessions more deterministic and cheaper, from the 2026-10-29
discussion. Ordered by value. Principle: put each rule as high in this list as it will go.

| Mechanism | Enforced by | Cost per session |
|---|---|---|
| Hooks / permissions (`settings.json`) | the harness, always | none |
| Scripts with one entry point | the script | none until run |
| Skills (`~/.claude/skills`) | the agent, on a description match | one line |
| `AGENTS.md` / `CLAUDE.md` | the agent, usually | every line, every session |
| Memory | the agent, if recalled | index |

Done: tool-first rule + `tools/tools.md` index; retro Stop hook (`retro.md`, `retro/inbox.md`,
`~/.claude/hooks/retro-gate.sh`).

## 1. Hard rules → PreToolUse hooks (high value, S)
Instructions are probabilistic; these must never happen. Deny with a reason, in the style of
`~/.claude/hooks/artifact-scratchpad-only.sh`.
- [x] 2026-10-29 Writes under `~/thg-src/<org>/`: `~/.claude/hooks/snapshot-readonly.sh`.
      Heuristic for Bash; false positive when a command both writes elsewhere (`rm x`) and
      names an org path.
- [x] 2026-10-29 Package installs and make/cmake under `nob.c`: `~/.claude/hooks/bash-guard.sh`.
- [~] Write of `*.py` outside the scratchpad: dropped. The tool-first rule allows one-off scripts
      in the scratchpad, so a hook cannot tell a justified script from a lazy one; the retro
      catches the pattern instead.
- Note: git state changes are already in `permissions.deny`; extend that list for
  `gh pr create|merge|ready` and `git -C * switch|rebase|merge|tag` if wanted.

## 2. PostToolUse / Stop checks (medium, S)
- [x] 2026-10-29 `~/.claude/hooks/clang-format-edited.sh`: formats only the added lines
      (`--lines`, from the Edit's structuredPatch), because estate's C files are not
      clang-format clean and whole-file formatting would restyle untouched code.
- [x] 2026-10-29 `~/.claude/hooks/nob-test-on-stop.sh`: `./nob test` when .c/.h were edited
      since the last prompt; blocks once on failure, then warns. `NOB_TEST=0` disables.

## 3. Read-only allowlist (medium, S)
- [ ] Run `/fewer-permission-prompts` to mine transcripts; expect `rg`, `sqlite3 -readonly`,
      `git diff|log|status|show`, `jq`, `wc`, `ls`.
- [x] Add `Edit(~/.config/agents/retro/inbox.md)` and `Read(~/.config/agents/**)` to
      `permissions.allow` so the retro does not prompt (the auto-mode classifier blocked the agent
      from adding these itself).

## 4. Shrink always-loaded context (high, M)
- [x] 2026-10-29 Split `estate/AGENTS.md` (5,684 → 774 words) into `docs/facts.md`,
      `database.md`, `cloud-fit.md`, `deployability.md`, `arch.md`, moved verbatim, with a
      "Where to read more" table.
- [ ] Same check for `thg-src/AGENTS.md` (smaller; probably fine).

## 5. Skills for recurring workflows (medium, M)
- [ ] `estate-finding`: scan → import → query → confirm in `rg` → confidence tag → record the
      exact filter → end with an Ask. Body = the workflow from `thg-src/AGENTS.md`.
- [ ] `cloud-fit-review`: derived-SQL order, `report.sh` / `review.py`, overrides rules.

## 6. Keep the queries (medium, S)
- [ ] `estate/local/queries/` (git-ignored, stays local): parametrised `.sql` per question, plus
      an index like `tools.md`. Removes re-deriving "repos importing X active since Y" each time.
      Tension with "ad-hoc queries are not kept": these are kept locally, not in the repo.

## 7. Agent-friendly tool shape (ongoing)
- [ ] For own scripts: `--help` with an example, TSV/JSON output, non-zero exit on failure,
      errors that name the next step ("run repo-class.sql first"). `estate -d` is the model.

## 8. Retro follow-ups
- [ ] After ~1 week: check `retro-gate` entries in `~/.claude/hooks/agent-audit.log`, tune
      `RETRO_MIN_TOOLS` (default 25).
- [ ] Once the inbox has entries: a `/retro-triage` skill to walk it with the user.
- [ ] If the in-session retro feels intrusive: fall back to a SessionEnd hook running a
      background `claude -p` over the transcript.
