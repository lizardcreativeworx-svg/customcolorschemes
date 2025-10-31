<#
.SYNOPSIS
    Generates a custom image with a background, frame, and overlay text.

.DESCRIPTION
    Reads color and text configuration from a JSON file (or defaults).
    Applies a small "nudge" to RGB values for uniqueness.
    Supports multilingual overlay text via -Language parameter.
    Outputs a PNG image with a frame and overlay text.

.PARAMETER ConfigPath
    Path to a JSON config file with color and text settings.

.PARAMETER Language
    Language code (e.g., "en", "es", "fr"). Defaults to "en".
    If translation not found, falls back to default text.

.EXAMPLE
    .\Generate-CustomImage.ps1 -ConfigPath ".\config.json" -Language "es"
#>

param (
    [string]$ConfigPath = ".\config.json",
    [string]$Language = "en"
)

# --- Load Drawing Assembly ---
Add-Type -AssemblyName System.Drawing

# --- Helper: Nudge RGB values ---
function Nudge-RGB($rgb, $offset = 2) {
    return @(
        [Math]::Min(255, [Math]::Max(0, [int]$rgb[0] + $offset)),
        [Math]::Min(255, [Math]::Max(0, [int]$rgb[1] + $offset)),
        [Math]::Min(255, [Math]::Max(0, [int]$rgb[2] + $offset))
    )
}

# --- Load Config or Defaults ---
if (Test-Path $ConfigPath) {
    try {
        $config    = Get-Content $ConfigPath | ConvertFrom-Json
        $BgRGB     = @($config.backgroundColor[0], $config.backgroundColor[1], $config.backgroundColor[2])
        $FrameRGB  = @($config.frameColor[0], $config.frameColor[1], $config.frameColor[2])
        $TextRGB   = @($config.textColor[0], $config.textColor[1], $config.textColor[2])
        $Text      = $config.text

        # Handle translations if available
        if ($config.PSObject.Properties.Name -contains "translations") {
            if ($config.translations[$Language]) {
                $Text = $config.translations[$Language]
            }
        }
    }
    catch {
        Write-Host "[ERROR] Failed to parse config file. Using defaults." -ForegroundColor Red
        $BgRGB     = @(240,240,240)
        $FrameRGB  = @(255,63,63)   # Sunset Coral
        $TextRGB   = @(94,84,255)   # Sky Indigo
        $Text      = "Welcome to the Ryguy Color Scheme"
    }
} else {
    Write-Host "[WARNING] Config file not found. Using defaults." -ForegroundColor Yellow
    $BgRGB     = @(240,240,240)
    $FrameRGB  = @(255,63,63)   # Sunset Coral
    $TextRGB   = @(94,84,255)   # Sky Indigo
    $Text      = "Welcome to the Ryguy Color Scheme"
}

# --- Apply Nudge for uniqueness ---
$BgRGB     = Nudge-RGB $BgRGB 1
$FrameRGB  = Nudge-RGB $FrameRGB 2
$TextRGB   = Nudge-RGB $TextRGB 1

# --- Create Colors ---
$bgColor    = [System.Drawing.Color]::FromArgb([int]$BgRGB[0], [int]$BgRGB[1], [int]$BgRGB[2])
$frameColor = [System.Drawing.Color]::FromArgb([int]$FrameRGB[0], [int]$FrameRGB[1], [int]$FrameRGB[2])
$textColor  = [System.Drawing.Color]::FromArgb([int]$TextRGB[0], [int]$TextRGB[1], [int]$TextRGB[2])

# --- Create Image ---
$bitmap   = New-Object System.Drawing.Bitmap 800, 600
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)

try {
    # Background
    $graphics.Clear($bgColor)

    # Frame
    $pen = New-Object System.Drawing.Pen ($frameColor, 5)
    $graphics.DrawRectangle($pen, 8, 8, 784, 584)  # Adjusted to ensure frame is visible

    # Text
    try {
        $font  = New-Object System.Drawing.Font("Arial", 24)
    } catch {
        $font  = New-Object System.Drawing.Font("Segoe UI", 24)
    }
    $brush = New-Object System.Drawing.SolidBrush($textColor)
    $graphics.DrawString($Text, $font, $brush, 20, 20)

    # Save
    $outputPath = ".\custom_image.png"
    $bitmap.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Host "✅ Image saved to $outputPath" -ForegroundColor Green
}
finally {
    $graphics.Dispose()
    $bitmap.Dispose()
    if ($pen) { $pen.Dispose() }
    if ($font) { $font.Dispose() }
    if ($brush) { $brush.Dispose() }
}