#!/bin/sh
# page-probe.sh: run a script inside a local HTML page in headless Chrome and
# print what it logs, plus any JS errors the page or the script raised.
usage() {
	cat <<'EOF'
usage: page-probe.sh [options] <page.html> <probe.js>

Loads a local page (file://) in headless Chrome with a fresh profile, waits,
then runs probe.js inside it and prints its output. The page is copied to a
temp dir with its Content-Security-Policy <meta> removed and a <base> tag
pointing at the page's own directory, so its relative scripts, styles and
images still load. The original file is never changed.

probe.js is the body of an async function. It can use:
  log(...values)   print a line (objects are JSON-encoded)
  sleep(ms)        await a pause (e.g. after a click that renders later)
  $(selector[, root])   (root || document).querySelector
  $$(selector[, root])  Array of (root || document).querySelectorAll
Anything it throws is reported as an error.

Errors captured: window error events (script and resource loading failures),
unhandled promise rejections, console.error calls, and the probe's own throw.

options:
  --hash FRAG     URL fragment to open with, e.g. --hash 'tab=sim'
  --wait MS       delay after the load event before the probe runs (default 300)
  --budget MS     Chrome virtual-time budget for the whole run (default 10000);
                  raise it for probes that run long or sleep a lot
  --keep          keep the temp dir (prints its path) for debugging
  --chrome PATH   Chrome binary (default: $CHROME, then the macOS app, then
                  google-chrome / chromium on PATH)

output: probe lines, then one "ERR <message>" line per error.
exit:   0 no errors, 1 errors reported, 2 usage or setup problem,
        3 the probe never finished (raise --budget or --wait).

example:
  printf '%s\n' "\$('#tab-flows').click();" "log(\$\$('.flow-list button').length);" > /tmp/p.js
  page-probe.sh --hash 'tab=overview' ~/side/mor/mor.html /tmp/p.js
EOF
}

hash= wait=300 budget=10000 keep= chrome=${CHROME:-}
while [ $# -gt 0 ]; do
	case "$1" in
	-h | --help) usage; exit 0 ;;
	--hash) hash=$2; shift 2 ;;
	--wait) wait=$2; shift 2 ;;
	--budget) budget=$2; shift 2 ;;
	--keep) keep=1; shift ;;
	--chrome) chrome=$2; shift 2 ;;
	--) shift; break ;;
	-*) echo "page-probe.sh: unknown option $1" >&2; exit 2 ;;
	*) break ;;
	esac
done
[ $# -eq 2 ] || { usage >&2; exit 2; }
page=$1 probe=$2
[ -f "$page" ] || { echo "page-probe.sh: no such page: $page" >&2; exit 2; }
[ -f "$probe" ] || { echo "page-probe.sh: no such probe: $probe" >&2; exit 2; }
case "$wait$budget" in *[!0-9]*) echo "page-probe.sh: --wait and --budget take milliseconds" >&2; exit 2 ;; esac

if [ -z "$chrome" ]; then
	for c in "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
		"$(command -v google-chrome 2>/dev/null)" "$(command -v chromium 2>/dev/null)"; do
		[ -n "$c" ] && [ -x "$c" ] && { chrome=$c; break; }
	done
fi
[ -n "$chrome" ] && [ -x "$chrome" ] || { echo "page-probe.sh: Chrome not found; pass --chrome or set CHROME" >&2; exit 2; }

tmp=$(mktemp -d "${TMPDIR:-/tmp}/page-probe.XXXXXX") || exit 2
if [ -n "$keep" ]; then echo "page-probe.sh: temp dir $tmp" >&2; else trap 'rm -rf "$tmp"' EXIT; fi

