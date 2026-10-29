# AGENTS.md

Behavioral directives and workflow constraints for LLM coding agents.
Biased toward caution, surgical execution, and zero unnecessary dependencies.

---

## 1. Core Engineering Principles

### Think Before Coding
- **Surface Tradeoffs:** Never pick an ambiguous interpretation silently. State assumptions before writing code.
- **Push Back:** If a requested task introduces unnecessary complexity, explicitly suggest a simpler approach first.

### Simplicity First
- **Zero Speculative Code:** Write only the minimum code required to solve the immediate problem.
- **No Premature Abstractions:** Do not create wrappers, utility classes, or interfaces for single-use code.
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

### Tooling & Workspace Hierarchy
- **Code Intelligence & Search:**
  1. **Structural Graph Search (`ripwire`):** Primary mechanism for context packing, call graphs, and orientation:
     - Project orientation: `ripwire .`
     - Task context: `ripwire . --pack-task="<task description>"`
     - Callers & blast radius: `ripwire . --callers=<symbol>` or `ripwire . --impact=<symbol>`
  2. **Exact Text Search (`rg`):** Fallback for literal string matching (`rg -F`). Restrict scope using `--type` or `-g`.
  3. **No `grep`:** it is denied in permissions, including inside pipelines. Use `rg` for filtering too (`rg -v`, `rg -n`, `rg -c`, `rg -x`).
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

### Dependency Rule
- **Native/Zero-Dep Priority:** Never install third-party packages or alter host shell environments without explicit confirmation. Always favor standard C libraries and native APIs.
- When asking, explain why it is needed and why it can't reasonably be done without it.

---

## 3. Response Format

- **Direct & Concise:** Omit conversational preamble, pleasantries, apologies, and structural setups. Lead directly with technical solutions, commands, or diffs.
