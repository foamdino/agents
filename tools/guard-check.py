#!/usr/bin/env python3
"""guard-check: check that each guard is covered by a test, by reverting it.

Usage: python3 -I guard-check.py [--root DIR] [--fail-pattern RE] CASES.json -- CMD [ARG...]

CASES.json is a list of mutations, each tried on its own:
  [{"name": "no time limit", "file": "js/core/orders.js", "old": "exact text", "new": "replacement"}, ...]
Relative paths and CMD resolve against --root (default: the current directory).

First CMD runs on the unmodified tree and must exit 0, or nothing is mutated.
Then for each case: replace "old" (which must occur exactly once) with "new",
run CMD, and restore the file byte for byte (also on error or Ctrl-C).
Each case prints one line:
  caught    NAME: the output lines matching --fail-pattern (default ^FAIL)
  MISSED    NAME: CMD still exited 0, so no test covers this guard
  CRASH     NAME: CMD failed with no matching line (a broken mutation or
            harness, not a test catching the guard): the last output lines

Exit: 0 every case caught, 1 any missed or crashed, 2 bad input or the
baseline run failed.
"""
import json
import os
import re
import subprocess
import sys


def die(msg):
    print('guard-check: ' + msg, file=sys.stderr)
    sys.exit(2)


def parse(argv):
    root, pattern = '.', r'^FAIL'
    if argv[:1] in (['-h'], ['--help']):
        print(__doc__)
        sys.exit(0)
    if '--' not in argv:
        die('give the test command after --  (see --help)')
    i = argv.index('--')
    opts, cmd = argv[:i], argv[i + 1:]
    if not cmd:
        die('empty test command after --')
    cases = None
    while opts:
        a = opts.pop(0)
        if a in ('-h', '--help'):
            print(__doc__)
            sys.exit(0)
        elif a == '--root' and opts:
            root = opts.pop(0)
        elif a == '--fail-pattern' and opts:
            pattern = opts.pop(0)
        elif not a.startswith('-') and cases is None:
            cases = a
        else:
            die('unexpected argument: ' + a)
    if cases is None:
        die('give a CASES.json file')
    try:
        fail = re.compile(pattern, re.M)
    except re.error as e:
        die('bad --fail-pattern: %s' % e)
    return os.path.abspath(root), fail, cases, cmd


def load(path, root):
    try:
        with open(path, encoding='utf-8') as f:
            cases = json.load(f)
    except (OSError, ValueError) as e:
        die('cannot read %s: %s' % (path, e))
    if not isinstance(cases, list) or not cases:
        die('%s must hold a non-empty JSON list of cases' % path)
    for i, c in enumerate(cases):
        if not isinstance(c, dict) or set(c) != {'name', 'file', 'old', 'new'} or not all(isinstance(c[k], str) for k in c):
            die('case %d must be {"name", "file", "old", "new"}, all strings' % i)
        if not c['old'] or c['old'] == c['new']:
            die('case %d (%s): "old" is empty or equal to "new"' % (i, c['name']))
        p = os.path.join(root, c['file'])
        try:
            with open(p, encoding='utf-8') as f:
                n = f.read().count(c['old'])
        except OSError as e:
            die('case %d (%s): %s' % (i, c['name'], e))
        if n != 1:
            die('case %d (%s): "old" occurs %d times in %s, need exactly 1' % (i, c['name'], n, c['file']))
    return cases


def run(cmd, root):
    r = subprocess.run(cmd, cwd=root, capture_output=True, text=True)
    return r.returncode, r.stdout + r.stderr


def tail(out, n=3):
    lines = [l for l in out.splitlines() if l.strip()]
    return ' | '.join(l.strip()[:100] for l in lines[-n:]) or '(no output)'


def main():
    root, fail, path, cmd = parse(sys.argv[1:])
    cases = load(path, root)
    code, out = run(cmd, root)
    if code != 0:
        print('guard-check: the unmodified tree fails (exit %d), so no case can be judged: %s' % (code, tail(out)), file=sys.stderr)
        sys.exit(2)
    bad = 0
    for c in cases:
        p = os.path.join(root, c['file'])
        with open(p, 'rb') as f:
            original = f.read()
        text = original.decode('utf-8')
        try:
            with open(p, 'w', encoding='utf-8', newline='') as f:
                f.write(text.replace(c['old'], c['new'], 1))
            code, out = run(cmd, root)
        finally:
            with open(p, 'wb') as f:
                f.write(original)
            with open(p, 'rb') as f:
                if f.read() != original:
                    die('could not restore ' + c['file'] + ': fix it by hand before anything else')
        hits = [m.group(0) for m in re.finditer(r'^.*$', out, re.M) if fail.search(m.group(0))]
        if code == 0:
            bad += 1
            print('MISSED    %s: the tests still pass' % c['name'])
        elif hits:
            print('caught    %s: %s' % (c['name'], '; '.join(h.strip()[:100] for h in hits)))
        else:
            bad += 1
            print('CRASH     %s: exit %d with no line matching the fail pattern: %s' % (c['name'], code, tail(out)))
    sys.exit(1 if bad else 0)


if __name__ == '__main__':
    main()