# Build the harness page. Python (stdlib) does the HTML surgery because the
# page and probe text can contain anything; sh quoting can't carry it safely.
python3 -I - "$page" "$probe" "$tmp/harness.html" "$wait" <<'PY' || exit 2
import json, os, re, sys
page, probe, out, wait = sys.argv[1], sys.argv[2], sys.argv[3], int(sys.argv[4])
html = open(page, encoding='utf-8').read()
body = open(probe, encoding='utf-8').read()
base = 'file://' + os.path.dirname(os.path.abspath(page)) + '/'

html = re.sub(r'<meta[^>]+http-equiv=["\']?Content-Security-Policy["\']?[^>]*>', '', html, flags=re.I)
head = ('<base href="%s"><script>window.__probeErrs = [];'
        'addEventListener("error", function (e) { var t = e.target; __probeErrs.push(t && t !== window && (t.src || t.href) ? "failed to load " + (t.src || t.href) : (e.message || "error") + (e.filename ? " @" + e.filename + ":" + e.lineno : "")); }, true);'
        'addEventListener("unhandledrejection", function (e) { __probeErrs.push("unhandled rejection: " + (e.reason && e.reason.stack || e.reason)); });'
        '(function (ce) { console.error = function () { __probeErrs.push("console.error: " + Array.prototype.map.call(arguments, String).join(" ")); return ce.apply(console, arguments); }; })(console.error);'
        '</script>') % base
m = re.search(r'<head[^>]*>', html, flags=re.I)
html = html[:m.end()] + head + html[m.end():] if m else head + html

# The probe text is embedded as a JSON string and run with new Function, so
# nothing in it (quotes, </script>, newlines) can break the harness.
runner = '''<script>
addEventListener("load", function () {
  setTimeout(async function () {
    var out = [], done = function () {
      var pre = document.createElement("pre");
      pre.id = "__probe_result";
      pre.textContent = JSON.stringify({ out: out, errs: window.__probeErrs });
      document.body.appendChild(pre);
    };
    var log = function () { out.push(Array.prototype.map.call(arguments, function (v) { return typeof v === "string" ? v : JSON.stringify(v); }).join(" ")); };
    var sleep = function (ms) { return new Promise(function (r) { setTimeout(r, ms); }); };
    var $ = function (s, root) { return (root || document).querySelector(s); };
    var $$ = function (s, root) { return Array.from((root || document).querySelectorAll(s)); };
    try {
      var AsyncFunction = Object.getPrototypeOf(async function () {}).constructor;
      await new AsyncFunction("log", "sleep", "$", "$$", %s)(log, sleep, $, $$);
    } catch (e) { window.__probeErrs.push("probe: " + (e && e.stack || e)); }
    done();
  }, %d);
});
</script>''' % (json.dumps(body).replace('</', '<\\/'), wait)
i = html.lower().rfind('</body>')
html = html[:i] + runner + html[i:] if i >= 0 else html + runner
open(out, 'w', encoding='utf-8').write(html)
PY

url="file://$tmp/harness.html"
[ -n "$hash" ] && url="$url#$hash"
"$chrome" --headless=new --disable-gpu --no-first-run --no-default-browser-check \
	--user-data-dir="$tmp/profile" --allow-file-access-from-files \
	--virtual-time-budget="$budget" --dump-dom "$url" >"$tmp/dom.html" 2>"$tmp/chrome.log"

python3 -I - "$tmp/dom.html" "file://$tmp/harness.html" "$page" <<'PY'
import html, json, os, re, sys
dom = open(sys.argv[1], encoding='utf-8', errors='replace').read()
# Point errors in the page's own inline scripts at the page, not the copy.
harness, page = sys.argv[2], 'file://' + os.path.abspath(sys.argv[3])
m = re.search(r'<pre id="__probe_result">(.*?)</pre>', dom, re.S)
if not m:
    print('page-probe.sh: the probe did not finish; raise --budget or --wait', file=sys.stderr)
    sys.exit(3)
r = json.loads(html.unescape(m.group(1)))
for line in r['out']:
    print(line)
for e in r['errs']:
    print('ERR ' + e.replace(harness, page))
sys.exit(1 if r['errs'] else 0)
PY
