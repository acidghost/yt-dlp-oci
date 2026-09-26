#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."
version=$(sed -n 's/^yt-dlp\[default\]==//p' requirements.in)

bash scripts/release.sh --check "$version-0"
bash scripts/release.sh --check "$version-1"
wrong_version="$((${version%%.*} + 1)).${version#*.}"
for invalid in "$version-01" "v$version-1" "$wrong_version-1"; do
    if bash scripts/release.sh --check "$invalid" >/dev/null 2>&1; then
        echo "Unexpectedly accepted release tag: $invalid" >&2
        exit 1
    fi
done

# Stub Git at the process boundary; no tags or remote refs are changed by this test.
git() {
    case $1 in
    branch) echo main ;;
    status) : ;;
    tag) printf '%s\n' "$LOCAL_TAGS" ;;
    ls-remote) printf '%s\n' "$REMOTE_REFS" ;;
    *)
        echo "Unexpected git command: $*" >&2
        return 1
        ;;
    esac
}
export -f git
export LOCAL_TAGS REMOTE_REFS

LOCAL_TAGS=''
REMOTE_REFS=''
[[ $(bash scripts/release.sh --next) == "$version-0" ]]

LOCAL_TAGS="$version-2"
REMOTE_REFS="abc123 refs/tags/$version-10"
[[ $(bash scripts/release.sh --next) == "$version-11" ]]

LOCAL_TAGS="$version-12"
REMOTE_REFS="abc123 refs/tags/$version-10"
[[ $(bash scripts/release.sh --next) == "$version-13" ]]

LOCAL_TAGS=''
REMOTE_REFS="abc123 refs/tags/$version-01"
[[ $(bash scripts/release.sh --next) == "$version-0" ]]
