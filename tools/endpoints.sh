#!/bin/sh
# endpoints.sh: list one repo's inbound REST endpoints from an estate SQLite DB.
set -eu

usage() {
	cat <<'EOF'
usage: endpoints.sh DB REPO
  DB    estate database built by `estate -d` or db/import.sh (e.g. estate/db/current.db)
  REPO  <org>/<repo>, or a bare repo name if only one org has it

Prints the scan date, the repo and its default server.servlet.context-path (if set), then
one tab-separated line per production endpoint, sorted by path:
  VERB  PATH  Class.handler  file:line  PROFILES
PATH includes the class-level @RequestMapping prefix but not the context path. VERB is
ANY for a @RequestMapping with no method. PROFILES is '*' when the endpoint is declared
in every profile, else the profile list. Java/Spring annotations only, as the scan
extracts them: no request bodies, no @Operation text; read the file:line for those.
A path built from a constant (CONST + "/{id}") comes through as the class prefix only,
so duplicate VERB+PATH lines with different handlers mean: read the source.
Exit 1 if REPO is unknown or ambiguous.
EOF
}

case "${1:-}" in -h | --help) usage; exit 0 ;; esac
[ $# -eq 2 ] || { usage >&2; exit 2; }
db=$1
name=$2
[ -r "$db" ] || { echo "endpoints: cannot read $db" >&2; exit 2; }
case "$name" in
'' | *[!A-Za-z0-9._/-]*) echo "endpoints: bad repo name: $name" >&2; exit 2 ;;
esac

matches=$(sqlite3 -readonly "$db" "select repo from repos where repo = '$name'
	or substr(repo, instr(repo, '/') + 1) = '$name' order by repo;")
case "$matches" in
'') echo "endpoints: $name not in $db" >&2; exit 1 ;;
*'
'*) printf 'endpoints: %s is ambiguous:\n%s\n' "$name" "$matches" >&2; exit 1 ;;
esac

sqlite3 -readonly -cmd ".parameter set :r '$matches'" "$db" <"$(dirname "$0")/endpoints.sql"
