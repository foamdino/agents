#!/bin/sh
# weekly-usage.sh: Claude plan usage and tokens per project since a date.
usage() {
	cat <<'EOF'
usage: weekly-usage.sh [--since YYYY-MM-DD] LOG TRANSCRIPTS_DIR

plan    from LOG (the status line's usage log, written by
        hooks/statusline.sh: epoch, session, 5h used, 5h reset, 7d used,
        7d reset). Per 7-day window touched since --since: peak % used and
        reset time. Per 5-hour window: how many, the peak, how many hit 80%+.
        Says when the log starts after --since (partial week).
tokens  from TRANSCRIPTS_DIR (Claude Code's ~/.claude/projects): assistant
        replies on or after --since (UTC date of the reply), one row per
        message id, each charged to the git repo of the directory it ran
        in (the directory itself when it is not in a repo): sessions that
        touched the repo, replies, output tokens, input tokens (fresh +
        cache read + cache write), share of the week's output.

--since defaults to 7 days before today.

example:
  weekly-usage.sh ~/.claude/usage.tsv ~/.claude/projects
EOF
}

since=
while [ $# -gt 0 ]; do
	case $1 in
	-h | --help) usage; exit 0 ;;
	--since) since=$2; shift 2 ;;
	-*) usage >&2; exit 2 ;;
	*) break ;;
	esac
done
[ $# -eq 2 ] || { usage >&2; exit 2; }
log=$1 dir=$2
[ -d "$dir" ] || { echo "no such directory: $dir" >&2; exit 2; }
[ -n "$since" ] || since=$(date -v-7d +%F 2>/dev/null || date -d '7 days ago' +%F)
case $since in
[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
*) echo "--since must be YYYY-MM-DD: $since" >&2; exit 2 ;;
esac
from=$(date -j -f '%Y-%m-%d %H:%M:%S' "$since 00:00:00" +%s 2>/dev/null || date -d "$since" +%s)

echo "since $since"
echo
echo "plan (status-line log)"
if [ ! -s "$log" ]; then
	echo "  no log at $log yet"
else
	when() { date -r "$1" "+$2" 2>/dev/null || date -d "@$1" "+$2"; }
	awk -F '\t' -v from="$from" '
	NR == 1 { first = $1 }
	$1 >= from {
		n++
		if ($4 != "") { k = int($4 / 3600); if (!(k in p5) || $3 > p5[k]) p5[k] = $3 }
		if ($6 != "") { k = int($6 / 3600); if (!(k in p7) || $5 > p7[k]) { p7[k] = $5; r7[k] = $6 } }
	}
	END {
		if (first > from) printf "start\t%d\n", first
		if (!n) { print "none"; exit }
		for (k in p7) printf "7d\t%d\t%d\n", r7[k], p7[k]
		c = 0; hi = 0; top = 0
		for (k in p5) { c++; if (p5[k] >= 80) hi++; if (p5[k] > top) top = p5[k] }
		if (c) printf "5h\t%d\t%d\t%d\n", c, top, hi
	}' "$log" | sort -k1,1r -k2,2n | while IFS="$(printf '\t')" read -r kind a b c; do
		case $kind in
		start) echo "  log starts $(when "$a" '%Y-%m-%d %H:%M'): partial week" ;;
		none) echo "  no rows since then" ;;
		7d) echo "  7-day window resetting $(when "$a" '%a %Y-%m-%d %H:%M'): peak $b% used" ;;
		5h) echo "  5-hour windows: $a, peak $b% used, $c at 80%+" ;;
		esac
	done
fi

echo
echo "tokens (transcripts, per repo)"
rows=$(mktemp)
trap 'rm -f "$rows"' EXIT
fd -e jsonl . "$dir" -0 | xargs -0 cat | jq -r --arg since "$since" '
	select(.type == "assistant" and (.timestamp // "") >= $since and .message.usage != null)
	| .message.usage as $u
	| [ (.cwd // "?"), (.sessionId // "?"), (.message.id // .uuid),
	    ($u.output_tokens // 0),
	    (($u.input_tokens // 0) + ($u.cache_read_input_tokens // 0) + ($u.cache_creation_input_tokens // 0)) ]
	| @tsv' 2>/dev/null > "$rows"
# Each distinct cwd -> its git repo root (the cwd itself when not in a repo or gone), then join.
cut -f 1 "$rows" | sort -u | while IFS= read -r d; do
	printf '%s\t%s\n' "$d" "$(git -C "$d" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$d")"
done | awk -F '\t' -v home="$HOME" '
	NR == FNR { root[$1] = $2; next }
	!seen[$3]++ {
		p = root[$1]; if (index(p, home) == 1) p = "~" substr(p, length(home) + 1)
		if (!((p, $2) in s)) { s[p, $2] = 1; ses[p]++ }
		rep[p]++; out[p] += $4; inp[p] += $5; tot += $4
	}
	END {
		if (!tot) { print "  none"; exit }
		printf "%d\t  %-56s %8s %8s %12s %14s %6s\n", -1, "repo", "sessions", "replies", "output", "input", "share"
		for (p in rep) printf "%d\t  %-56s %8d %8d %12d %14d %5.1f%%\n", out[p], p, ses[p], rep[p], out[p], inp[p], 100 * out[p] / tot
		printf "%d\t  %-56s %8s %8s %12d\n", -2, "total", "", "", tot
	}' - "$rows" | sort -t "$(printf '\t')" -k1,1nr | awk -F '\t' '$1 == -1 { h = $2; next } $1 == -2 { t = $2; next } { r[++n] = $2 } END { if (h != "") print h; for (i = 1; i <= n; i++) print r[i]; if (t != "") print t }'
