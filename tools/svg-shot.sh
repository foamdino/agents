#!/bin/sh
# svg-shot.sh: render one standalone SVG file to a PNG with headless Chrome.
usage() {
	cat <<'EOF'
usage: svg-shot.sh [--chrome PATH] <file.svg> [out.png]

Renders the SVG on a white page at the size its viewBox gives (or its
width/height attributes), so a diagram can be looked at without the page that
embeds it. The SVG's own <style> applies; CSS from an embedding page does not.
The SVG file is never changed.

out.png defaults to $TMPDIR/svg-shot/<name>.png. The path written is printed.

options:
  --chrome PATH   Chrome binary (default: $CHROME, then the macOS app, then
                  google-chrome / chromium on PATH)

exit: 0 written, 1 Chrome produced no image, 2 usage or setup problem.

example:
  svg-shot.sh ~/side/mor/docs/diagrams/payments.svg
EOF
}

chrome=${CHROME:-}
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help) usage; exit 0 ;;
	--chrome) [ $# -ge 2 ] || { usage >&2; exit 2; }; chrome=$2; shift 2 ;;
	-*) echo "svg-shot.sh: unknown option: $1" >&2; exit 2 ;;
	*) break ;;
	esac
done
[ $# -ge 1 ] && [ $# -le 2 ] || { usage >&2; exit 2; }
svg=$1
[ -f "$svg" ] || { echo "svg-shot.sh: no such file: $svg" >&2; exit 2; }
name=$(basename "$svg" .svg)
tmpdir=${TMPDIR:-/tmp}
out=${2:-${tmpdir%/}/svg-shot/$name.png}
mkdir -p "$(dirname "$out")" || exit 2

if [ -z "$chrome" ]; then
	for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
		"$(command -v google-chrome 2>/dev/null)" "$(command -v chromium 2>/dev/null)"; do
		[ -n "$c" ] && [ -x "$c" ] && { chrome=$c; break; }
	done
fi
[ -n "$chrome" ] && [ -x "$chrome" ] || { echo "svg-shot.sh: Chrome not found; pass --chrome or set CHROME" >&2; exit 2; }

# Size from the first <svg ...> tag: viewBox="minx miny w h", else width/height.
tag=$(tr '\n' ' ' <"$svg" | sed -n 's/.*\(<svg[^>]*>\).*/\1/p' | head -n 1)
vb=$(printf '%s' "$tag" | sed -n 's/.*viewBox="\([^"]*\)".*/\1/p' | tr ',' ' ')
if [ -n "$vb" ]; then
	set -- $vb
	w=$3 h=$4
else
	w=$(printf '%s' "$tag" | sed -n 's/.* width="\([0-9.]*\)[a-z]*".*/\1/p')
	h=$(printf '%s' "$tag" | sed -n 's/.* height="\([0-9.]*\)[a-z]*".*/\1/p')
fi
w=${w%%.*} h=${h%%.*}
case "$w$h" in '' | *[!0-9]*) echo "svg-shot.sh: no viewBox or width/height on <svg>" >&2; exit 2 ;; esac

tmp=$(mktemp -d "${TMPDIR:-/tmp}/svg-shot.XXXXXX") || exit 2
trap 'rm -rf "$tmp"' EXIT
{
	printf '<!doctype html><meta charset="utf-8"><style>html,body{margin:0;background:#fff}svg{display:block;width:%spx;height:%spx}</style>' "$w" "$h"
	cat "$svg"
} >"$tmp/page.html"

rm -f "$out"
"$chrome" --headless=new --disable-gpu --hide-scrollbars --no-first-run --no-default-browser-check \
	--user-data-dir="$tmp/profile" --window-size="$w,$h" --screenshot="$out" \
	"file://$tmp/page.html" >"$tmp/chrome.log" 2>&1
[ -s "$out" ] || { echo "svg-shot.sh: Chrome wrote no image; log:" >&2; cat "$tmp/chrome.log" >&2; exit 1; }
echo "$out"
