# Generate an HTML page that previews every font family in this repository.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File tools\generate-font-samples.ps1
#
# Output:
#   web/font-samples.html — open directly in a browser (file://) or via a local server.
#
# When to re-run:
#   After adding, removing, or updating any font family in fonts/.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$fontsRoot = Join-Path $repoRoot "fonts"
$outputFile = Join-Path $repoRoot "web\font-samples.html"

$weightMap = @{
    "Thin"       = 100; "Hair"       = 100; "Hairline"   = 100
    "ExtraLight" = 200; "UltraLight" = 200; "Two"        = 200
    "Light"      = 300
    "Regular"    = 400; "Book"       = 400; "Roman"      = 400; "Normal" = 400; "Four" = 400; "Text" = 400
    "Medium"     = 500
    "SemiBold"   = 600; "DemiBold"   = 600; "SemiBd"     = 600
    "Bold"       = 700
    "ExtraBold"  = 800; "UltraBold"  = 800; "Eight"      = 800
    "Black"      = 900; "Heavy"      = 900; "Ultra"      = 900; "Sixteen" = 900
}

$sampleText = "The quick brown fox jumps over the lazy dog"
$sampleParagraph = "Pack my box with five dozen liquor jugs. How vexingly quick daft zebras jump! The five boxing wizards jump quickly. Sphinx of black quartz, judge my vow."
$monoSample = 'func main() { fmt.Println("Hello, world!") }'

function Get-DisplayName($dirName) {
    $parts = $dirName -split '-'
    $result = ($parts | ForEach-Object {
        if ($_.Length -le 3 -and $_ -match '^(ibm|otf|ttf)$') { $_.ToUpper() }
        else { (Get-Culture).TextInfo.ToTitleCase($_) }
    }) -join ' '
    $result = $result -replace 'Ibm Plex', 'IBM Plex'
    return $result
}

function Get-WeightFromName($fileName) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    foreach ($key in ($weightMap.Keys | Sort-Object { $_.Length } -Descending)) {
        if ($name -match "[-_]$key(?:Italic)?$" -or $name -match "$key(?:Italic)?$") {
            return $weightMap[$key]
        }
    }
    return 400
}

function Test-IsItalic($fileName) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    return ($name -match 'Italic' -or $name -match '-It$' -or $name -match 'Oblique')
}

function Test-IsVariable($fileName) {
    return ($fileName -match '\[')
}

function Test-IsOpticalVariant($fileName) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($fileName)
    return ($name -match '\d+pt[-_]' -or $name -match '^\w+\d+pt-')
}

# --- Collect font families ---
$families = @()

Get-ChildItem -Path $fontsRoot -Directory | Sort-Object Name | ForEach-Object {
    $famDir = $_.FullName
    $famName = $_.Name
    $displayName = Get-DisplayName $famName

    $ttfDir = Join-Path $famDir "fonts\complete\ttf"
    $otfDir = Join-Path $famDir "fonts\complete\otf"

    $fontFiles = @()
    if (Test-Path $ttfDir) {
        $fontFiles += Get-ChildItem -Path "$ttfDir\*" -File -Include "*.ttf"
    }
    if ($fontFiles.Count -eq 0 -and (Test-Path $otfDir)) {
        $fontFiles += Get-ChildItem -Path "$otfDir\*" -File -Include "*.otf"
    }

    if ($fontFiles.Count -eq 0) { return }

    $isVariable = $false
    $isMono = ($famName -match 'mono')
    $isEmoji = ($famName -match 'emoji')
    $entries = @()

    foreach ($file in $fontFiles) {
        $relPath = $file.FullName.Substring($repoRoot.Length + 1) -replace '\\', '/'

        if (Test-IsVariable $file.Name) {
            $isVariable = $true
            $isItalic = (Test-IsItalic $file.Name)
            $entries += @{
                Path     = $relPath
                Weight   = 400
                IsItalic = $isItalic
                IsVar    = $true
                Label    = if ($isItalic) { "Variable Italic" } else { "Variable" }
            }
        } else {
            if (Test-IsOpticalVariant $file.Name) { continue }
            $weight = Get-WeightFromName $file.Name
            $isItalic = Test-IsItalic $file.Name
            $label = ($weightMap.GetEnumerator() | Where-Object { $_.Value -eq $weight } | Select-Object -First 1).Key
            if (-not $label) { $label = "Regular" }
            if ($isItalic) { $label += " Italic" }

            $entries += @{
                Path     = $relPath
                Weight   = $weight
                IsItalic = $isItalic
                IsVar    = $false
                Label    = $label
            }
        }
    }

    if ($entries.Count -eq 0) { return }

    $families += @{
        Name        = $famName
        DisplayName = $displayName
        Entries     = $entries
        IsVariable  = $isVariable
        IsMono      = $isMono
        IsEmoji     = $isEmoji
    }
}

