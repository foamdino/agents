#!/bin/sh
# SessionStart hook: remind the agent that the weekly review
# (~/.config/agents/weekly.md) is due, so it can tell the user.
#
# Due = no "YYYY-MM-DD weekly review.md" in the notes dir dated within the
# last 7 days. The date comes from the file name, not its mtime.
# WEEKLY_NOTES_DIR and WEEKLY_TODAY override the dir and today's date (tests).
# Output: SessionStart additionalContext, or nothing.

cat >/dev/null
dir=${WEEKLY_NOTES_DIR:-$HOME/thoughts/agent}
today=${WEEKLY_TODAY:-$(date +%F)}
cutoff=$(date -j -v-7d -f %F "$today" +%F 2>/dev/null || date -d "$today -7 days" +%F) || exit 0

last=$(ls "$dir" 2>/dev/null |
	sed -n 's/^\([0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}\) weekly review\.md$/\1/p' | sort | tail -1)
if [ -n "$last" ] && [ "$(echo "$last" | tr -d -)" -gt "$(echo "$cutoff" | tr -d -)" ]; then
	exit 0
fi

jq -n --arg last "${last:-none yet}" '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: "Weekly review due (newest: \($last)). Tell the user in one line, once, at a natural point; run /weekly only if they ask."
  }
}'
