#!/usr/bin/env python3
"""subst: apply exact-text replacements across files, all or nothing.

Usage: python3 -I subst.py [--root DIR] [--dry-run] EDITS.json

EDITS.json is a list of edits, applied in order:
  [{"file": "docs/a.md", "old": "exact text", "new": "replacement"}, ...]
Relative paths resolve against --root (default: the current directory).

Each "old" must occur exactly once in its file at the point its edit is
applied (after the earlier edits to that file). If any edit fails, no file
is written. Prints one line per edit: "ok FILE:LINE" or "FAIL FILE: why".

Exit: 0 all applied (or would apply, with --dry-run), 1 an edit failed and
nothing was written, 2 bad arguments or input.
"""
import json
import os
import sys
import tempfile


def die(msg):
    print('subst: ' + msg, file=sys.stderr)
    sys.exit(2)


def load(path):
    try:
        with open(path, encoding='utf-8') as f:
            edits = json.load(f)
    except (OSError, ValueError) as e:
        die('cannot read %s: %s' % (path, e))
    if not isinstance(edits, list) or not edits:
        die('%s must hold a non-empty JSON list of edits' % path)
    for i, e in enumerate(edits):
        if not isinstance(e, dict) or set(e) != {'file', 'old', 'new'} or not all(isinstance(e[k], str) for k in e):
            die('edit %d must be {"file", "old", "new"}, all strings' % i)
        if not e['old']:
            die('edit %d: "old" is empty' % i)
    return edits


def main(argv):
    root, dry, args = '.', False, []
    it = iter(argv)
    for a in it:
        if a in ('-h', '--help'):
            print(__doc__.strip())
            return 0
        if a == '--dry-run':
            dry = True
        elif a == '--root':
            root = next(it, None) or die('--root needs a directory')
        elif a.startswith('-'):
            die('unknown option ' + a)
        else:
            args.append(a)
    if len(args) != 1:
        die('give exactly one EDITS.json (see --help)')
    edits = load(args[0])

    texts, failed = {}, False
    for e in edits:
        path = os.path.normpath(os.path.join(root, e['file']))
        if path not in texts:
            try:
                with open(path, encoding='utf-8') as f:
                    texts[path] = f.read()
            except OSError as err:
                print('FAIL %s: %s' % (e['file'], err.strerror))
                failed = True
                continue
        s = texts[path]
        n = s.count(e['old'])
        if n != 1:
            print('FAIL %s: old text found %d times: %r' % (e['file'], n, e['old'][:60]))
            failed = True
            continue
        at = s.index(e['old'])
        texts[path] = s[:at] + e['new'] + s[at + len(e['old']):]
        print('ok %s:%d' % (e['file'], s.count('\n', 0, at) + 1))

    if failed:
        print('nothing written')
        return 1
    if dry:
        return 0
    # Write each file to a temp file beside it, then rename them all.
    staged = []
    try:
        for path, s in texts.items():
            fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path) or '.', prefix='.subst-')
            with os.fdopen(fd, 'w', encoding='utf-8') as f:
                f.write(s)
            os.chmod(tmp, os.stat(path).st_mode & 0o7777)
            staged.append((tmp, path))
    except OSError as err:
        for tmp, _ in staged:
            os.unlink(tmp)
        die('could not stage writes: %s; nothing written' % err)
    for tmp, path in staged:
        os.replace(tmp, path)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
