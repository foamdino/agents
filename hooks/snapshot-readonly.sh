#!/bin/sh
# PreToolUse hook (Edit|Write|MultiEdit|NotebookEdit|Bash): ~/thg-src/<org>/ is a
# read-only snapshot. estate/ and files at the root of ~/thg-src stay writable.
#
# File tools: the target path (absolute, as the tools require) under an org dir.
# Bash: a heuristic, not a sandbox. Denies a command that names an org path
# (~/thg-src/<org>/, /Users/.../thg-src/<org>/, or ../<org>/ from estate) together
# with a writing verb: a > or >> redirect into it, sed -i / perl -i, rm, mv,
# touch, tee, truncate, mkdir, chmod, ln, or cp/rsync/install with it last.
# Org names are read from the directory listing on every call.
# Output: a PreToolUse "deny" decision naming the path; nothing otherwise.

root="$HOME/thg-src"
orgs=$(cd "$root" 2>/dev/null && for d in */; do
	d=${d%/}
	[ "$d" = estate ] || printf '%s|' "$d"
done)
[ -n "$orgs" ] || exit 0
orgs=${orgs%|}

jq -c --arg root "$root" --arg orgs "$orgs" '
  def deny($what): {hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "deny",
    permissionDecisionReason: "Blocked by ~/.config/agents/hooks/snapshot-readonly.sh: \($what) is in the read-only ~/thg-src snapshot (thg-src/AGENTS.md: do not modify any repo under <org>/). Write analysis files at the thg-src root or in estate/."
  }};
  ("(\($root)|~/thg-src|\\$HOME/thg-src|\\$\\{HOME\\}/thg-src)/(\($orgs))(/|$)") as $abs
  | ("(\($abs)|(?<![^\\s\"\\x27=])\\.\\./(\($orgs))/)") as $any
  | if .tool_name == "Bash" then
      (.tool_input.command // "") as $c
      | ($c | (test("(>>?|\\btee\\s+(-a\\s+)?)\\s*[\"\\x27]?\($any)")
          or (test("(^|[;&|(]\\s*)(sudo\\s+)?(sed\\s+(-[a-zA-Z]*\\s+)*-i|perl\\s+-[a-zA-Z]*i|rm|mv|touch|truncate|mkdir|chmod|ln)\\b") and test($any))
          or test("(^|[;&|(]\\s*)(cp|rsync|install)\\b[^;&|]*\\s[\"\\x27]?\($any)[^\\s;&|]*\\s*($|[;&|])"))
      ) as $hit
      | if $hit then deny("the command `\($c | .[0:120])`") else empty end
    else
      (.tool_input.file_path // .tool_input.notebook_path // "") as $p
      | if ($p | test("^\($abs)")) then deny($p) else empty end
    end
'
