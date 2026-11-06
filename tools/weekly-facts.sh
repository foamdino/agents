#!/bin/sh
# weekly-facts.sh: per-project activity facts for a weekly review.
usage() {
	cat <<'EOF'
usage: weekly-facts.sh --author EMAIL [--since YYYY-MM-DD] DIR...

Prints one block per project directory (non-directories are skipped):
  kind     git | dir (not a git repo)
  status   active  = activity on or after --since
           warm    = activity in the 30 days before the run date
           dormant = neither
  last     date of EMAIL's newest commit on any branch ("never" if none);
           git repos only
  commits  EMAIL's non-merge commits on any branch since --since:
           date, short hash, subject
  changed  files modified since --since: uncommitted (modified or untracked,
           not ignored) for git repos; any file for dirs, skipping .git,
           build, vendor, node_modules, target, .cache
  plans    TODO/ROADMAP/PLAN/IDEAS/BACKLOG files at the root or in docs/

--since defaults to 7 days before today.

example:
  weekly-facts.sh --author me@example.com ~/projects/* ~/side/*
EOF
}

author=
since=
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help) usage; exit 0 ;;
	--author) author=$2; shift 2 ;;
	--since) since=$2; shift 2 ;;
	--) shift; break ;;
	-*) usage >&2; exit 2 ;;
	*) break ;;
	esac
done
[ -n "$author" ] && [ $# -gt 0 ] || { usage >&2; exit 2; }

days_ago() {
	date -v-"$1"d +%F 2>/dev/null || date -d "$1 days ago" +%F
}
[ -n "$since" ] || since=$(days_ago 7)
case "$since" in
[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
*) echo "weekly-facts: --since must be YYYY-MM-DD" >&2; exit 2 ;;
esac
warm=$(days_ago 30)

# Files under the current directory, from a NUL-separated list on stdin,
# modified on or after $1.
newer_than() {
	xargs -0 sh -c '[ $# -gt 0 ] && find "$@" -prune -type f -newermt "$0" -print 2>/dev/null' "$1"
}

skip_generated() {
	awk '!/(^|\/)(\.git|build|vendor|node_modules|target|\.cache)\//'
}

tree_newer_than() {
	find "$1" \( -name .git -o -name build -o -name vendor -o -name node_modules \
		-o -name target -o -name .cache \) -prune -o -type f -newermt "$2" -print
}

echo "# weekly facts: since $since, author $author, warm since $warm"
for d in "$@"; do
	[ -d "$d" ] || continue
	d=${d%/}
	echo
	echo "## $d"
	if git -C "$d" rev-parse --is-inside-work-tree >/dev/null 2>&1 &&
		[ "$(git -C "$d" rev-parse --show-toplevel)" = "$(cd "$d" && pwd -P)" ]; then
		commits=$(git -C "$d" log --all --no-merges --author="$author" \
			--since="$since 00:00" --format='%cs %h %s')
		last=$(git -C "$d" log --all --no-merges --author="$author" -1 --format=%cs)
		changed=$(cd "$d" && git ls-files -z -m -o --exclude-standard | sort -zu | newer_than "$since" | skip_generated)
		if [ -n "$commits" ] || [ -n "$changed" ]; then
			status=active
		elif [ -n "$last" ] && [ "$(echo "$last" | tr -d -)" -ge "$(echo "$warm" | tr -d -)" ]; then
			status=warm
		elif [ -n "$(cd "$d" && git ls-files -z -m -o --exclude-standard | newer_than "$warm" | skip_generated | head -1)" ]; then
			status=warm
		else
			status=dormant
		fi
		echo "kind: git"
		echo "status: $status"
		echo "last: ${last:-never}"
	else
		commits=
		changed=$(cd "$d" && tree_newer_than . "$since" | sed 's|^\./||')
		if [ -n "$changed" ]; then
			status=active
		elif [ -n "$(tree_newer_than "$d" "$warm" | head -1)" ]; then
			status=warm
		else
			status=dormant
		fi
		echo "kind: dir"
		echo "status: $status"
	fi
	if [ -n "$commits" ]; then
		echo "commits: $(echo "$commits" | wc -l | tr -d ' ')"
		echo "$commits" | sed 's/^/  /'
	fi
	if [ -n "$changed" ]; then
		echo "changed: $(echo "$changed" | wc -l | tr -d ' ')"
		echo "$changed" | head -25 | sed 's/^/  /'
	fi
	plans=$(find "$d" "$d/docs" -maxdepth 1 -type f \( -iname 'todo*' -o -iname 'roadmap*' \
		-o -iname 'plan*' -o -iname 'ideas*' -o -iname 'backlog*' \) 2>/dev/null |
		sed "s|^$d/||")
	[ -n "$plans" ] && echo "plans: $(echo "$plans" | tr '\n' ' ')"
done