Write-Host ("Found {0} font families." -f $families.Count)

# --- Generate HTML ---
$fontFaces = New-Object System.Text.StringBuilder
$navLinks = New-Object System.Text.StringBuilder
$sections = New-Object System.Text.StringBuilder
$comparisons = New-Object System.Text.StringBuilder

foreach ($fam in $families) {
    $cssFamily = "sample-$($fam.Name)"
    $anchorId = $fam.Name

    # @font-face declarations
    if ($fam.IsVariable) {
        foreach ($entry in $fam.Entries) {
            $style = if ($entry.IsItalic) { "italic" } else { "normal" }
            [void]$fontFaces.AppendLine("    @font-face {")
            [void]$fontFaces.AppendLine("      font-family: '$cssFamily';")
            [void]$fontFaces.AppendLine("      src: url(""../$($entry.Path)"") format('truetype');")
            [void]$fontFaces.AppendLine("      font-weight: 100 900;")
            [void]$fontFaces.AppendLine("      font-style: $style;")
            [void]$fontFaces.AppendLine("      font-display: swap;")
            [void]$fontFaces.AppendLine("    }")
        }
    } else {
        foreach ($entry in ($fam.Entries | Sort-Object { $_.Weight }, { $_.IsItalic })) {
            $style = if ($entry.IsItalic) { "italic" } else { "normal" }
            $fmt = if ($entry.Path -match '\.otf$') { "opentype" } else { "truetype" }
            [void]$fontFaces.AppendLine("    @font-face {")
            [void]$fontFaces.AppendLine("      font-family: '$cssFamily';")
            [void]$fontFaces.AppendLine("      src: url(""../$($entry.Path)"") format('$fmt');")
            [void]$fontFaces.AppendLine("      font-weight: $($entry.Weight);")
            [void]$fontFaces.AppendLine("      font-style: $style;")
            [void]$fontFaces.AppendLine("      font-display: swap;")
            [void]$fontFaces.AppendLine("    }")
        }
    }

    # Nav link
    [void]$navLinks.AppendLine("        <a href=""#$anchorId"">$($fam.DisplayName)</a>")

    # Comparison row (skip emoji)
    if (-not $fam.IsEmoji) {
        [void]$comparisons.AppendLine("        <div class=""compare-row"">")
        [void]$comparisons.AppendLine("          <div class=""compare-label"">$($fam.DisplayName)</div>")
        [void]$comparisons.AppendLine("          <div class=""compare-text"" style=""font-family: '$cssFamily', sans-serif;"">$sampleText</div>")
        [void]$comparisons.AppendLine("        </div>")
    }

    # Family section
    [void]$sections.AppendLine("      <section class=""family"" id=""$anchorId"">")
    [void]$sections.AppendLine("        <h2>$($fam.DisplayName)</h2>")
    [void]$sections.AppendLine("        <div class=""meta"">")
    $fileCount = $fam.Entries.Count
    $typeLabel = if ($fam.IsVariable) { "variable" } elseif ($fam.IsMono) { "monospace" } elseif ($fam.IsEmoji) { "emoji" } else { "static" }
    [void]$sections.AppendLine("          <span class=""badge"">$typeLabel</span>")
    [void]$sections.AppendLine("          <span class=""file-count"">$fileCount files</span>")
    [void]$sections.AppendLine("        </div>")

    $fontStyle = "font-family: '$cssFamily', sans-serif;"

    if ($fam.IsEmoji) {
        [void]$sections.AppendLine("        <div class=""emoji-sample"" style=""$fontStyle font-size: 48px;"">")
        [void]$sections.AppendLine("          &#x1F600; &#x1F389; &#x2764; &#x1F680; &#x2728; &#x1F4A1; &#x1F3AF; &#x2705; &#x26A0; &#x1F30D;")
        [void]$sections.AppendLine("        </div>")
    } else {
        # Headline sample
        [void]$sections.AppendLine("        <div class=""sample headline"" style=""$fontStyle"">$sampleText</div>")

        # Body sample
        $bodyText = if ($fam.IsMono) { $monoSample } else { $sampleParagraph }
        [void]$sections.AppendLine("        <div class=""sample body"" style=""$fontStyle"">$bodyText</div>")

        # Weight ramp
        [void]$sections.AppendLine("        <div class=""weight-ramp"">")
        if ($fam.IsVariable) {
            $weights = @(100, 200, 300, 400, 500, 600, 700, 800, 900)
            foreach ($w in $weights) {
                $wLabel = switch ($w) {
                    100 { "Thin 100" }; 200 { "ExtraLight 200" }; 300 { "Light 300" }
                    400 { "Regular 400" }; 500 { "Medium 500" }; 600 { "SemiBold 600" }
                    700 { "Bold 700" }; 800 { "ExtraBold 800" }; 900 { "Black 900" }
                }
                [void]$sections.AppendLine("          <div class=""weight-line"" style=""$fontStyle font-weight: $w;""><span class=""weight-label"">$wLabel</span> $sampleText</div>")
            }
        } else {
            $shown = @{}
            foreach ($entry in ($fam.Entries | Where-Object { -not $_.IsItalic } | Sort-Object { $_.Weight })) {
                if ($shown.ContainsKey($entry.Weight)) { continue }
                $shown[$entry.Weight] = $true
                [void]$sections.AppendLine("          <div class=""weight-line"" style=""$fontStyle font-weight: $($entry.Weight);""><span class=""weight-label"">$($entry.Label) $($entry.Weight)</span> $sampleText</div>")
            }
        }
        [void]$sections.AppendLine("        </div>")

        # Italic sample if available
        $hasItalic = ($fam.Entries | Where-Object { $_.IsItalic }).Count -gt 0
        if ($hasItalic) {
            [void]$sections.AppendLine("        <div class=""sample italic-sample"" style=""$fontStyle font-style: italic;""><em>$sampleText</em></div>")
        }

        # Size ramp
        [void]$sections.AppendLine("        <div class=""size-ramp"">")
        foreach ($sz in @(12, 14, 16, 20, 24, 32, 48)) {
            [void]$sections.AppendLine("          <div class=""size-line"" style=""$fontStyle font-size: ${sz}px;""><span class=""size-label"">${sz}px</span> $sampleText</div>")
        }
        [void]$sections.AppendLine("        </div>")
    }

    [void]$sections.AppendLine("      </section>")
}

