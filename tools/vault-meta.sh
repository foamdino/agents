#!/bin/sh
# vault-meta.sh: list Obsidian notes with no frontmatter, and add it to them from a plan.
set -eu

usage() {
	cat <<'EOF'
usage: vault-meta.sh missing VAULT
       vault-meta.sh apply VAULT PLAN

missing  List .md notes under VAULT (paths relative to it) whose first line is not `---`.
         Skips VAULT/agent/ and anything VAULT/.ignore hides (the listing is `rg --files`).
apply    Prepend frontmatter to each note in PLAN, a JSON array of
           {"path": "MOR/Note.md", "type": "meeting", "projects": ["mor"],
            "components": ["order-manager"], "tags": ["kickoff"],
            "related": ["MOR/Changes", "agent/2026-11-09 Some note"]}
         path and related are relative to VAULT, related without .md. Tags written are
         project/<p> and component/<c>, then the plan's own tags. Every entry is checked
         before any note is written: plan shape (vault-meta.jq), note exists, has no
         frontmatter yet, related notes exist. Each note keeps its inode and its body
         byte for byte (verified). Prints one `ok PATH` per note written.
Exit 1 on any problem; nothing is written if a check fails.
EOF
}

case "${1:-}" in -h | --help) usage; exit 0 ;; esac
jqf="$(dirname "$0")/vault-meta.jq"

has_frontmatter() {
	[ "$(head -n 1 "$1" | tr -d '\r')" = "---" ]
}

case "${1:-}" in
missing)
	[ $# -eq 2 ] || { usage >&2; exit 2; }
	cd "$2"
	rg --files | rg '\.md$' | rg -v '^agent/' | sort | while IFS= read -r f; do
		has_frontmatter "$f" || printf '%s\n' "$f"
	done
	;;
apply)
	[ $# -eq 3 ] || { usage >&2; exit 2; }
	vault=$2
	plan=$3
	[ -d "$vault" ] || { echo "vault-meta: no such vault: $vault" >&2; exit 2; }
	[ -r "$plan" ] || { echo "vault-meta: cannot read $plan" >&2; exit 2; }
	problems=$(jq -r --arg mode check -f "$jqf" "$plan") || exit 2
	if [ -z "$problems" ]; then
		problems=$(jq -r '.[] | "\(.path)\t\(.related[])", "\(.path)\t"' "$plan" |
			while IFS="$(printf '\t')" read -r p r; do
				if [ -z "$r" ]; then
					[ -f "$vault/$p" ] || echo "$p: no such note"
					[ ! -f "$vault/$p" ] || ! has_frontmatter "$vault/$p" ||
						echo "$p: already has frontmatter"
				else
					[ -f "$vault/$r.md" ] || echo "$p: related note not found: $r"
				fi
			done)
	fi
	if [ -n "$problems" ]; then
		printf '%s\n' "$problems" >&2
		exit 1
	fi
	tmp=$(mktemp -d)
	trap 'rm -rf "$tmp"' EXIT
	n=$(jq length "$plan")
	i=0
	while [ "$i" -lt "$n" ]; do
		p=$(jq -r --argjson i "$i" '.[$i].path' "$plan")
		note="$vault/$p"
		jq -r --arg mode render --argjson i "$i" -f "$jqf" "$plan" >"$tmp/fm"
		cp "$note" "$tmp/body"
		cat "$tmp/fm" "$tmp/body" >"$tmp/new"
		skip=$(($(wc -c <"$tmp/fm") + 1))
		tail -c "+$skip" "$tmp/new" | cmp -s - "$tmp/body" ||
			{ echo "vault-meta: $p: body check failed, not written" >&2; exit 1; }
		cat "$tmp/new" >"$note"
		cmp -s "$tmp/new" "$note" || { echo "vault-meta: $p: write did not verify" >&2; exit 1; }
		echo "ok $p"
		i=$((i + 1))
	done
	;;
*)
	usage >&2
	exit 2
	;;
esac
