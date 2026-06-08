# rcc-fonts — The Reliable Collaboration Company font package

A portable, self-contained collection of open-source fonts that [The Reliable Collaboration Company](https://rcc.team) uses across its projects. Currently includes the [IBM Plex](https://github.com/IBM/plex) family. Compiled into a single repo with cross-platform install scripts so the full set can be installed together as a package on any machine — no CDN, no font compilation, no hunting for individual downloads.

Contents:

- [What's in this repo](#whats-in-this-repo)
- [Install on Windows](#install-on-windows)
- [Install on macOS](#install-on-macos)
- [Install on Linux](#install-on-linux)
- [Use in Microsoft Office (Word, PowerPoint, Excel, Outlook)](#use-in-microsoft-office-word-powerpoint-excel-outlook)
- [Use in creative apps that DO read OS fonts](#use-in-creative-apps-that-do-read-os-fonts)
- [Use in creative apps that DON'T read OS fonts](#use-in-creative-apps-that-dont-read-os-fonts)
- [Embed on a website without a CDN](#embed-on-a-website-without-a-cdn)
- [Verify the install worked](#verify-the-install-worked)
- [Uninstall](#uninstall)
- [License](#license)

---

## What's in this repo

```
rcc-fonts/
├── fonts/                        # one folder per IBM Plex family (11 total)
│   ├── ibm-plex-sans/            #   Latin/Greek/Cyrillic, the workhorse
│   ├── ibm-plex-sans-condensed/
│   ├── ibm-plex-sans-variable/   #   single-file variable axis (100..700)
│   ├── ibm-plex-serif/
│   ├── ibm-plex-serif-variable/
│   ├── ibm-plex-mono/
│   ├── ibm-plex-sans-arabic/
│   ├── ibm-plex-sans-hebrew/
│   ├── ibm-plex-sans-devanagari/
│   ├── ibm-plex-sans-thai/
│   └── ibm-plex-sans-thai-looped/
├── install/
│   ├── windows-install-all-users.ps1
│   ├── windows-install-current-user.ps1
│   ├── linux-install.sh
│   └── macos-install.sh
├── web/
│   ├── ibm-plex.css              # one stylesheet for Sans/Serif/Mono/Condensed + Vars
│   └── example.html              # working demo page
├── FAMILIES.md                   # full list of included families with version pinning
├── LICENSE                       # SIL Open Font License 1.1
├── working-journal.md            # log of intentions, decisions, considerations
└── README.md                     # you are here
```

Each family folder mirrors the official IBM release layout — `fonts/complete/{otf,ttf,woff,woff2}` plus `css/` and `scss/` with pre-built stylesheets pointing at relative paths. See [`FAMILIES.md`](FAMILIES.md) for full details and version pins.

Repository size: about **75 MB** on disk. CJK (Chinese/Japanese/Korean) families are not included — they would add ~1.4 GB and aren't useful for English-language work. If you need them later, see [Adding CJK later](FAMILIES.md#adding-cjk-chinese--japanese--korean-later) for a one-shot script that drops them in.

> **Is the repo folder required after install?** No. The install scripts on every OS *copy* the font files into OS-managed font directories (`C:\Windows\Fonts`, `~/Library/Fonts`, `~/.local/share/fonts/`). Once the install completes, you can delete or move this folder and Word/Adobe/etc. will keep working. The folder only needs to stick around if you're (a) self-hosting the fonts on a website that points at it, or (b) using the LaTeX `fontspec` recipe below with a relative `Path =`.

---

## Install on Windows

> Tested on Windows 10 and Windows 11. Works the same in PowerShell 5.1 (built-in) and PowerShell 7+.

You have three options, in order of convenience:

### Option A — automated, all users (recommended)

Installs every weight of every included family.

1. Open **PowerShell as Administrator** (right-click the Start menu → "Terminal (Admin)" on Win11; "Windows PowerShell (Admin)" on Win10).
2. `cd` into wherever you cloned this repo, e.g. `cd C:\Users\matt\code\ibm-plex-fonts`.
3. Run:
   ```powershell
   powershell -ExecutionPolicy Bypass -File install\windows-install-all-users.ps1
   ```
4. The script copies fonts to `C:\Windows\Fonts` and registers each one in the registry. You'll see a count like `Installed 244 fonts to C:\Windows\Fonts.`

### Option B — automated, current user only (no admin)

Same result, but installed under `%LOCALAPPDATA%\Microsoft\Windows\Fonts` and registered in `HKCU`. Per-user installs are a Windows 10 1809+ feature and don't require admin rights.

```powershell
powershell -ExecutionPolicy Bypass -File install\windows-install-current-user.ps1
```

### Option C — manual (good for one or two faces)

Open `fonts\ibm-plex-sans\fonts\complete\otf\` in Explorer, select the files you want, right-click → **Install** (current user) or **Install for all users** (admin required). Repeat per family.

> **Which format should I install on Windows?** Install the **OTF** files. OTF is the OpenType format Plex was designed and shipped in. Office and Adobe handle OTF correctly. If you ever hit a tool that refuses OTF (rare; very old apps only), install the **TTF** copy from the same family — they cover the same weights/styles.

After install you may need to **close and re-open** Word/PowerPoint/etc. — most Microsoft apps only scan the font list at startup.

---

## Install on macOS

> Works on Big Sur (11) and newer.

### Option A — automated

```bash
./install/macos-install.sh           # current user (~/Library/Fonts)
sudo TARGET=/Library/Fonts ./install/macos-install.sh   # all users
```

### Option B — Font Book

1. Open **Font Book** (⌘+Space → "Font Book").
2. **File → Add Fonts to Current User…** (or *Computer* / *All Users*).
3. Select the `fonts/` directory in this repo and click **Open**. Font Book recursively imports every `.otf`/`.ttf` it finds.

### Option C — drag and drop

Drag the `.otf` files from `fonts/<family>/fonts/complete/otf/` into `~/Library/Fonts/` (current user) or `/Library/Fonts/` (all users). macOS picks them up immediately — no cache rebuild needed.

---

## Install on Linux

> Works on any distribution that uses fontconfig (Ubuntu, Debian, Fedora, Arch, openSUSE, etc.).

### Option A — automated

```bash
./install/linux-install.sh                                  # ~/.local/share/fonts/IBM-Plex/
sudo TARGET=/usr/share/fonts/IBM-Plex ./install/linux-install.sh   # all users
```

The script copies the OTFs and TTFs into the target directory and runs `fc-cache -f` to refresh fontconfig.

### Option B — manual

```bash
mkdir -p ~/.local/share/fonts/IBM-Plex
cp -r fonts/ibm-plex-*/fonts/complete/otf/*.otf ~/.local/share/fonts/IBM-Plex/
fc-cache -f
```

Verify:

```bash
fc-list | grep -i 'IBM Plex' | head
```

---

## Use in Microsoft Office (Word, PowerPoint, Excel, Outlook)

Office uses the OS font list. After running the install steps above:

1. **Quit and relaunch** the Office app (Word doesn't notice new fonts mid-session).
2. Open the **Font dropdown** in the Home ribbon. IBM Plex faces appear as:
   - *IBM Plex Sans*
   - *IBM Plex Sans Condensed*
   - *IBM Plex Sans Light* / *Medium* / *Thin* / *ExtraLight* etc. — Office shows each weight as its own dropdown entry because of how Plex's OS/2 tables are structured.
   - *IBM Plex Serif*
   - *IBM Plex Mono*
3. Apply as usual. To set a default, **Home → Font dialog launcher (small arrow)** → choose the face → **Set As Default → All documents based on Normal.dotm**.

> **Heads up on weight selection.** Plex ships *eight* weights per Latin family (Thin → Bold). Many will show in Word as separate entries rather than via the Bold button. To pick e.g. *SemiBold*, type "IBM Plex Sans SemiBold" into the font name field directly.

---

## Use in creative apps that DO read OS fonts

These apps automatically see whatever the OS sees. **No extra setup beyond installing on the OS:**

| App | Notes |
|-----|-------|
| Adobe Photoshop, Illustrator, InDesign, XD, Premiere, After Effects, Acrobat | Reads system fonts. Restart the app after install. The Plex faces appear alongside Adobe Fonts. |
| Figma (desktop app) | Reads system fonts via the Figma "Font installer" helper; ensure it's running. Browser Figma does **not** see local fonts. |
| Sketch | Reads system fonts. |
| Affinity Designer / Photo / Publisher | Reads system fonts. |
| Microsoft Office (Word/PowerPoint/Excel/Outlook) | Reads system fonts. |
| Apple Pages / Numbers / Keynote | Reads system fonts. |
| LibreOffice / OpenOffice | Reads system fonts. |
| Google Docs (desktop browser) | Does **not** read local fonts — Google maintains its own catalog. Use Plex on the web instead. |
| Browsers (Chrome, Firefox, Safari, Edge) | Read system fonts for CSS `font-family: "IBM Plex Sans"` — useful when previewing local HTML. |
| VS Code, Sublime Text, Vim/Neovim, JetBrains IDEs | Read system fonts. Set `editor.fontFamily` / `font` / `guifont` to `"IBM Plex Mono"`. |

---

## Use in creative apps that DON'T read OS fonts

A few tools maintain their own font lists or sandbox. Here's how to point each one at this repo's `fonts/` folder so you don't have to duplicate.

### Inkscape (Windows / macOS / Linux)

Inkscape uses fontconfig (Linux) or DirectWrite/CoreText (Windows/macOS), so it normally picks up OS-installed fonts. If it doesn't:

- **Edit → Preferences → Interface → System → User config: Reset** then restart.
- Or **Edit → Preferences → Tools → Text → Font Directories** and add the absolute path to this repo's `fonts/` folder.

### GIMP

- **Edit → Preferences → Folders → Fonts → Add…**
- Add the absolute path to `fonts/` in this repo. GIMP scans recursively and picks up every `.otf`/`.ttf`.
- Click **Refresh** in the Fonts dialog (Windows → Dockable Dialogs → Fonts).

### Blender

Blender doesn't read OS fonts at all — each Text object loads a font from a path.

1. Add a Text object: **Add → Text**.
2. With the Text selected: **Properties → Object Data Properties (the "a" tab)** → **Font** section.
3. Click the folder icon next to **Regular / Bold / Italic / Bold Italic** and pick a file from `fonts/ibm-plex-sans/fonts/complete/otf/` (e.g. `IBMPlexSans-Regular.otf`).

To set a project default, use **File → Defaults → Save Startup File** after configuring the font on a Text object.

### LaTeX (XeLaTeX / LuaLaTeX)

With `fontspec` you can point at the `.otf` files directly — no system install needed:

```latex
\usepackage{fontspec}
\setmainfont{IBMPlexSans-Regular.otf}[
    Path           = ./fonts/ibm-plex-sans/fonts/complete/otf/ ,
    ItalicFont     = IBMPlexSans-Italic.otf ,
    BoldFont       = IBMPlexSans-Bold.otf ,
    BoldItalicFont = IBMPlexSans-BoldItalic.otf
]
\setmonofont{IBMPlexMono-Regular.otf}[
    Path = ./fonts/ibm-plex-mono/fonts/complete/otf/
]
```

For pdfLaTeX (which only reads system metrics), use the TeX Live `plex` package or install the fonts via the OS first.

### OBS Studio

OBS reads OS fonts on Windows/macOS/Linux for Text (GDI+) and Text (FreeType 2) sources — install via the OS steps above. No per-app config needed.

### DaVinci Resolve

Resolve reads OS fonts. Restart Resolve after installing.

### Krita

Krita reads OS fonts. Restart Krita after installing.

### Web app that bundles fonts (Notion, Slack desktop, etc.)

These ship their own font files and ignore OS fonts. You can't reliably swap them — file a feature request or use a stylesheet injector extension.

---

## Embed on a website without a CDN

The repo is ready to drop onto any web server as a static asset directory. Two patterns:

### Pattern 1 — one stylesheet, the Latin core

Copy the entire repo (or just `fonts/` plus `web/`) into your site's static assets, e.g. `https://yoursite/assets/ibm-plex-fonts/`. Then:

```html
<link rel="stylesheet" href="/assets/ibm-plex-fonts/web/ibm-plex.css">

<style>
  body { font-family: "IBM Plex Sans", system-ui, sans-serif; }
  h1, h2 { font-family: "IBM Plex Serif"; }
  code, pre { font-family: "IBM Plex Mono", monospace; }
</style>
```

`web/ibm-plex.css` defines `@font-face` for Sans, Sans Condensed, Serif, Mono, Sans Var, and Serif Var, using `woff2` (primary) and `woff` (fallback). Paths are relative to the CSS file, so it works wherever you put it as long as `fonts/` lives alongside `web/`.

See `web/example.html` for a working demo. Open it directly in a browser (`file://`) or serve it (`python3 -m http.server` from the repo root, then open `http://localhost:8000/web/example.html`) to confirm everything wires up correctly.

### Pattern 2 — per-family, IBM's official CSS

Each family folder ships a `css/ibm-plex-<family>-default.css` with proper `unicode-range` subsetting (loads only the Latin/Cyrillic/Greek bits the page actually needs). Use these directly:

```html
<link rel="stylesheet" href="/assets/ibm-plex-fonts/fonts/ibm-plex-sans/css/ibm-plex-sans-default.css">
<link rel="stylesheet" href="/assets/ibm-plex-fonts/fonts/ibm-plex-sans-arabic/css/ibm-plex-sans-arabic-default.css">
<link rel="stylesheet" href="/assets/ibm-plex-fonts/fonts/ibm-plex-sans-devanagari/css/ibm-plex-sans-devanagari-default.css">
```

Use this pattern when you need a non-Latin script that's not covered by `web/ibm-plex.css`.

### Web server config

Make sure your server:

1. Serves `.woff2` and `.woff` with the correct MIME type (`font/woff2`, `font/woff`). Most modern servers (nginx, Caddy, Apache 2.4+) already do.
2. Sends `Cache-Control: public, max-age=31536000, immutable` for font files — they never change.
3. (Optional but useful) Sets `Access-Control-Allow-Origin: *` for fonts if you serve them from a different origin than your HTML.

Example nginx snippet:

```nginx
location ~* \.(woff2?|otf|ttf)$ {
    add_header Cache-Control "public, max-age=31536000, immutable";
    add_header Access-Control-Allow-Origin "*";
    types { font/woff2 woff2; font/woff woff; font/otf otf; font/ttf ttf; }
}
```

---

## Verify the install worked

- **Windows:** open *Settings → Personalization → Fonts* and type "Plex" — you should see the full list.
- **macOS:** open *Font Book* and search for "Plex".
- **Linux:** `fc-list | grep -i 'IBM Plex' | wc -l` — expect at least ~80 for the Latin families.
- **Word / Office:** quit and relaunch, then open the font dropdown and search "Plex".
- **Web:** open `web/example.html` directly in a browser; the page should render in Plex Sans / Serif / Mono (not a fallback). If you see a generic sans-serif, the `<link>` href is wrong relative to the page.

---

## Uninstall

- **Windows:** *Settings → Personalization → Fonts*, click any "IBM Plex" entry, then **Uninstall** at the top of the panel. Repeat for each family — there's no bulk uninstall in the GUI. (Power users: delete files from `C:\Windows\Fonts` and remove matching keys from `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts`.)
- **macOS:** *Font Book → search "Plex" → select all → File → Remove*.
- **Linux:** `rm -rf ~/.local/share/fonts/IBM-Plex && fc-cache -f`.

---

## License

IBM Plex is released under the SIL Open Font License 1.1. See [`LICENSE`](LICENSE). You can use, modify, redistribute, and bundle these fonts in personal and commercial work — including embedding in PDFs, websites, apps, and physical print. The only restriction worth knowing is that you can't re-release a modified copy under the "Plex" name without IBM's permission.

This repository is a redistribution of unmodified, official IBM/plex release binaries, packaged by The Reliable Collaboration Company for internal use across its projects. It is not affiliated with or endorsed by IBM.
