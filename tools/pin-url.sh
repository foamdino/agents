#!/bin/sh
# pin-url.sh — print the SHA-256 of what each URL downloads, for pinning in a bootstrap.sh.
set -e

usage() {
    cat <<'EOF'
usage: pin-url.sh URL...

Downloads each URL to a temporary directory (removed on exit) and prints
    <sha256>  <url>
For a .tar.gz / .tgz it also prints the tarball's top-level folders, so you can
check that `tar --strip-components=1` is safe (exactly one folder).

Exit 1 if any download fails; the other URLs are still printed.
Needs: curl, tar, and sha256sum or shasum.
EOF
}

case "$1" in
    -h|--help) usage; exit 0 ;;
    '') usage >&2; exit 1 ;;
esac

sha256() {
    if command -v sha256sum >/dev/null 2>&1; then
        sha256sum "$1" | cut -d' ' -f1
    else
        shasum -a 256 "$1" | cut -d' ' -f1
    fi
}

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT
rc=0
for url in "$@"; do
    if ! curl -sfL "$url" -o "$dir/dl"; then
        echo "FAILED  $url" >&2
        rc=1
        continue
    fi
    echo "$(sha256 "$dir/dl")  $url"
    case "$url" in
        *.tar.gz|*.tgz)
            echo "    top-level: $(tar -tzf "$dir/dl" | cut -d/ -f1 | sort -u | tr '\n' ' ')"
            ;;
    esac
    rm -f "$dir/dl"
done
exit $rc
