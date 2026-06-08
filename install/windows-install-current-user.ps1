# Install every IBM Plex .ttf and .otf for the CURRENT USER only.
#
# Usage (regular non-admin PowerShell is fine):
#   cd <path-to-repo>
#   powershell -ExecutionPolicy Bypass -File install\windows-install-current-user.ps1
#
# Behavior:
#   - Copies files to %LOCALAPPDATA%\Microsoft\Windows\Fonts (the per-user
#     location introduced in Windows 10 1809).
#   - Registers each file in HKCU so it survives a reboot.
#   - No admin privileges required.

$ErrorActionPreference = "Stop"
$repoRoot = Split-Path -Parent $PSScriptRoot
$fontsRoot = Join-Path $repoRoot "fonts"

if (-not (Test-Path $fontsRoot)) {
    throw "Could not find $fontsRoot. Run this script from inside the repo."
}

$userFontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
New-Item -ItemType Directory -Force -Path $userFontDir | Out-Null
$regKey = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
New-Item -Path $regKey -Force | Out-Null

$candidates = New-Object System.Collections.Generic.List[string]

Get-ChildItem -Path $fontsRoot -Directory | ForEach-Object {
    $family = $_.FullName
    @("otf","ttf") | ForEach-Object {
        $dir = Join-Path $family ("fonts\complete\{0}" -f $_)
        if (Test-Path $dir) {
            Get-ChildItem -Path $dir -File -Include "*.otf","*.ttf" | ForEach-Object { $candidates.Add($_.FullName) }
        }
    }
}

Write-Host ("Found {0} font files to install." -f $candidates.Count)

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
foreach ($file in $candidates) {
    $name = [System.IO.Path]::GetFileName($file)
    $dest = Join-Path $userFontDir $name

    Copy-Item -Path $file -Destination $dest -Force

    $ext = [System.IO.Path]::GetExtension($file).ToLower()
    $kind = if ($ext -eq ".otf") { "OpenType" } else { "TrueType" }
    $display = Get-FontDisplayName $file
    if (-not $display) { $display = [System.IO.Path]::GetFileNameWithoutExtension($file) }
    $regValueName = "{0} ({1})" -f $display, $kind

    # HKCU stores the absolute path, not just the filename.
    New-ItemProperty -Path $regKey -Name $regValueName -Value $dest -PropertyType String -Force | Out-Null
    $installed++
}

Write-Host ("Installed {0} fonts for user {1} to {2}." -f $installed, $env:USERNAME, $userFontDir)
Write-Host "Restart any already-open apps (Word, Photoshop, etc.) to see the new fonts."
