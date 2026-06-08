# Working journal

A log of the intentions, decisions, and considerations that went into authoring this repository. Written as the work happened, in the order it happened, so a future reader (or future-you) can reconstruct why things are the way they are.

## The goal

Matt is selecting IBM Plex for branding on a new project. He wanted a single repository he could clone onto his Windows machine and immediately use the fonts — in Microsoft Word first, but also in any creative tool and on a website that doesn't reach out to a CDN. He was unsure whether to clone the official `IBM/plex` source repo and build it, or to use the prebuilt artifacts, and delegated the decision.

Implicit requirements I derived from that brief:

- Cloning must be enough — no `npm install`, no font compilation, no follow-up downloads.
- The instructions must cover Windows, macOS, and Linux even though the immediate use case is Windows, because the same brand assets will likely move between his machines.
- "Full use" means every language coverage IBM ships, not just Latin.
- "Creative tooling that doesn't pull from OS font lists" was called out specifically — so the README must address that gap, not just OS install.
- Self-hosting on a website without a CDN means shipping the actual font files and a working stylesheet, not just instructions.

## Decision 1: prebuilt releases, not building from source

The `IBM/plex` source repo is a Lerna monorepo that requires Node, Python, fontmake, and a multi-hour build to produce the very same `.otf` / `.ttf` / `.woff` / `.woff2` files that IBM publishes as GitHub release ZIPs. There is no value in re-running that pipeline locally for a redistribution-and-install use case.

So: download the published release ZIPs, extract them, commit the result. The fonts in the releases are byte-identical to what IBM intends users to consume.

## Decision 2: which release ZIPs to include

IBM/plex was reorganized so that each family is now its own npm/GitHub release with its own version. The latest of each (as of authoring this repo) is pinned in `FAMILIES.md`. I included **every** family — Latin, Condensed, Variable axes, Serif, Mono, Arabic, Hebrew, Devanagari, Thai, Thai Looped, JP, KR, SC, TC — because Matt asked for "full use."

The trade-off: the CJK families dominate the repo. SC alone is 586 MB; the four CJK families total ~1.4 GB; the whole repo is ~1.6 GB. I considered three alternatives:

1. **Skip CJK by default, fetch on demand via a script.** Cleaner repo, more friction at use time. Rejected because Matt said "clone → register → use."
2. **Use git LFS for the CJK files.** Adds a hard dependency on `git-lfs` being installed before cloning works, which makes the setup brittle on a fresh Windows box. Rejected.
3. **Ship everything inline.** Larger initial clone but one-time cost, and works with a vanilla `git clone`. Chosen.

I verified that no individual file exceeds GitHub's 100 MB hard limit (largest is around 18 MB), so direct pushing to GitHub will not be blocked. `FAMILIES.md` documents which folders to delete if the CJK weight is unwanted.

## Decision 3: preserve IBM's per-family layout, don't flatten

I considered re-arranging the files into a flat `fonts/{otf,ttf,woff,woff2}/` tree at the root. That would be tidier on first glance but would:

