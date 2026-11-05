# AGENTS.md

Behavioral directives and workflow constraints for LLM coding agents.
Biased toward caution, surgical execution, and zero unnecessary dependencies.

---

## 1. Core Engineering Principles

### Think Before Coding
- **Surface Tradeoffs:** Never pick an ambiguous interpretation silently. State assumptions before writing code.
- **Push Back:** If a requested task introduces unnecessary complexity, explicitly suggest a simpler approach first.

### Design Conversations (non-trivial changes)
- **Look First:** Read the relevant code before asking; don't ask what it already answers.
- **One Question at a Time.**
- **Three Options:** Offer 3 approaches with tradeoffs; "do nothing" is a valid one. Recommend one, wait for my pick.
- **Cite Prior Art:** Back every option or solution you offer with its provenance where one exists: a known implementation ("the Linux kernel uses bitmaps here"), a paper, a standard. Say when you know of none; never invent one.
- **Label Your Calls:** Mark anything you filled in as your decision, with the reason. No silent defaults.
- **Scope Creep:** If the work grows mid-task, stop and say so.

### Simplicity First
- **Zero Speculative Code:** Write only the minimum code required to solve the immediate problem.
- **No Premature Abstractions:** Do not create wrappers, utility classes, or interfaces for single-use code. No function-pointer table or wrapper until two implementations need it.
- **Validate at Boundaries:** Check CLI args, config, files and network input where they enter; trust them inside.
- **Zero Unrequested Flexibility:** Do not add configuration options, flags, or parameters unless requested.

### Surgical Execution
- **Strict Scope Boundaries:** Touch only the files and lines necessary for the request. Do not format or re-style adjacent code.
- **Clean Your Own Mess:** Only delete unused imports, variables, or functions introduced by YOUR changes.
- **Style Matching:** Adhere strictly to existing codebase formatting and architectural patterns.

---

## 2. Execution & Workflow Directives

### Goal Verification & Error Recovery
- **Atomic File Edits:** Make edits incrementally. Do not generate massive multi-function files in a single tool call payload.
- **Failure Diagnostics:** If a command or build fails, analyze the diagnostic output and isolate root causes before patching.

### Debugging
- **Feedback Loop First:** Before theorising, get one fast command that fails on this exact symptom, then shrink the repro until every remaining part is needed.
- **Ranked Hypotheses:** List 3–5 falsifiable hypotheses ("if X, changing Y makes it go away"); show me before testing.
- **Fix at the Source:** Trace a bad value back to where it originates. If that state should be impossible, a guard where it broke hides the bug; find what produced it.
- **One Change at a Time:** One hypothesis, one minimal change. Never stack fixes.
- **Two Strikes:** After 2 failed fixes, write down the premise they shared and test it, then discuss.
- **Regression Tests:** A regression test must fail without the fix.
- **Tagged Debug Output:** Prefix temporary prints `[DEBUG-xxxx]`; remove them all before finishing.

### Measurement
- **Benchmarks:** Before reporting or acting on a performance number, follow `~/.config/agents/skills/benchmark-checklist/SKILL.md`.

### Review Feedback (mine, tools', or external)
- **No Performative Agreement:** Check each point against the code, then fix it or push back with reasons.
- **Clarify First:** If any item is unclear, ask before implementing any of them.
- **YAGNI Check:** Before building something out "properly", check it is used (`rg`); if not, propose removing it.
- **Prior Decisions Win:** Feedback that conflicts with a decision I made → ask.
- **Contradictions:** When code, docs and what I told you disagree, report it and ask. Don't pick a side.

### Delegated Implementation
- **Briefs Carry Decisions:** File, exact signature, test + assertions, pinned values. The implementer writes the bodies. A brief longer than the code is the code.

### Workspace Map
- `~/projects/<repo>` — THG projects I'm actively working on.
- `~/thg-src/<org>/<repo>` — THG source estate, a **read-only** snapshot (enforced by hook). `~/thg-src/estate/` and files at the `~/thg-src` root are writable; `~/thg-src/AGENTS.md` covers the estate.
- `~/side/<project>` — side projects, prototypes and unpromoted work.
- `~/thoughts` — my Obsidian vault (meeting notes, ideas, project fragments). Before non-trivial work and on finishing a unit of work, follow `~/.config/agents/vault.md`. Agents write only in `~/thoughts/agent/`.
- A project's own `AGENTS.md` overrides this file.

