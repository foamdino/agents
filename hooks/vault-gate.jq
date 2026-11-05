# vault-gate.sh: tool calls and file edits since the last real user prompt.
# Run as: jq -n -r -f vault-gate.jq <transcript.jsonl>   Output: "<tools> <edits>"
# A real prompt is string content or text blocks only (not tool results, not isMeta),
# the same reset rule as retro-gate.sh.
reduce inputs as $r ({tools: 0, edits: 0};
  if $r.type == "user" and ($r.isMeta | not)
     and ($r.message.content | type == "string"
          or (type == "array" and all(.[]; .type == "text")))
  then {tools: 0, edits: 0}
  elif $r.type == "assistant"
  then [$r.message.content[]? | select(.type == "tool_use")] as $t
    | .tools += ($t | length)
    | .edits += ([$t[] | select(.name | test("^(Edit|Write|MultiEdit|NotebookEdit)$"))] | length)
  else . end)
| "\(.tools) \(.edits)"