- break the relative URLs inside IBM's prebuilt CSS (which says `url("../fonts/complete/woff2/IBMPlexSans-Regular.woff2")`),
- destroy the boundary between families (e.g. installers couldn't easily decide "install Latin OTFs but only hinted CJK"),
- diverge from IBM's published structure, making future re-syncs awkward.

So I kept each release's internal layout intact and just placed the family folders side by side under `fonts/`. The two variable releases (`plex-sans-variable`, `plex-serif-variable`) shipped with inconsistent root paths — one extracted to `fonts/`, the other to `plex-serif-variable/` — and I normalized both to mirror the static-family layout (`<family>/fonts/{complete,split}/...`). I noted that mismatch as an oddity worth re-checking the next time IBM updates the variable releases.

## Decision 4: how aggressive to be with the install scripts

I wrote four installers (`windows-install-all-users.ps1`, `windows-install-current-user.ps1`, `linux-install.sh`, `macos-install.sh`). Considerations:

- **OTF vs TTF.** Both are installed because some Office versions historically prefer TTF for embedding in `.docx`. Disk cost is small relative to CJK so I didn't try to be clever about picking one.
- **Hinted vs unhinted CJK.** Hinted is preferred on Windows because Windows uses hints for low-DPI glyph rendering. The installers ship only hinted CJK to halve the install footprint without hurting visual quality on the target OS.
- **Registering with Windows.** A copy into `C:\Windows\Fonts` is *not* enough on Windows 10/11 — the font must also be in `HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts` (or `HKCU` for per-user). The script uses `System.Windows.Media.GlyphTypeface` to extract the proper Win32 family name from each file so the registry key matches what Word displays in its dropdown. I considered using PowerShell's older Shell.Application Namespace 0x14 approach but it has been deprecated for batch installs and shows nag dialogs.
- **No "uninstall" script.** Uninstall is rare and the README covers the manual path. A wrong uninstall could break other apps' fonts; not worth the foot-gun.

## Decision 5: web stylesheet — one combined CSS, not @import chains

I considered three approaches to the self-hosting story:

1. **Point users at IBM's per-family CSS only.** Smallest authoring effort. But requires the user to write multiple `<link>` tags and figure out which ones they need.
2. **Generate one consolidated CSS via `@import` of each family's default CSS.** Browsers do resolve `@import`-ed URLs relative to the imported file, so the relative `../fonts/...` URLs would still work. But `@import` is render-blocking and serial; bad for performance.
3. **Hand-author one consolidated `web/ibm-plex.css` with `@font-face` for the Latin core.** Single `<link>`, parallel resource discovery, and zero magic. Chosen.

The combined CSS covers Sans, Sans Condensed, Serif, Mono, and both Variable faces. Non-Latin scripts (Arabic, Hebrew, Devanagari, Thai, CJK) are kept out of the combined file because:

- They blow up the @font-face declaration count (each CJK family has 80+ subset declarations).
- Each project that needs them needs only one or two specific scripts.
- IBM already ships well-tuned per-family CSS with proper `unicode-range` subsetting.

So the recipe is: one `<link>` for Latin core, plus per-family `<link>`s for any non-Latin script you actually need. Documented in the README.

I also included `web/example.html` as a working test page. If a user opens it in a browser and sees Plex render, the wiring is correct. If they see fallbacks, they have a debugging starting point.

## Decision 6: where the installers and docs live, and what they're called

- `install/` — all installer scripts. Named by OS so a Windows user doesn't accidentally try to run the macOS script.
- `web/` — self-hosting assets. Separate from `fonts/` because `web/ibm-plex.css` is *my* artifact, not IBM's, and I didn't want to mix authored content with redistributed content.
- `FAMILIES.md` — the version-pinning table. Kept separate from the README so the README stays readable and FAMILIES can grow with future additions without bloating the front page.
- `working-journal.md` — this file. Matt requested it explicitly mid-task to capture decisions and considerations.

## Considerations I deliberately didn't act on

- **Subsetting Latin to a smaller "marketing site" file.** Useful for production landing pages but premature here — the user can always pyftsubset later.
- **Generating PDF specimens.** Nice-to-have but adds tooling dependencies (fonttools, etc.) and is easy to do later with the OTFs in hand.
- **Including the source `sources.zip` artifacts.** They're useful for re-hinting or subsetting but not for installation, and they roughly double download size.
- **A Makefile or task runner.** The install scripts are short, OS-specific, and self-documenting; adding a wrapper layer would just hide what they do.
- **Git LFS / a downloader script for CJK.** Considered (see Decision 2) and rejected for the "clone → use" simplicity goal.

## Things to revisit next time IBM ships a release

1. Re-check the variable-family ZIP layouts. Both shipped with non-standard root directories at the time of authoring (see Decision 3). If IBM normalizes them, the `_downloads` extraction step in any update workflow can drop the special-case handling.
2. Re-pin the version numbers in `FAMILIES.md`.
3. Re-check whether IBM has added a Mono Variable face. As of authoring, only Sans and Serif have variable versions.
4. Confirm IBM is still distributing via release ZIPs and not e.g. switching to npm-only distribution.

## Provenance

Every font file in this repo came from `https://github.com/IBM/plex/releases/download/%40ibm%2F<family>%40<version>/<family>.zip`. SHA256 of the ZIPs wasn't checked because (a) GitHub serves them over TLS and (b) git itself records a hash of every file in the tree once committed, which is the artifact a user is actually consuming. If higher provenance assurance is needed later, capture the SHA256s into `FAMILIES.md`.

---

## Follow-up: dropping CJK after first review

After the initial scaffolding, Matt asked what "CJK" meant. Once it was clear that CJK = Chinese / Japanese / Korean and that he wouldn't need any of those for the current branding work, we agreed the 1.4 GB cost wasn't worth the optionality. So:

- The four CJK family folders were deleted, taking the repo from ~1.6 GB to **75 MB**.
- The install scripts had been special-casing CJK (preferring the `hinted/` subdirectories that those families ship, and falling back to the base directory for KR's unsplit OTFs). All of that logic was deleted — every remaining family has the same flat `fonts/complete/{otf,ttf}/` layout, so the installers are now a single loop with no per-family branching. Net win for readability.
- `FAMILIES.md` was rewritten: CJK families came out of the version table and were moved into a short "Adding CJK later" section with a copy-paste bash snippet that re-fetches the four ZIPs and drops them back into `fonts/`. The installer scripts will pick them up automatically the next time they run.
- `README.md` lost the "1.6 GB repository" warning, the CJK mention in the Office dropdown list, the CJK-only "use hinted variants" notes in the install sections, and the JP example in the per-family web embed section.
- `web/example.html`'s footer paragraph dropped its CJK mention with a forward pointer to `FAMILIES.md` if it's ever needed.

The decision overrides Decision 2 above (which leaned toward bundling everything). Both decisions are recorded as written — Decision 2 reflects the reasoning at authoring time given the brief, and this section reflects the refined choice once the actual use case was clarified.