### Tooling & Workspace Hierarchy
- **Code Intelligence & Search:**
  1. **Structural Graph Search (`ripwire`):** Primary mechanism for context packing, call graphs, and orientation:
     - Project orientation: `ripwire .`
     - Task context: `ripwire . --pack-task="<task description>"`
     - Callers & blast radius: `ripwire . --callers=<symbol>` or `ripwire . --impact=<symbol>`
  2. **Exact Text Search (`rg`):** Fallback for literal string matching (`rg -F`). Restrict scope using `--type` or `-g`.
  3. **No `grep`:** it is denied in permissions, including inside pipelines. Use `rg` for filtering too (`rg -v`, `rg -n`, `rg -c`, `rg -x`).
- **Quiet Output:** Use quiet flags on commands with progress output (`pull -q`, `--quiet`), or show only the tail.
- **Build System Convention:** For C projects, assume `nob.c` is the build runner (`./nob`). Do not invoke `make` or `cmake` unless instructed.
- **Claude Code hooks (`~/.config/agents/hooks/`; logs stay in `~/.claude/hooks/`):** a jq program longer than ~5 lines goes in a sibling `<hook>.jq` file run with `jq -f`, never inside a shell-quoted string; check it compiles with `jq -n -f <hook>.jq` before wiring it up. Test every hook with `~/.config/agents/tools/hook-test.sh` and keep its cases in `~/.config/agents/hooks/tests/<hook>.tsv`.

### Tool Selection (before writing any helper script)
Shell one-liners and pipelines are fine and do not count as scripts. Before writing a script, go in this order:
1. **Installed tools first:** coreutils, `rg`, `awk`, `sqlite3`, `jq`, `ripwire`, and the project's own tools (`tools/`, `nob`). Check with `command -v`.
2. **Personal index next:** read `~/.config/agents/tools/tools.md`, then use or extend a matching tool.
3. **Missing well-known tool → stop and say so.** If a common tool (e.g. `jq`, `mlr`, `qsv`, `fd`, `yq`) would make the task trivial and is not installed, say: "This would be simple with `<tool>` (`brew install <tool>`). Install it, or should I write a script?" Do not install it yourself.
4. **Script last.** A one-off script goes in the session scratchpad. If it is reusable, propose saving it ("I'd like to save this as `<name>`: <purpose>"). Promote it to `~/.config/agents/tools/` only on approval and under the admission rules in `tools.md`.

### Git Rule
- **Never run state-modifying git commands.** The user always runs them: `add`, `commit`, `push`, `pull`, `fetch`, `checkout`/`switch`, `branch` (anything beyond listing), `merge`, `rebase`, `reset`, `stash`, `tag`, `clean`, `restore`, `rm`, `mv`, `config`, `init` and anything similar, plus `gh pr create`/`ready`/`merge`. Do not offer to run them either. Read-only commands (`status`, `diff`, `log`, `show`, `ls-files`, `blame`, `branch` listing, `gh pr view`/`list`/`diff`) are fine.
- When work is ready, list the exact commands for the user to run instead.

### Secrets Rule
- **Never ingest secrets.** Don't open files whose names suggest credentials (`*key*`, `*token*`, `*password*`, keepass). If you see a key, password or token anyway, don't copy, quote, summarise or store it: not in notes, memory, logs, or prompts to other models. Refer to it by location only.

### Dependency Rule
- **Native/Zero-Dep Priority:** Never install third-party packages or alter host shell environments without explicit confirmation. Always favor standard C libraries and native APIs.
- When asking, explain why it is needed and why it can't reasonably be done without it.

---

## 3. Response Format

- **Direct & Concise:** Omit conversational preamble, pleasantries, apologies, and structural setups. Lead directly with technical solutions, commands, or diffs.
- **Honest Status:** Report only the checks you actually ran ("built with `./nob`, no warnings"). Building is not running: never claim the code works.
