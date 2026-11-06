#!/bin/sh
# hook-test.sh: run a Claude Code hook script against a table of cases.
usage() {
	cat <<'EOF'
usage: hook-test.sh <hook-script> <cases.tsv>

Feeds each case to the hook on stdin as hook-input JSON and compares the
decision it prints with the expected one. Exit 0 when every case passes.

cases.tsv: tab-separated, one case per line; blank lines and # comments skipped.
  expect  tool  value  [cwd]  [env]
  expect  deny | allow | ask   (PreToolUse: hookSpecificOutput.permissionDecision)
          block                (Stop/PostToolUse: .decision)
          none                 (no output at all; "allow" also passes on no output)
  tool    tool_name: Bash, Edit, Write, ...; or "-" to pass value as the whole
          input JSON (for Stop hooks: transcript_path, stop_hook_active, ...)
  value   Bash: the command. File tools: file_path. "-": a JSON object.
  cwd     optional; defaults to the current directory ("-" also means default).
  env     optional; space-separated VAR=value pairs set for the hook (no
          spaces inside a value).
  "output" as expect matches any JSON without a decision (SessionStart context).

example:
  printf 'deny\tBash\tbrew install x\nallow\tBash\tbrew list\n' > cases.tsv
  hook-test.sh ~/.config/agents/hooks/bash-guard.sh cases.tsv
EOF
}

case "$1" in -h | --help | "") usage; exit 0 ;; esac
[ $# -eq 2 ] || { usage >&2; exit 2; }
hook=$1
cases=$2
[ -x "$hook" ] || { echo "hook-test: $hook is not executable" >&2; exit 2; }
[ -r "$cases" ] || { echo "hook-test: cannot read $cases" >&2; exit 2; }

tab=$(printf '\t')
pass=0
fail=0
while IFS="$tab" read -r expect tool value cwd vars; do
	case "$expect" in "" | \#*) continue ;; esac
	[ "$cwd" = - ] && cwd=
	if [ "$tool" = - ]; then
		input=$value
	else
		input=$(jq -nc --arg t "$tool" --arg v "$value" --arg c "${cwd:-$PWD}" '
		  {tool_name: $t, cwd: $c, hook_event_name: "PreToolUse",
		   tool_input: (if $t == "Bash" then {command: $v} else {file_path: $v} end)}')
	fi
	# shellcheck disable=SC2086 # vars is a list of VAR=value words
	out=$(printf '%s' "$input" | env $vars "$hook" 2>&1)
	if [ -z "$out" ]; then
		got=none
	else
		got=$(printf '%s' "$out" | jq -r '.hookSpecificOutput.permissionDecision // .decision // "output"' 2>/dev/null) ||
			got="error: $(printf '%s' "$out" | head -1)"
	fi
	if [ "$got" = "$expect" ] || { [ "$expect" = allow ] && [ "$got" = none ]; }; then
		pass=$((pass + 1))
		printf 'ok    %-6s %s\n' "$expect" "$value"
	else
		fail=$((fail + 1))
		printf 'FAIL  %-6s got %s: %s\n' "$expect" "$got" "$value"
	fi
done <"$cases"

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
