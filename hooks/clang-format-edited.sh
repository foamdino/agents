#!/bin/sh
# PostToolUse hook (Edit|Write|MultiEdit): clang-format the lines the agent just
# wrote in a .c/.h file, and nothing else. Many trees are not clang-format clean,
# so formatting whole files would restyle code nobody touched.
#
# Lines come from tool_response.structuredPatch: the "+" lines of each hunk,
# numbered from newStart. A Write that created the file formats all of it.
# --style=file --fallback-style=none: a file with no .clang-format above it is
# left alone. Silent; formatter errors are dropped so a tool call never fails here.

jq -r '
  (.tool_response.filePath // .tool_input.file_path // "") as $f
  | select($f | test("\\.[ch]$"))
  | if (.tool_response.structuredPatch | type) == "array"
       and (.tool_response.structuredPatch | length) > 0 then
      [ .tool_response.structuredPatch[]
        | reduce .lines[] as $l ({n: .newStart, out: []};
            if ($l | startswith("+")) then .out += [.n] | .n += 1
            elif ($l | startswith("-")) then .
            else .n += 1 end)
        | .out[] ]
      | select(length > 0)
      | [$f] + map("--lines=\(.):\(.)")
    elif .tool_response.type == "create" then [$f]
    else empty end
  | @sh
' | {
	read -r args || exit 0
	eval "set -- $args"
	f=$1
	shift
	clang-format -i --style=file --fallback-style=none "$@" "$f" 2>/dev/null
}
exit 0
