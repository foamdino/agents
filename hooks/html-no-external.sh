#!/bin/sh
# PreToolUse hook (Edit|Write|MultiEdit): refuse new content in an .html/.htm
# file that would load anything from outside the file itself (scripts,
# stylesheets, fonts, images, frames, imports, network calls). Plain <a href>
# links are allowed: they are navigation, not dependencies.
#
# Checks only the text being written (Write content, Edit new_string, every
# MultiEdit new_string), so existing content is not re-flagged.
# Output: a PreToolUse "deny" decision with the rule that matched; nothing
# when the change is clean or the file is not HTML.

jq -c '
  def rules: [
    ["an external src (script, img, iframe, source, video, audio, embed, track, input)",
     "<(script|img|iframe|frame|source|video|audio|embed|track|input)\\b[^>]*\\bsrc(set)?\\s*=\\s*[\"'"'"']?\\s*(https?:)?//"],
    ["an external <link href> (stylesheet, font, preload, icon)",
     "<link\\b[^>]*\\bhref\\s*=\\s*[\"'"'"']?\\s*(https?:)?//"],
    ["an external <object data>",
     "<object\\b[^>]*\\bdata\\s*=\\s*[\"'"'"']?\\s*(https?:)?//"],
    ["a <form action> posting off the page",
     "<form\\b[^>]*\\baction\\s*=\\s*[\"'"'"']?\\s*(https?:)?//"],
    ["a CSS @import",
     "@import\\b"],
    ["a CSS url() to another origin",
     "url\\(\\s*[\"'"'"']?\\s*(https?:)?//"],
    ["a meta refresh",
     "http-equiv\\s*=\\s*[\"'"'"']?refresh"],
    ["a JS import from a URL",
     "\\bimport\\b[^;\\n]*[\"'"'"'](https?:)?//"],
    ["a JS network call (fetch, XMLHttpRequest, WebSocket, EventSource, sendBeacon, importScripts)",
     "\\b(fetch|XMLHttpRequest|WebSocket|EventSource|sendBeacon|importScripts)\\s*\\("]
  ];

  (.tool_input.file_path // "") as $f
  | select($f | test("\\.html?$"; "i"))
  | ([.tool_input.content, .tool_input.new_string, ((.tool_input.edits // [])[] | .new_string)]
     | map(select(type == "string")) | join("\n")) as $t
  | first(rules[] | select(.[1] as $re | $t | test($re; "i")) | .[0]) as $hit
  | {hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Blocked by ~/.config/agents/hooks/html-no-external.sh: the change to \($f) adds \($hit). Report-style HTML must be self-contained: inline the code, style or data instead."
    }}
'