$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"

$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>RCC Fonts &mdash; Sample Gallery</title>
  <style>
$($fontFaces.ToString())
    * { margin: 0; padding: 0; box-sizing: border-box; }

    body {
      font-family: system-ui, -apple-system, sans-serif;
      background: #f8f9fa;
      color: #1a1a2e;
      line-height: 1.5;
    }

    header {
      background: #1a1a2e;
      color: #fff;
      padding: 48px 32px 40px;
      text-align: center;
    }
    header h1 { font-size: 36px; font-weight: 700; margin-bottom: 8px; }
    header p { color: #a0a0b8; font-size: 14px; }

    .container { max-width: 1100px; margin: 0 auto; padding: 0 24px; }

    nav {
      background: #fff;
      border-bottom: 1px solid #e0e0e0;
      padding: 16px 32px;
      position: sticky;
      top: 0;
      z-index: 100;
      overflow-x: auto;
      white-space: nowrap;
    }
    nav a {
      display: inline-block;
      color: #1a1a2e;
      text-decoration: none;
      font-size: 13px;
      padding: 4px 12px;
      border-radius: 4px;
      margin: 2px 0;
      transition: background 0.15s;
    }
    nav a:hover { background: #e8e8f0; }

    .comparison {
      background: #fff;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      margin: 32px auto;
      max-width: 1100px;
      padding: 24px;
    }
    .comparison h2 {
      font-size: 20px;
      margin-bottom: 16px;
      padding-bottom: 12px;
      border-bottom: 1px solid #eee;
    }
    .compare-row {
      display: flex;
      align-items: baseline;
      padding: 8px 0;
      border-bottom: 1px solid #f4f4f4;
    }
    .compare-row:last-child { border-bottom: none; }
    .compare-label {
      width: 220px;
      flex-shrink: 0;
      font-size: 12px;
      color: #666;
      font-family: system-ui, sans-serif;
    }
    .compare-text { font-size: 22px; flex: 1; }

    .family {
      background: #fff;
      border: 1px solid #e0e0e0;
      border-radius: 8px;
      margin: 24px auto;
      max-width: 1100px;
      padding: 32px;
    }
    .family h2 {
      font-size: 28px;
      margin-bottom: 8px;
    }
    .meta {
      margin-bottom: 24px;
      display: flex;
      align-items: center;
      gap: 12px;
    }
    .badge {
      display: inline-block;
      font-size: 11px;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      padding: 2px 10px;
      border-radius: 12px;
      background: #e8e8f0;
      color: #555;
    }
    .file-count { font-size: 13px; color: #888; }

    .sample { margin-bottom: 20px; overflow-wrap: break-word; }
    .headline { font-size: 42px; line-height: 1.2; font-weight: 700; }
    .body { font-size: 16px; line-height: 1.6; color: #333; max-width: 720px; }
    .italic-sample { font-size: 18px; color: #555; margin-bottom: 24px; }
    .emoji-sample { line-height: 1.4; margin: 16px 0; }

    .weight-ramp, .size-ramp {
      margin: 24px 0;
      padding: 20px;
      background: #fafafa;
      border-radius: 6px;
      border: 1px solid #eee;
    }
    .weight-line, .size-line {
      padding: 6px 0;
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
    .weight-label, .size-label {
      display: inline-block;
      width: 160px;
      font-family: system-ui, sans-serif;
      font-size: 12px;
      color: #888;
      font-weight: 400;
      font-style: normal;
    }

    footer {
      text-align: center;
      padding: 40px 24px;
      font-size: 13px;
      color: #999;
    }

    @media (max-width: 700px) {
      header { padding: 32px 16px; }
      header h1 { font-size: 24px; }
      .family { padding: 20px 16px; }
      .headline { font-size: 28px; }
      .compare-label { width: 140px; font-size: 11px; }
      .compare-text { font-size: 16px; }
      .weight-label, .size-label { width: 120px; }
    }
  </style>
</head>
<body>
  <header>
    <h1>RCC Fonts &mdash; Sample Gallery</h1>
    <p>$($families.Count) font families &middot; generated $timestamp</p>
  </header>

  <nav class="container">
$($navLinks.ToString())  </nav>

  <div class="container">
    <div class="comparison">
      <h2>Side-by-Side Comparison</h2>
$($comparisons.ToString())    </div>

$($sections.ToString())  </div>

  <footer>
    Generated by <code>tools/generate-font-samples.ps1</code> &middot; RCC Fonts
  </footer>
</body>
</html>
"@

$html | Out-File -FilePath $outputFile -Encoding utf8
Write-Host "Generated $outputFile"
