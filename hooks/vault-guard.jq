# vault-guard.sh: deny writes to ~/thoughts outside ~/thoughts/agent/.
# Run as: jq -c --arg home "$HOME" -f vault-guard.jq   (stdin: PreToolUse input)
# Bash is a heuristic, like snapshot-readonly.sh: a > / >> / tee into a protected path,
# sed -i / perl -i / rm / mv / touch / truncate / mkdir / chmod / ln naming one, or
# cp / rsync / install with one as the last argument.
def deny($what): {hookSpecificOutput: {
  hookEventName: "PreToolUse",
  permissionDecision: "deny",
  permissionDecisionReason: "Blocked by ~/.config/agents/hooks/vault-guard.sh: \($what) is the user's own vault note. Agents write only in ~/thoughts/agent/ (~/.config/agents/vault.md)."
}};
("(\($home)|~|\\$HOME|\\$\\{HOME\\})/thoughts/(?!agent(/|$))") as $prot
| if .tool_name == "Bash" then
    (.tool_input.command // "") as $c
    | ($c | (test("(>>?|\\btee\\s+(-a\\s+)?)\\s*[\"\\x27]?\($prot)")
        or (test("(^|[;&|(]\\s*)(sudo\\s+)?(sed\\s+(-[a-zA-Z]*\\s+)*-i|perl\\s+-[a-zA-Z]*i|rm|mv|touch|truncate|mkdir|chmod|ln)\\b") and test($prot))
        or test("(^|[;&|(]\\s*)(cp|rsync|install)\\b[^;&|]*\\s(\"\($prot)[^\"]*\"|\\x27\($prot)[^\\x27]*\\x27|\($prot)[^\\s;&|]*)\\s*($|[;&|])"))
    ) as $hit
    | if $hit then deny("the command `\($c | .[0:120])`") else empty end
  else
    (.tool_input.file_path // .tool_input.notebook_path // "") as $p
    | if ($p | test("^\($prot)")) then deny($p) else empty end
  end
