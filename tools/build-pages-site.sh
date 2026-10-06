#!/usr/bin/env bash
# Assemble a static site from a checkout of this repo: web/ plus only the
# font files that web/*.html and web/*.css reference. The repo layout is
# mirrored so the pages' relative ../fonts/... URLs resolve unchanged.
#
# Usage:
#   tools/build-pages-site.sh <repo-checkout-dir> <output-dir>
#
# Run tools/generate-font-samples.ps1 in the checkout first. Used by
# .github/workflows/pages.yml.

set -euo pipefail

src="$1"
out="$2"

mkdir -p "$out"
cp -r "$src/web" "$out/web"

# Copy every ../fonts/... file referenced by the pages and stylesheets.
mapfile -t referenced < <(grep -ohP 'url\("\.\./\Kfonts/[^"]+' "$src"/web/*.html "$src"/web/*.css | sort -u)
missing=0
for f in "${referenced[@]}"; do
  f="$(printf '%b' "${f//%/\\x}")"  # URL-decode (e.g. %20)
  if [ -f "$src/$f" ]; then
    install -D -m 644 "$src/$f" "$out/$f"
  else
    echo "::error::Referenced font file not found: $f"
    missing=1
  fi
done
[ "$missing" -eq 0 ]

cat > "$out/index.html" <<'HTML'
<!DOCTYPE html>
<meta charset="utf-8">
<title>RCC Fonts</title>
<meta http-equiv="refresh" content="0; url=web/font-samples.html">
<a href="web/font-samples.html">RCC Fonts &mdash; Sample Gallery</a>
HTML

echo "$out: copied ${#referenced[@]} font files; size $(du -sh "$out" | cut -f1)"
