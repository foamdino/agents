#!/bin/sh
# PreToolUse hook (Edit|Write|MultiEdit|NotebookEdit|Bash): the Obsidian vault at
# ~/thoughts is the user's; agents write only in ~/thoughts/agent/. The check is
# vault-guard.jq. Output: a PreToolUse "deny" decision naming the path; nothing otherwise.

jq -c --arg home "$HOME" -f "$(dirname "$0")/vault-guard.jq"
