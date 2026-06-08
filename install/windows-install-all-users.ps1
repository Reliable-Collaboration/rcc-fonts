# Install every .ttf and .otf font in this repo system-wide on Windows.
#
# Usage (must be run from an Administrator PowerShell):
#   cd <path-to-repo>
#   powershell -ExecutionPolicy Bypass -File install\windows-install-all-users.ps1
#   powershell -ExecutionPolicy Bypass -File install\windows-install-all-users.ps1 -Force
#
# Behavior:
#   - Copies files to C:\Windows\Fonts (the all-users location).
#   - Registers each file in HKLM so it survives a reboot and is visible to
#     Word, PowerPoint, Adobe Creative Cloud apps, Sketch, Affinity, etc.
#   - Skips fonts that are already installed unless -Force is specified.

param(
    [switch]$Force
)

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$fontsRoot = Join-Path $repoRoot "fonts"

if (-not (Test-Path $fontsRoot)) {
    throw "Could not find $fontsRoot. Run this script from inside the repo."
}

$systemFontDir = Join-Path $env:WINDIR "Fonts"
$regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

$candidates = New-Object System.Collections.Generic.List[string]

Get-ChildItem -Path $fontsRoot -Directory | ForEach-Object {
    $family = $_.FullName
    @("otf","ttf") | ForEach-Object {
        $dir = Join-Path $family ("fonts\complete\{0}" -f $_)
        if (Test-Path $dir) {
            Get-ChildItem -Path "$dir\*" -File -Include "*.otf","*.ttf" | ForEach-Object { $candidates.Add($_.FullName) }
        }
    }
}

Write-Host ("Found {0} font files to install." -f $candidates.Count)

# Load the Win32 typeface name from each font file so the registry entry uses
# the proper "Family Name Style (TrueType)" / "Family Name Style (OpenType)" key.
Add-Type -AssemblyName PresentationCore
function Get-FontDisplayName($path) {
    try {
        $uri = New-Object System.Uri($path)
        $glyphTypeface = New-Object System.Windows.Media.GlyphTypeface($uri)
        $name = $glyphTypeface.Win32FamilyNames.Values | Select-Object -First 1
        $face = $glyphTypeface.Win32FaceNames.Values   | Select-Object -First 1
        if (-not $name) { return $null }
        if ($face -and $face -ne "Regular") { return "$name $face" } else { return $name }
    } catch { return $null }
}

$installed = 0
$skipped = 0
foreach ($file in $candidates) {
    $name = [System.IO.Path]::GetFileName($file)
    $dest = Join-Path $systemFontDir $name

    if ((Test-Path $dest) -and -not $Force) {
        $skipped++
        continue
    }

    Copy-Item -Path $file -Destination $dest -Force

    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $kind = if ($ext -eq ".otf") { "OpenType" } else { "TrueType" }
    $display = Get-FontDisplayName $file
    if (-not $display) { $display = [System.IO.Path]::GetFileNameWithoutExtension($file) }
    $regValueName = "{0} ({1})" -f $display, $kind

    New-ItemProperty -Path $regKey -Name $regValueName -Value $name -PropertyType String -Force | Out-Null
    $installed++
}

if ($installed -eq 0 -and $skipped -gt 0) {
    Write-Host ("All {0} fonts are already installed. Use -Force to reinstall." -f $skipped)
} elseif ($skipped -gt 0) {
    Write-Host ("Installed {0} fonts to {1}. Skipped {2} already-installed fonts. Use -Force to reinstall all." -f $installed, $systemFontDir, $skipped)
} else {
    Write-Host ("Installed {0} fonts to {1}." -f $installed, $systemFontDir)
}
if ($installed -gt 0) {
    Write-Host "Restart any already-open apps (Word, Photoshop, etc.) to see the new fonts."
}
