#!/usr/bin/env bash
# Install every IBM Plex .otf and .ttf in this repo for the current Linux user.
#
# Usage:
#   ./install/linux-install.sh
#
# Behavior:
#   - Copies files to ~/.local/share/fonts/IBM-Plex/<family>/
#   - Rebuilds fontconfig's cache (fc-cache -f).
#
# To install system-wide instead, re-run with TARGET=/usr/share/fonts/IBM-Plex (requires sudo).

set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
fonts_root="$repo_root/fonts"
target="${TARGET:-$HOME/.local/share/fonts/IBM-Plex}"

if [[ ! -d $fonts_root ]]; then
    echo "Could not find $fonts_root" >&2
    exit 1
fi

mkdir -p "$target"
copied=0

for family_dir in "$fonts_root"/*/; do
    family=$(basename "$family_dir")
    dest="$target/$family"
    mkdir -p "$dest"
    for fmt in otf ttf; do
        src="$family_dir/fonts/complete/$fmt"
        [[ -d $src ]] || continue
        while IFS= read -r -d '' f; do
            cp -f "$f" "$dest/"
            copied=$((copied + 1))
        done < <(find "$src" -maxdepth 1 -type f \( -name '*.otf' -o -name '*.ttf' \) -print0)
    done
done

echo "Copied $copied font files into $target"
if command -v fc-cache >/dev/null; then
    fc-cache -f "$target"
    echo "Refreshed fontconfig cache."
else
    echo "fc-cache not found — install 'fontconfig' (e.g. apt install fontconfig) and re-run." >&2
fi

echo "Done. Verify with:  fc-list | grep -i 'IBM Plex'"
