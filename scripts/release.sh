#!/usr/bin/env bash
set -euo pipefail

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

usage() {
    cat >&2 <<EOF
Usage:
  $0                 Create and push the next release tag.
  $0 --next          Print the next tag without creating or pushing it.
  $0 --check <tag>   Validate a tag against the locked yt-dlp version (used by CI).
EOF
    exit 2
}

# The release tag must describe the version actually installed in the image.
input_version=$(sed -nE 's/^yt-dlp\[default\]==([0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2})$/\1/p' requirements.in)
locked_version=$(sed -nE 's/^yt-dlp==([0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}) .*/\1/p' requirements.txt)
if [[ -z $input_version || $input_version != "$locked_version" ]]; then
    echo "yt-dlp versions in requirements.in and requirements.txt must match" >&2
    exit 1
fi

if [[ $# -eq 2 && $1 == --check ]]; then
    tag=$2
    if [[ ! $tag =~ ^[0-9]{4}\.[0-9]{1,2}\.[0-9]{1,2}-(0|[1-9][0-9]*)$ || $tag != "$locked_version-"* ]]; then
        echo "Invalid release tag: $tag (expected $locked_version-<patch number>)" >&2
        exit 1
    fi
    echo "Validated $tag"
    exit 0
fi

if [[ $# -gt 1 || ($# -eq 1 && $1 != --next) ]]; then
    usage
fi
if [[ $(git branch --show-current) != main ]]; then
    echo "Releases must be made from main" >&2
    exit 1
fi
if [[ -n $(git status --porcelain) ]]; then
    echo "Commit all changes before releasing" >&2
    exit 1
fi

# Query origin so a fresh clone doesn't reuse a patch already published there.
local_tags=$(git tag --list "$locked_version-*")
remote_tags=$(git ls-remote --refs --tags origin "refs/tags/$locked_version-*" | sed -n 's@.*refs/tags/@@p')
latest=-1
while IFS= read -r tag; do
    [[ $tag == "$locked_version-"* ]] || continue
    patch=${tag#"$locked_version-"}
    if [[ $patch =~ ^(0|[1-9][0-9]*)$ ]] && ((patch > latest)); then
        latest=$patch
    fi
done < <(printf '%s\n%s\n' "$local_tags" "$remote_tags")

patch=$((latest + 1))
tag="$locked_version-$patch"
if [[ ${1:-} == --next ]]; then
    echo "$tag"
    exit 0
fi

git tag -a "$tag" -m "yt-dlp $locked_version image patch $patch"
git push origin "refs/tags/$tag"
echo "Published tag $tag (image build runs in GitHub Actions)"
