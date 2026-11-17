#!/bin/sh
# Status line: claude.ai plan usage left in the 5-hour and 7-day windows, with reset times.
# Claude Code pipes JSON on stdin; rate_limits.{five_hour,seven_day} = {used_percentage,
# resets_at (epoch s)}. It is present only on a claude.ai login, after the session's first
# API reply; until then this prints "usage: n/a".
#
# Also the only writer of the usage log (USAGE_LOG, default ~/.claude/usage.tsv), read by
# tools/weekly-usage.sh: one row when the percentages or reset times change,
#   epoch  session_id  5h_used  5h_resets_at  7d_used  7d_resets_at   ('' = window absent)
LOG=${USAGE_LOG:-$HOME/.claude/usage.tsv}
out=$(jq -r '
  def left(w; fmt):
    if w == null then empty
    else "\(100 - (w.used_percentage | floor))% left (resets \(w.resets_at | localtime | strftime(fmt)))"
    end;
  .rate_limits as $r
  | ([ (left($r.five_hour; "%H:%M") | "5h " + .),
       (left($r.seven_day; "%a %H:%M") | "7d " + .) ]
     | if length == 0 then "usage: n/a" else join(" · ") end),
    (if $r.five_hour == null and $r.seven_day == null then ""
     else [ $r.five_hour.used_percentage, $r.five_hour.resets_at,
            $r.seven_day.used_percentage, $r.seven_day.resets_at ]
          | map(. // "" | tostring) | join("\t") end),
    (.session_id // "")
')
line=$(printf '%s\n' "$out" | sed -n 1p)
vals=$(printf '%s\n' "$out" | sed -n 2p)
session=$(printf '%s\n' "$out" | sed -n 3p)
if [ -n "$vals" ]; then
    last=$(tail -n 1 "$LOG" 2>/dev/null | cut -f 3-)
    [ "$vals" = "$last" ] || printf '%s\t%s\t%s\n' "$(date +%s)" "$session" "$vals" >> "$LOG"
fi
printf '%s\n' "$line"
