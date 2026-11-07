# Regenerates the Store/MSIX icons in store\Assets from app.ico. Run it after changing app.ico.
# The images are committed, so this isn't part of the normal build.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$root = Split-Path $PSScriptRoot -Parent
$assets = "$PSScriptRoot\Assets"
New-Item -ItemType Directory $assets -Force | Out-Null

# Every image in app.ico is stored as PNG data; read them all, keyed by size (0 in the header means 256).
$bytes = [IO.File]::ReadAllBytes("$root\app.ico")
$frames = @{}
for ($i = 0; $i -lt [BitConverter]::ToUInt16($bytes, 4); $i++) {
    $entry = 6 + 16 * $i
    $size = if ($bytes[$entry] -eq 0) { 256 } else { $bytes[$entry] }
    $length = [BitConverter]::ToInt32($bytes, $entry + 8)
    $offset = [BitConverter]::ToInt32($bytes, $entry + 12)
    $frames[[int]$size] = [Drawing.Image]::FromStream([IO.MemoryStream]::new($bytes, $offset, $length))
}
$largest = $frames[($frames.Keys | Measure-Object -Maximum).Maximum]

# Draws the icon centred on a transparent canvas, using the closest ico frame at or above the target size.
function Save-Icon([string]$name, [int]$width, [int]$height, [double]$iconScale) {
    $iconSize = [int][Math]::Round([Math]::Min($width, $height) * $iconScale)
    $source = $frames.Keys | Where-Object { $_ -ge $iconSize } | Sort-Object | Select-Object -First 1
    $image = if ($source) { $frames[$source] } else { $largest }
    $bitmap = [Drawing.Bitmap]::new($width, $height)
    $g = [Drawing.Graphics]::FromImage($bitmap)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.DrawImage($image, [int](($width - $iconSize) / 2), [int](($height - $iconSize) / 2), $iconSize, $iconSize)
    $g.Dispose()
    $bitmap.Save("$assets\$name", [Drawing.Imaging.ImageFormat]::Png)
    $bitmap.Dispose()
}

foreach ($scale in 100, 200) {
    $f = $scale / 100
    Save-Icon "Square44x44Logo.scale-$scale.png" (44 * $f) (44 * $f) 1
    Save-Icon "Square150x150Logo.scale-$scale.png" (150 * $f) (150 * $f) 0.6
    Save-Icon "Wide310x150Logo.scale-$scale.png" (310 * $f) (150 * $f) 0.6
    Save-Icon "StoreLogo.scale-$scale.png" (50 * $f) (50 * $f) 1
}
# Taskbar, Start menu list and title bar sizes. "altform-unplated" draws them without a coloured plate.
foreach ($size in 16, 24, 32, 48, 256) {
    Save-Icon "Square44x44Logo.targetsize-$size.png" $size $size 1
    Save-Icon "Square44x44Logo.targetsize-${size}_altform-unplated.png" $size $size 1
}
Write-Host "Wrote icons to $assets"
