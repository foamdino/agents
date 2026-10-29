#!/bin/sh
# Stop hook: after a long task, ask the agent for a short retrospective
# (~/.config/agents/retro.md) before it stops.
#
# Long = at least RETRO_MIN_TOOLS (default 25) tool calls since the last real
# user prompt (string content or text blocks, not tool results, not isMeta).
# Counting from the last prompt resets the gate per task, so no state file.
# stop_hook_active (set when this Stop follows a hook block) lets the stop
# through, so the retro runs at most once per stop. RETRO=0 disables it.
# Each block is logged to ~/.claude/hooks/agent-audit.log for tuning.
# Output: a Stop "block" decision, or nothing.

[ "${RETRO:-1}" = 0 ] && exit 0

input=$(cat)
[ "$(printf '%s' "$input" | jq -r '.stop_hook_active // false')" = true ] && exit 0

transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -r "$transcript" ] || exit 0

count=$(jq -n '
  reduce inputs as $r (0;
    if $r.type == "user" and ($r.isMeta | not)
       and ($r.message.content | type == "string"
            or (type == "array" and all(.[]; .type == "text")))
    then 0
    elif $r.type == "assistant"
    then . + ([$r.message.content[]? | select(.type == "tool_use")] | length)
    else . end)
' "$transcript" 2>/dev/null) || exit 0

[ "${count:-0}" -ge "${RETRO_MIN_TOOLS:-25}" ] || exit 0

printf '%s' "$input" | jq -c --arg ts "$(date -u '+%FT%TZ')" --argjson n "$count" \
	'{timestamp: $ts, session_id, event: "retro-gate", tool_calls: $n, cwd}' \
	>>"$HOME/.claude/hooks/agent-audit.log"

jq -n --arg n "$count" '{
  decision: "block",
  reason: "Long task (\($n) tool calls). Before stopping, run the retrospective in ~/.config/agents/retro.md: read it, follow it, append any proposals to ~/.config/agents/retro/inbox.md, then stop."
}'
