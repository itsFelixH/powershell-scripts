#Requires -Version 5.1

<#
.SYNOPSIS
	Finds corrupt or unreadable media files.

.DESCRIPTION
	Scans a folder for media files (images and videos) and uses ffprobe to
	verify each file can be read. Reports any files that are broken, truncated,
	or otherwise unreadable.

.PARAMETER Path
	Folder to scan. Defaults to the current directory.

.PARAMETER Recurse
	Process subfolders recursively.

.PARAMETER MoveTo
	Move broken files to this folder instead of just reporting them.

.EXAMPLE
	.\Find-BrokenMedia.ps1 -Path "D:\Photos" -Recurse

	Scans all media files and lists any that are broken.

.EXAMPLE
	.\Find-BrokenMedia.ps1 -Path "D:\Photos" -Recurse -MoveTo "D:\Broken"

	Moves broken files to a separate folder for review.

.NOTES
	Requires ffprobe (part of ffmpeg) to be installed and available in PATH.
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[switch]$Recurse,

	[Parameter(Mandatory = $false)]
	[string]$MoveTo
)

$mediaExtensions = @(
	".jpg", ".jpeg", ".png", ".gif", ".bmp", ".tiff", ".tif",
	".webp", ".heic", ".heif", ".jfif", ".svg",
	".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv", ".webm",
	".mp3", ".wav", ".flac", ".aac", ".ogg", ".m4a", ".wma"
)

# Create move-to folder if specified
if ($MoveTo -and -not (Test-Path $MoveTo)) {
	New-Item -ItemType Directory -Path $MoveTo | Out-Null
}

$getChildItemParams = @{
	Path = $Path
	File = $true
}
if ($Recurse) { $getChildItemParams.Recurse = $true }

$files = Get-ChildItem @getChildItemParams | Where-Object { $_.Extension.ToLower() -in $mediaExtensions }
$totalFiles = ($files | Measure-Object).Count

if ($totalFiles -eq 0) {
	Write-Host "No media files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Checking $totalFiles media file(s)..."
Write-Host ""

$brokenFiles = @()
$checkedCount = 0

$files | ForEach-Object {
	$checkedCount++

	# Show progress every 50 files
	if ($checkedCount % 50 -eq 0) {
		Write-Host "  Checked $checkedCount / $totalFiles..." -ForegroundColor DarkGray
	}

	$inputFile = $_.FullName

	# Use ffprobe to verify the file is readable
	$errorOutput = ffprobe -v error -i $inputFile 2>&1

	if ($LASTEXITCODE -ne 0 -or $errorOutput) {
		$script:brokenFiles += [PSCustomObject]@{
			File  = $_.FullName
			Name  = $_.Name
			Size  = $_.Length
			Error = ($errorOutput | Out-String).Trim()
		}
	}
}

Write-Host ""

if ($brokenFiles.Count -eq 0) {
	Write-Host "ALL GOOD - All $totalFiles media files are readable." -ForegroundColor Green
} else {
	Write-Host "BROKEN FILES ($($brokenFiles.Count) of $totalFiles):" -ForegroundColor Red
	Write-Host ""

	foreach ($broken in $brokenFiles) {
		Write-Host "  $($broken.File)" -ForegroundColor Yellow
		if ($broken.Error) {
			Write-Host "    $($broken.Error)" -ForegroundColor DarkGray
		}

		# Move if requested
		if ($MoveTo) {
			$destination = Join-Path $MoveTo $broken.Name
			$counter = 1
			while (Test-Path $destination) {
				$ext = [System.IO.Path]::GetExtension($broken.Name)
				$base = [System.IO.Path]::GetFileNameWithoutExtension($broken.Name)
				$destination = Join-Path $MoveTo "${base}_$counter$ext"
				$counter++
			}
			Move-Item -Path $broken.File -Destination $destination
			Write-Host "    -> Moved to $destination" -ForegroundColor Cyan
		}
	}

	Write-Host ""
	$brokenSizeMB = [math]::Round(($brokenFiles | Measure-Object -Property Size -Sum).Sum / 1MB, 2)
	Write-Host "Total broken: $($brokenFiles.Count) file(s), $brokenSizeMB MB" -ForegroundColor Red
}
