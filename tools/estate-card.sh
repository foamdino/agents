#!/bin/sh
# estate-card.sh: print one repo's place in the estate from an estate SQLite DB.
set -eu

usage() {
	cat <<'EOF'
usage: estate-card.sh DB REPO
  DB    estate database built by `estate -d` or db/import.sh (e.g. estate/db/out-all.db)
  REPO  <org>/<repo>, or a bare repo name if only one org has it

Prints the scan date, class, owner, deploy profiles and archive verdict, then the repos
that depend on REPO and the repos REPO depends on, one line per repo with a count per
kind (rest, msg, call = runtime traffic; lib = Maven dependency). Repo-level only:
no hosts, paths or findings. Exit 1 if REPO is unknown or ambiguous.
EOF
}

case "${1:-}" in -h | --help) usage; exit 0 ;; esac
[ $# -eq 2 ] || { usage >&2; exit 2; }
db=$1
name=$2
[ -r "$db" ] || { echo "estate-card: cannot read $db" >&2; exit 2; }
case "$name" in
'' | *[!A-Za-z0-9._/-]*) echo "estate-card: bad repo name: $name" >&2; exit 2 ;;
esac

matches=$(sqlite3 -readonly "$db" "select repo from repos where repo = '$name'
	or substr(repo, instr(repo, '/') + 1) = '$name' order by repo;")
case "$matches" in
'') echo "estate-card: $name not in $db" >&2; exit 1 ;;
*'
'*) printf 'estate-card: %s is ambiguous:\n%s\n' "$name" "$matches" >&2; exit 1 ;;
esac

sqlite3 -readonly -cmd ".parameter set :r '$matches'" "$db" <"$(dirname "$0")/estate-card.sql"
