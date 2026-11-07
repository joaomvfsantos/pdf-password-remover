# Packages the published .exe, qpdf and store\AppxManifest.xml into an MSIX for the Microsoft Store.
# Run build-installer.ps1 first. Output: installer\output\PdfPasswordRemover-<version>-x64.msix
# The package is unsigned: the Store signs it when you submit it. The unpacked package is left in
# installer\output\store-layout so it can be test-installed locally (see CONTRIBUTING.md).
# qpdf's version and SHA-256 are read from installer\PdfPasswordRemover.iss so they live in one place.
param([string]$Version)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$root = $PSScriptRoot

# makeappx/makepri come from the Windows SDK if installed, otherwise from this NuGet package.
$buildToolsVersion = '10.0.26100.7705'

$exe = "$root\installer\publish\PdfPasswordRemover.exe"
if (-not (Test-Path $exe)) { throw "$exe not found. Run build-installer.ps1 first." }
if (-not $Version) {
    $Version = ((Get-Item $exe).VersionInfo.ProductVersion -split '[+-]')[0]
}
# Store packages need a 4-part version whose last part is 0.
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Version must look like 1.2.0, got '$Version'" }
$packageVersion = "$Version.0"

$iss = Get-Content "$root\installer\PdfPasswordRemover.iss" -Raw
$qpdfVersion = [regex]::Match($iss, '#define QpdfVersion "([^"]+)"').Groups[1].Value
$qpdfSha256 = [regex]::Match($iss, '#define QpdfSha256 "([^"]+)"').Groups[1].Value
if (-not $qpdfVersion -or -not $qpdfSha256) { throw "Could not read QpdfVersion/QpdfSha256 from the .iss file" }

$manifest = [xml]::new()
$manifest.PreserveWhitespace = $true
$manifest.Load("$root\store\AppxManifest.xml")
$ns = [Xml.XmlNamespaceManager]::new($manifest.NameTable)
$ns.AddNamespace('m', 'http://schemas.microsoft.com/appx/manifest/foundation/windows10')
$manifest.SelectSingleNode('/m:Package/m:Identity', $ns).SetAttribute('Version', $packageVersion)

$work = Join-Path ([IO.Path]::GetTempPath()) "pdfpr-store-$([guid]::NewGuid())"
New-Item -ItemType Directory $work | Out-Null
try {
    function Find-SdkTool([string]$name) {
        $sdk = Get-ChildItem "${env:ProgramFiles(x86)}\Windows Kits\10\bin\*\x64\$name" -ErrorAction SilentlyContinue |
            Sort-Object { [version]$_.Directory.Parent.Name } -Descending | Select-Object -First 1
        if ($sdk) { return $sdk.FullName }
        $tools = "$work\buildtools"
        if (-not (Test-Path $tools)) {
            Invoke-WebRequest "https://www.nuget.org/api/v2/package/Microsoft.Windows.SDK.BuildTools/$buildToolsVersion" -OutFile "$work\buildtools.zip"
            Expand-Archive "$work\buildtools.zip" $tools
        }
        (Get-ChildItem "$tools\bin\*\x64\$name" | Select-Object -First 1).FullName
    }
    $makeappx = Find-SdkTool 'makeappx.exe'
    $makepri = Find-SdkTool 'makepri.exe'

    $qpdfFolder = "qpdf-$qpdfVersion-msvc64"
    $zip = "$work\qpdf.zip"
    Invoke-WebRequest "https://github.com/qpdf/qpdf/releases/download/v$qpdfVersion/$qpdfFolder.zip" -OutFile $zip
    $hash = (Get-FileHash $zip -Algorithm SHA256).Hash
    if ($hash -ne $qpdfSha256) { throw "qpdf zip SHA-256 mismatch: expected $qpdfSha256, got $hash" }
    Expand-Archive $zip "$work\qpdf"

    # Same layout as the installer: the app finds qpdf\qpdf.exe under its own folder.
    $layout = "$root\installer\output\store-layout"
    if (Test-Path $layout) { Remove-Item $layout -Recurse -Force }
    New-Item -ItemType Directory "$layout\qpdf" -Force | Out-Null
    Copy-Item $exe $layout
    Copy-Item "$work\qpdf\$qpdfFolder\bin\*" "$layout\qpdf"
    Get-ChildItem "$work\qpdf\$qpdfFolder" -Recurse -File -Include 'LICENSE*', 'NOTICE*' |
        ForEach-Object { Copy-Item $_.FullName "$layout\qpdf\$($_.Name)" }
    Copy-Item "$root\store\Assets" $layout -Recurse
    $manifest.Save("$layout\AppxManifest.xml")

    # resources.pri lets Windows pick the right icon size (scale-200, targetsize-48, ...).
    & $makepri createconfig /cf "$work\priconfig.xml" /dq en-US /o | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "makepri createconfig failed" }
    # Drop the default <packaging> rules, which split scale-200 icons into a separate .pri meant for bundles.
    $priConfig = [xml](Get-Content "$work\priconfig.xml" -Raw)
    $priConfig.resources.SelectNodes('packaging') | ForEach-Object { [void]$_.ParentNode.RemoveChild($_) }
    $priConfig.Save("$work\priconfig.xml")
    & $makepri new /pr $layout /cf "$work\priconfig.xml" /mn "$layout\AppxManifest.xml" /of "$layout\resources.pri" /o | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "makepri new failed" }

    $out = "$root\installer\output\PdfPasswordRemover-$Version-x64.msix"
    & $makeappx pack /d $layout /p $out /o | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "makeappx pack failed" }
    Write-Host "Created $out"
}
finally {
    Remove-Item $work -Recurse -Force
}
