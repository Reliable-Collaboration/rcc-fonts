#!/usr/bin/env bash
# Install every IBM Plex .otf and .ttf in this repo for the current macOS user.
#
# Usage:
#   ./install/macos-install.sh
#
# Behavior:
#   - Copies files to ~/Library/Fonts (user-only — no admin required).
#   - Picked up immediately by Font Book and any app launched after install.
#
# To install for ALL users, re-run with TARGET=/Library/Fonts (requires sudo).

set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
fonts_root="$repo_root/fonts"
target="${TARGET:-$HOME/Library/Fonts}"

if [[ ! -d $fonts_root ]]; then
    echo "Could not find $fonts_root" >&2
    exit 1
fi

mkdir -p "$target"
copied=0

for family_dir in "$fonts_root"/*/; do
    for fmt in otf ttf; do
        src="$family_dir/fonts/complete/$fmt"
        [[ -d $src ]] || continue
        while IFS= read -r -d '' f; do
            cp -f "$f" "$target/"
            copied=$((copied + 1))
        done < <(find "$src" -maxdepth 1 -type f \( -name '*.otf' -o -name '*.ttf' \) -print0)
    done
done

echo "Copied $copied font files into $target"
echo "Done. Verify in Font Book — search for \"IBM Plex\"."
