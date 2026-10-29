# Packages the published .exe together with qpdf into a portable zip that runs without installing anything.
# Run build-installer.ps1 first. Output: installer\output\PdfPasswordRemover-<version>-portable.zip
# qpdf's version and SHA-256 are read from installer\PdfPasswordRemover.iss so they live in one place.
param([string]$Version)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = $PSScriptRoot

$exe = "$root\installer\publish\PdfPasswordRemover.exe"
if (-not (Test-Path $exe)) { throw "$exe not found. Run build-installer.ps1 first." }
if (-not $Version) {
    $Version = ((Get-Item $exe).VersionInfo.ProductVersion -split '[+-]')[0]
}

$iss = Get-Content "$root\installer\PdfPasswordRemover.iss" -Raw
$qpdfVersion = [regex]::Match($iss, '#define QpdfVersion "([^"]+)"').Groups[1].Value
$qpdfSha256 = [regex]::Match($iss, '#define QpdfSha256 "([^"]+)"').Groups[1].Value
if (-not $qpdfVersion -or -not $qpdfSha256) { throw "Could not read QpdfVersion/QpdfSha256 from the .iss file" }

$qpdfFolder = "qpdf-$qpdfVersion-msvc64"
$work = Join-Path ([IO.Path]::GetTempPath()) "pdfpr-portable-$([guid]::NewGuid())"
New-Item -ItemType Directory $work | Out-Null
try {
    $zip = "$work\qpdf.zip"
    Invoke-WebRequest "https://github.com/qpdf/qpdf/releases/download/v$qpdfVersion/$qpdfFolder.zip" -OutFile $zip
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($hash -ne $qpdfSha256) { throw "qpdf zip SHA-256 mismatch: expected $qpdfSha256, got $hash" }
    Expand-Archive $zip "$work\qpdf"

    # The app finds qpdf.exe when it sits next to PdfPasswordRemover.exe.
    $stage = "$work\stage"
    New-Item -ItemType Directory $stage | Out-Null
    Copy-Item $exe $stage
    Copy-Item "$work\qpdf\$qpdfFolder\bin\*" $stage
    Get-ChildItem "$work\qpdf\$qpdfFolder" -Recurse -File -Include 'LICENSE*', 'NOTICE*' |
        ForEach-Object { Copy-Item $_.FullName "$stage\qpdf-$($_.Name)" }

    New-Item -ItemType Directory "$root\installer\output" -Force | Out-Null
    $out = "$root\installer\output\PdfPasswordRemover-$Version-portable.zip"
    Compress-Archive "$stage\*" $out -Force
    Write-Host "Created $out"
}
finally {
    Remove-Item $work -Recurse -Force
}
