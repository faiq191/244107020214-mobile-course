param(
  [Parameter(Mandatory=$true)][string]$InFile,
  [Parameter(Mandatory=$true)][string]$OutFile,
  [string]$Title = ""
)

Add-Type -AssemblyName System.Drawing

$lines = Get-Content -LiteralPath $InFile -Encoding UTF8

# Pad so the last line is not clipped and keep a sane maximum width.
$maxCols = 110
$wrapped = @()
foreach ($l in $lines) {
  $t = $l -replace "`t", "    "
  if ([string]::IsNullOrEmpty($t)) { $wrapped += ""; continue }
  while ($t.Length -gt $maxCols) {
    $wrapped += $t.Substring(0, $maxCols)
    $t = $t.Substring($maxCols)
  }
  $wrapped += $t
}

$fontSize = 15
$font = New-Object System.Drawing.Font("Consolas", $fontSize, [System.Drawing.FontStyle]::Regular)
$boldFont = New-Object System.Drawing.Font("Consolas", $fontSize, [System.Drawing.FontStyle]::Bold)
$padX = 16
$padTop = 14
$lineH = 20
$titleH = if ($Title) { 34 } else { 0 }

# measure
$tmp = New-Object System.Drawing.Bitmap 1,1
$g = [System.Drawing.Graphics]::FromImage($tmp)
$maxW = 640
foreach ($w in $wrapped) {
  $sz = $g.MeasureString($w, $font)
  if ($sz.Width -gt $maxW) { $maxW = [int][math]::Ceiling($sz.Width) }
}
$g.Dispose(); $tmp.Dispose()

$width = $maxW + ($padX * 2)
$height = $padTop * 2 + $titleH + ($wrapped.Count * $lineH) + 8

$bmp = New-Object System.Drawing.Bitmap $width, $height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::ClearTypeGridFit

# terminal-dark background
$g.Clear([System.Drawing.Color]::FromArgb(30, 30, 30))

$titleBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 200, 255))
$textBrush  = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 220, 220))
$greenBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(120, 230, 130))
$redBrush   = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(240, 120, 120))

$y = $padTop
if ($Title) {
  $g.DrawString($Title, $boldFont, $titleBrush, $padX, $y)
  $y += $titleH
  $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(80, 80, 80))
  $g.DrawLine($pen, $padX, $y - 6, $width - $padX, $y - 6)
}

foreach ($w in $wrapped) {
  $brush = $textBrush
  if ($w -match "All tests passed|No issues found|No more") { $brush = $greenBrush }
  elseif ($w -match "Failed|Error|error -|not supported|Unable to find") { $brush = $redBrush }
  $g.DrawString($w, $font, $brush, $padX, $y)
  $y += $lineH
}

$g.Dispose()
$bmp.Save($OutFile, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "Wrote $OutFile ($width x $height)"
