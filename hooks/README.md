# Claude Code hooks

Scripts that `~/.claude/settings.json` runs. They are specific to Claude Code (its hook input
and output JSON); the rest of this repo is agent-agnostic. Logs stay in `~/.claude/hooks/`
(`agent-audit.log`, `error.log`), outside the repo.

| Hook | Event / matcher | Does |
|---|---|---|
| `html-no-external.sh` | PreToolUse `Edit\|Write\|MultiEdit` | report HTML must be self-contained |
| `artifact-scratchpad-only.sh` | PreToolUse `Artifact` | only scratchpad files are published |
| `snapshot-readonly.sh` | PreToolUse `Edit\|Write\|MultiEdit\|NotebookEdit\|Bash` | `~/thg-src/<org>/` is read-only |
| `vault-guard.sh` | PreToolUse `Edit\|Write\|MultiEdit\|NotebookEdit\|Bash` | `~/thoughts` is read-only except `agent/` |
| `bash-guard.sh` | PreToolUse `Bash` | no package installs; no make/cmake under `nob.c` |
| `retro-gate.sh` | Stop | retrospective after long tasks (`../retro.md`) |
| `vault-gate.sh` | Stop | vault note after a unit of work (`../vault.md`) |
| `nob-test-on-stop.sh` | Stop | `./nob test` when C files were edited |
| `weekly-due.sh` | SessionStart `startup` | reminder when the weekly review (`../weekly.md`) is 7+ days old |

Test: `~/.config/agents/tools/hook-test.sh <hook> tests/<hook>.tsv`. Conventions are in
`../AGENTS.md` (Claude Code hooks).

## Registration

`settings.json` is not tracked (it also holds model and plugin state). To rebuild the wiring,
merge this `hooks` block into `~/.claude/settings.json`:

```json
"hooks": {
  "PreToolUse": [
    {"matcher": "Edit|Write|MultiEdit", "hooks": [{"type": "command", "command": "~/.config/agents/hooks/html-no-external.sh"}]},
    {"matcher": "Artifact", "hooks": [{"type": "command", "command": "~/.config/agents/hooks/artifact-scratchpad-only.sh"}]},
    {"matcher": "Edit|Write|MultiEdit|NotebookEdit|Bash", "hooks": [
      {"type": "command", "command": "~/.config/agents/hooks/snapshot-readonly.sh"},
      {"type": "command", "command": "~/.config/agents/hooks/vault-guard.sh"}
    ]},
    {"matcher": "Bash", "hooks": [{"type": "command", "command": "~/.config/agents/hooks/bash-guard.sh"}]}
  ],
  "Stop": [
    {"hooks": [
      {"type": "command", "command": "~/.config/agents/hooks/retro-gate.sh", "timeout": 30},
      {"type": "command", "command": "~/.config/agents/hooks/vault-gate.sh", "timeout": 30},
      {"type": "command", "command": "~/.config/agents/hooks/nob-test-on-stop.sh", "timeout": 300}
    ]}
  ],
  "SessionStart": [
    {"matcher": "startup", "hooks": [{"type": "command", "command": "~/.config/agents/hooks/weekly-due.sh", "timeout": 10}]}
  ]
}
```
