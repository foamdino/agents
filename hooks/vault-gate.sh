#!/bin/sh
# Stop hook: after a unit of work, ask the agent to record it in the Obsidian vault
# (~/.config/agents/vault.md), or say there is nothing worth noting.
#
# Fires when, since the last real user prompt, there was at least one file edit
# (Edit|Write|MultiEdit|NotebookEdit) or at least VAULT_MIN_TOOLS (default 5) tool
# calls; counted by vault-gate.jq. Whether the unit is finished (not waiting on the
# user) is the agent's call, stated in the reason. stop_hook_active lets the stop
# through, so this fires at most once per stop. VAULT=0 disables it.
# Each block is logged to ~/.claude/hooks/agent-audit.log.
# Output: a Stop "block" decision, or nothing.

[ "${VAULT:-1}" = 0 ] && exit 0

input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = true ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -r "$transcript" ] || exit 0

counts=$(jq -n -r -f "$(dirname "$0")/vault-gate.jq" "$transcript" 2>/dev/null) || exit 0
tools=${counts% *}
edits=${counts#* }

[ "${edits:-0}" -ge 1 ] || [ "${tools:-0}" -ge "${VAULT_MIN_TOOLS:-5}" ] || exit 0

printf '%s' "$input" | jq -c --arg ts "$(date -u '+%FT%TZ')" \
	--argjson t "$tools" --argjson e "$edits" \
	'{timestamp: $ts, session_id, event: "vault-gate", tool_calls: $t, edits: $e, cwd}' \
	>>"$HOME/.claude/hooks/agent-audit.log"

printf '%s' "$input" | jq '{
  decision: "block",
  reason: "Vault check (session \(.session_id)). If this unit of work is finished and not waiting on the user, follow ~/.config/agents/vault.md: write or update a note in ~/thoughts/agent/, or say in one line that nothing is worth noting. If it is not finished, stop."
}'
