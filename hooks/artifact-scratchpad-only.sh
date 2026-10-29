#!/bin/sh
# PreToolUse hook (Artifact): only files in the session scratchpad
# (/private/tmp/claude-*/ or /tmp/claude-*/) may be published or uploaded.
# Anything in a project tree, such as a report HTML, stays local.
#
# Looks at publish calls only (action omitted or "publish"): file_path,
# file_paths[], and the local sources in files (a string, {from} or {path};
# {artifact, path} copies from another artifact and is not local). Relative
# paths resolve against root, then the session cwd. A path containing ".."
# is refused outright. Symlinks are not resolved.
# Output: a PreToolUse "deny" decision naming the path; nothing otherwise.

jq -c '
  def absolute($base): if startswith("/") then . else "\($base)/\(.)" end;
  def allowed: (startswith("/private/tmp/claude-") or startswith("/tmp/claude-"))
               and (test("(^|/)\\.\\.(/|$)") | not);

  select((.tool_input.action // "publish") == "publish")
  | (.cwd // "") as $cwd
  | ((.tool_input.root // null) | if . == null then $cwd else absolute($cwd) end) as $base
  | [ .tool_input.file_path,
      (.tool_input.file_paths // [])[],
      ((.tool_input.files // []) | if type == "object" then .[] else .[] end
        | if type == "string" then .
          elif type == "object" and has("artifact") then empty
          elif type == "object" then (.from // .path // empty)
          else empty end)
    ]
  | map(select(type == "string") | absolute($base))
  | first(.[] | select(allowed | not)) as $bad
  | {hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked by ~/.config/agents/hooks/artifact-scratchpad-only.sh: \($bad) is outside the session scratchpad. Files in project trees are never published; build the page in the scratchpad if it is meant to be shared."
    }}
'
