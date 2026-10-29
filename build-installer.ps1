# Publishes the app as a self-contained single .exe and compiles the Inno Setup installer.
# Output: installer\output\PdfPasswordRemover-<version>-setup.exe
# -Version overrides <Version> from the .csproj (the release workflow passes the tag's version).
param([string]$Version)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$versionArgs = @()
if ($Version) { $versionArgs += "-p:Version=$Version" }
dotnet publish "$root\PdfPasswordRemover.csproj" -c Release -r win-x64 --self-contained true `
    -p:PublishSingleFile=true -p:IncludeNativeLibrariesForSelfExtract=true -p:EnableCompressionInSingleFile=true `
    @versionArgs -o "$root\installer\publish"
if ($LASTEXITCODE -ne 0) { throw "dotnet publish failed" }

$iscc = @(
    (Get-Command iscc -ErrorAction SilentlyContinue).Source,
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
    "$env:ProgramFiles\Inno Setup 6\ISCC.exe"
) | Where-Object { $_ -and (Test-Path $_) } | Select-Object -First 1
if (-not $iscc) { throw "Inno Setup 6.5+ not found. Install it with: winget install JRSoftware.InnoSetup" }

& $iscc "$root\installer\PdfPasswordRemover.iss"
if ($LASTEXITCODE -ne 0) { throw "Inno Setup compile failed" }
