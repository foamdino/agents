#!/bin/sh
# Stop hook: when the agent edited .c/.h files since the last real user prompt,
# run ./nob test in each nob project those files belong to (nearest ancestor with
# nob.c), so "done" means the tests pass.
#
# Edits are Edit/Write/MultiEdit tool calls in the transcript (Bash edits are not
# seen). On failure the stop is blocked with the last lines of output; if this
# stop already follows a hook block (stop_hook_active), it is let through with a
# warning to the user instead, so a test the agent cannot fix never loops.
# NOB_TEST=0 disables it. Output: a Stop decision or systemMessage, or nothing.

[ "${NOB_TEST:-1}" = 0 ] && exit 0

input=$(cat)
transcript=$(printf '%s' "$input" | jq -r '.transcript_path // empty')
[ -n "$transcript" ] && [ -r "$transcript" ] || exit 0
active=$(printf '%s' "$input" | jq -r '.stop_hook_active // false')

files=$(jq -rn '
  reduce inputs as $r ([];
    if $r.type == "user" and ($r.isMeta | not)
       and ($r.message.content | type == "string"
            or (type == "array" and all(.[]; .type == "text")))
    then []
    elif $r.type == "assistant"
    then . + [$r.message.content[]?
              | select(.type == "tool_use" and (.name | test("^(Edit|Write|MultiEdit)$")))
              | .input.file_path // empty
              | select(test("\\.[ch]$"))]
    else . end)
  | unique[]
' "$transcript" 2>/dev/null) || exit 0
[ -n "$files" ] || exit 0

roots=$(printf '%s\n' "$files" | while IFS= read -r f; do
	d=$(dirname "$f")
	while [ "$d" != / ] && [ ! -f "$d/nob.c" ]; do d=$(dirname "$d"); done
	[ -f "$d/nob.c" ] && [ -x "$d/nob" ] && printf '%s\n' "$d"
done | sort -u)
[ -n "$roots" ] || exit 0

failed=""
for r in $roots; do
	out=$(cd "$r" && ./nob test 2>&1) || failed="$failed
== $r: ./nob test failed
$(printf '%s\n' "$out" | tail -25)"
done
[ -n "$failed" ] || exit 0

if [ "$active" = true ]; then
	jq -nc --arg m "nob-test-on-stop: tests still failing after the agent's retry.$failed" \
		'{systemMessage: $m}'
else
	jq -nc --arg m "C files were edited and the tests fail. Fix them, or explain to the user why not, before stopping.$failed" \
		'{decision: "block", reason: $m}'
fi
