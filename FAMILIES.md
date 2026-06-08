# Included families

Open-source fonts used by The Reliable Collaboration Company across its projects. Currently sourced from the official [IBM/plex](https://github.com/IBM/plex) GitHub releases (pre-built binaries — no font compilation required). All families are SIL OFL 1.1 licensed.

| Folder | Family name (as shown by the OS) | Upstream release |
|--------|----------------------------------|------------------|
| `fonts/ibm-plex-sans/`             | IBM Plex Sans                       | `@ibm/plex-sans@1.1.0` |
| `fonts/ibm-plex-sans-variable/`    | IBM Plex Sans Var                   | `@ibm/plex-sans-variable@0.2.0` |
| `fonts/ibm-plex-sans-condensed/`   | IBM Plex Sans Condensed             | `@ibm/plex-sans-condensed@2.0.0` |
| `fonts/ibm-plex-serif/`            | IBM Plex Serif                      | `@ibm/plex-serif@2.0.0` |
| `fonts/ibm-plex-serif-variable/`   | IBM Plex Serif Var                  | `@ibm/plex-serif-variable@2.0.0` |
| `fonts/ibm-plex-mono/`             | IBM Plex Mono                       | `@ibm/plex-mono@1.1.0` |
| `fonts/ibm-plex-sans-arabic/`      | IBM Plex Sans Arabic                | `@ibm/plex-sans-arabic@1.1.0` |
| `fonts/ibm-plex-sans-hebrew/`      | IBM Plex Sans Hebrew                | `@ibm/plex-sans-hebrew@1.1.0` |
| `fonts/ibm-plex-sans-devanagari/`  | IBM Plex Sans Devanagari            | `@ibm/plex-sans-devanagari@1.1.0` |
| `fonts/ibm-plex-sans-thai/`        | IBM Plex Sans Thai                  | `@ibm/plex-sans-thai@1.1.0` |
| `fonts/ibm-plex-sans-thai-looped/` | IBM Plex Sans Thai Looped           | `@ibm/plex-sans-thai-looped@1.1.0` |

## Per-family layout

Latin / European / Middle-Eastern / Indic / Thai families:

```
fonts/<family>/
  css/             # ready-to-use @font-face stylesheets with relative URLs
  scss/            # SCSS sources for build-time integration
  fonts/
    complete/      # one file per weight+style
      otf/         # OpenType — preferred for desktop installation
      ttf/         # TrueType — best Word/Office compatibility
      woff/        # web format (legacy)
      woff2/       # web format (modern, smaller — preferred for the web)
      eot/         # IE8 web format (can be deleted if not needed)
    split/         # per-unicode-range subsets used by ibm-plex-*-all.css
      woff/
      woff2/
  LICENSE.txt
```

Variable families (`ibm-plex-sans-variable`, `ibm-plex-serif-variable`):

```
fonts/<family>/
  fonts/
    complete/{ttf,woff,woff2}/   # only two files: Roman + Italic, one per axis range
    split/{woff,woff2}/
```

## Adding CJK (Chinese / Japanese / Korean) later

IBM also ships Plex Sans JP, KR, SC, and TC — together they cover Han/Kanji/Hanja, Hiragana, Katakana, and Hangul. They aren't included here because they total ~1.4 GB (a single CJK weight has tens of thousands of glyphs vs. a couple hundred for a Latin face) and aren't needed for English-language work.

If you need them later, download the release ZIPs from GitHub and drop them into `fonts/`:

```bash
# Run from the repo root.
for fam in plex-sans-jp@3.0.0 plex-sans-kr@1.1.0 plex-sans-sc@1.1.0 plex-sans-tc@1.1.1; do
  short=${fam%@*}
  ver=${fam#*@}
  curl -sLfo "$short.zip" "https://github.com/IBM/plex/releases/download/%40ibm%2F${short}%40${ver}/ibm-${short}.zip"
  unzip -q "$short.zip" -d fonts/
  rm "$short.zip"
done
```

The installer scripts in `install/` will pick them up automatically on the next run, and each family ships its own `css/ibm-plex-<family>-default.css` for self-hosting on the web.
