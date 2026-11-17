#!/bin/sh
# estate-grep.sh: rg across an estate snapshot, summarised per repo with owner and activity.
set -eu

usage() {
	cat <<'EOF'
usage: estate-grep.sh [-i] [-F] [--code] [--tests] [--files] DB ROOT PATTERN [ORG...] [-- RG_OPTION...]
  DB       estate database (e.g. ~/thg-src/estate/db/current.db)
  ROOT     snapshot root holding <org>/<repo> (e.g. ~/thg-src)
  PATTERN  rg regex
  ORG      limit to these orgs; default: every org that has a repo in DB
  -i       case-insensitive (rg -i)
  -F       PATTERN is a literal string (rg -F)
  --code   only source and config files (Java, Kotlin, Scala, Groovy, Go, Python, JS/TS,
           Vue, SQL, properties, YAML, XML); skips vendor/ directories and *.min.js
  --tests  include test files (default: excluded, by the estate is_test path rules)
  --files  print one line per matching file (REPO<TAB>PATH) instead of the summary
  -- ...   passed to rg as is: -t java, -g '*.sql', -w, -P, ...

Summary: one tab-separated line per repo, most matching files first:
  FILES  REPO  OWNER  LAST_COMMIT
OWNER is from repo_owner and LAST_COMMIT from repos ('-' if the repo is not in DB or the
derived tables are not built). Repos in the DB's `vendored` table are skipped; if that
table is missing, a note goes to stderr and nothing is skipped. node_modules, target and
build directories are always skipped. The scan date is printed first.
Exit 0 if anything matched, 1 if nothing did, 2 on a usage or rg error.
EOF
}

tests=0
files=0
code=0
rgopts=''
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help) usage; exit 0 ;;
	-i | -F) rgopts="$rgopts $1"; shift ;;
	--code) code=1; shift ;;
	--tests) tests=1; shift ;;
	--files) files=1; shift ;;
	--) echo "estate-grep: rg options go after PATTERN and ORGs (see --help)" >&2; exit 2 ;;
	-*) echo "estate-grep: unknown option $1 (other rg options go after --)" >&2; exit 2 ;;
	*) break ;;
	esac
done
[ $# -ge 3 ] || { usage >&2; exit 2; }
db=$1
root=$2
pattern=$3
shift 3
[ -r "$db" ] || { echo "estate-grep: cannot read $db" >&2; exit 2; }
[ -d "$root" ] || { echo "estate-grep: no directory $root" >&2; exit 2; }

q() { sqlite3 -readonly -separator '	' "$db" "$1"; }
has_table() { [ -n "$(q "select 1 from sqlite_master where type='table' and name='$1'")" ]; }

# ORG arguments run up to `--`; everything after it goes to rg.
orgs=''
while [ $# -gt 0 ] && [ "$1" != "--" ]; do
	case "$1" in
	-*) echo "estate-grep: $1 after PATTERN: put -i/-F before DB, other rg options after --" >&2
		exit 2 ;;
	'' | *[!A-Za-z0-9._-]*) echo "estate-grep: not an org name: $1 (only one PATTERN;" \
		"-i/-F go before DB, other rg options after --)" >&2
		exit 2 ;;
	esac
	[ -d "$root/$1" ] || { echo "estate-grep: unknown org $1 (no $root/$1)" >&2; exit 2; }
	orgs="$orgs $1"
	shift
done
[ $# -gt 0 ] && shift
[ -n "$orgs" ] || orgs=$(q "select distinct substr(repo, 1, instr(repo, '/') - 1) from repos order by 1")

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if has_table vendored; then
	q "select repo from vendored" >"$tmp/vendored"
else
	echo "estate-grep: no vendored table in $db, vendored repos are included" \
		"(load it with: sqlite3 DB < estate/tools/cloud-fit/vendored.sql)" >&2
	: >"$tmp/vendored"
fi
if has_table repo_owner; then
	q "select r.repo, coalesce(o.owner, '-'), coalesce(r.last_commit, '-')
		from repos r left join repo_owner o using (repo)" >"$tmp/meta"
else
	q "select repo, '-', coalesce(last_commit, '-') from repos" >"$tmp/meta"
fi

# The estate is_test rules as rg globs (docs/facts.md): a test source set directly under
# src/, Java test class names, and the test directories and file names of Python/JS/TS.
set -- --glob '!**/node_modules/**' --glob '!**/target/**' --glob '!**/build/**' "$@"
if [ "$tests" -eq 0 ]; then
	set -- --glob-case-insensitive \
		--glob '!**/src/it/**' --glob '!**/src/test*/**' --glob '!**/src/e2e*/**' \
		--glob '!**/src/*test/**' --glob '!**/src/*tests/**' \
		--glob '!*Test.java' --glob '!*Tests.java' --glob '!*IT.java' \
		--glob '!**/test/**' --glob '!**/tests/**' --glob '!**/__tests__/**' \
		--glob '!**/__mocks__/**' --glob '!**/e2e/**' --glob '!**/cypress/**' \
		--glob '!*.test.*' --glob '!*.spec.*' --glob '!test_*.py' --glob '!*_test.py' \
			--glob '!conftest.py' "$@"
fi
if [ "$code" -eq 1 ]; then
	# Extensions the estate scan reads, plus SQL and XML; what it cannot use (lock files,
	# data dumps, minified bundles, vendored dependency trees) is what buries real hits.
	# rg: the last matching glob wins, so the exclusions follow the extension list.
	set -- --glob '*.{java,kt,kts,scala,groovy,gradle,go,py,js,jsx,mjs,cjs,ts,tsx,vue}' \
		--glob '*.{sql,properties,yml,yaml,xml}' \
		--glob '!**/vendor/**' --glob '!*.min.js' "$@"
fi
# shellcheck disable=SC2086 # $rgopts is -i and/or -F, validated above
set -- $rgopts "$@"

existing=''
for o in $orgs; do [ -d "$root/$o" ] && existing="$existing $o"; done
[ -n "$existing" ] || { echo "estate-grep: none of the DB's orgs are under $root" >&2; exit 2; }

# shellcheck disable=SC2086 # $existing is a list of validated org names
status=0
(cd "$root" && rg --files-with-matches --no-messages "$@" -e "$pattern" -- $existing) \
	>"$tmp/hits" || status=$?
[ "$status" -le 1 ] || { echo "estate-grep: rg failed (exit $status)" >&2; exit 2; }

# REPO<TAB>PATH for each hit outside a vendored repo. FILENAME, not NR == FNR: the first
# file may be empty.
awk -F/ -v OFS='\t' 'FILENAME == ARGV[1] { skip[$0] = 1; next }
	{ repo = $1 "/" $2; if (repo in skip) next
	  path = substr($0, length(repo) + 2); print repo, path }' \
	"$tmp/vendored" "$tmp/hits" | sort >"$tmp/rows"
[ -s "$tmp/rows" ] || exit 1

scan=$(q "select max(last_commit) from repos")
echo "# scan: latest commit $scan, db $(basename "$db")"
if [ "$files" -eq 1 ]; then
	cat "$tmp/rows"
	exit 0
fi
awk -F'\t' -v OFS='\t' 'FILENAME == ARGV[1] { meta[$1] = $2 OFS $3; next }
	{ n[$1]++ }
	END { for (r in n) print n[r], r, (r in meta ? meta[r] : "-" OFS "-") }' \
	"$tmp/meta" "$tmp/rows" | sort -t '	' -k1,1nr -k2,2
