# Retrospective

Purpose: turn friction from the task just finished into lasting improvements, so the next
session does not pay for it again. Triggered by a Stop hook after long tasks; applies to any
project.

## Look back over this task for
- **Repeated or improvised work:** a script, query or command sequence written from scratch or
  run more than once → candidate for `~/.config/agents/tools/` (see `tools.md`), a project tool,
  or a skill.
- **Missing tools:** a well-known tool that would have made a step trivial → suggest installing it.
- **Rule gaps:** an instruction you lacked, misread or nearly broke → a proposed edit to
  `AGENTS.md`, or a hook if it must never happen.
- **Wasted effort:** dead ends, re-reading the same files, wrong first guesses about the codebase
  → a note for project docs or memory.

## Rules
- Read `~/.config/agents/retro/inbox.md` first; do not repeat an open proposal.
- At most 3 proposals, each with concrete evidence from this session.
- "Nothing worth changing" is a valid outcome: say so in one line and append nothing.
- Propose only. Never change config, tools, hooks or `AGENTS.md` during the retro.
- No secrets, hostnames or finding details: describe the pattern, not the data.
- Append to the inbox, then tell the user in 1–3 lines what was added.

## Inbox entry format
```
## YYYY-MM-DD — <project dir>
- [tool|install|rule|hook|doc] <proposal> — evidence: <what happened> — effort: S/M/L
```
