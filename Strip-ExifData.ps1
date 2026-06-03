#Requires -Version 5.1

<#
.SYNOPSIS
	Removes EXIF/metadata from image files.

.DESCRIPTION
	Strips all metadata (EXIF, IPTC, XMP, GPS coordinates, camera info, etc.)
	from image files using ffmpeg. Useful for privacy before sharing photos.
	Creates clean copies by default, or overwrites originals with -Overwrite.

.PARAMETER Path
	Folder to scan for images. Defaults to the current directory.

.PARAMETER Recurse
	Process subfolders recursively.

.PARAMETER Overwrite
	Overwrite original files instead of creating new ones with "_clean" suffix.

.PARAMETER Filter
	File extension filter. Defaults to common image formats.

.EXAMPLE
	.\Strip-ExifData.ps1 -Path "D:\Photos\ToShare"

	Creates cleaned copies (photo_clean.jpg) without metadata.

.EXAMPLE
	.\Strip-ExifData.ps1 -Path "D:\Photos" -Recurse -Overwrite

	Strips metadata from all images in-place.

.NOTES
	Requires ffmpeg to be installed and available in PATH.
	GPS location, camera model, date/time, and all other metadata will be removed.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[switch]$Recurse,

	[Parameter(Mandatory = $false)]
	[switch]$Overwrite
)

$imageExtensions = @(".jpg", ".jpeg", ".png", ".tiff", ".tif", ".webp", ".heic", ".heif")

$getChildItemParams = @{
	Path = $Path
	File = $true
}
if ($Recurse) { $getChildItemParams.Recurse = $true }

$files = Get-ChildItem @getChildItemParams | Where-Object { $_.Extension.ToLower() -in $imageExtensions }
$numFiles = ($files | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No image files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Stripping metadata from $numFiles image file(s)..."
if ($Overwrite) {
	Write-Host "Mode: OVERWRITE originals" -ForegroundColor Yellow
} else {
	Write-Host "Mode: Create clean copies (*_clean.ext)" -ForegroundColor Cyan
}
Write-Host ""

$processed = 0
$failed = 0

$files | ForEach-Object {
	$inputFile = $_.FullName

	if ($Overwrite) {
		$tempFile = Join-Path $_.DirectoryName "$($_.BaseName)_stripping_temp$($_.Extension)"
		$outputFile = $inputFile
	} else {
		$outputFile = Join-Path $_.DirectoryName "$($_.BaseName)_clean$($_.Extension)"

		if (Test-Path $outputFile) {
			Write-Host "  Skipped '$($_.Name)' (clean copy exists)" -ForegroundColor Yellow
			return
		}
	}

	if ($PSCmdlet.ShouldProcess($_.Name, "Strip metadata")) {
		if ($Overwrite) {
			# Write to temp file, then replace original
			ffmpeg -v quiet -y -hide_banner -i $inputFile -map_metadata -1 -map 0 -c copy $tempFile 2>$null

			if ($LASTEXITCODE -eq 0 -and (Test-Path $tempFile)) {
				Remove-Item -Path $inputFile -Force
				Move-Item -Path $tempFile -Destination $outputFile
				Write-Host "  Stripped: $($_.Name)" -ForegroundColor Green
				$script:processed++
			} else {
				if (Test-Path $tempFile) { Remove-Item -Path $tempFile -Force }
				Write-Host "  FAILED: $($_.Name)" -ForegroundColor Red
				$script:failed++
			}
		} else {
			ffmpeg -v quiet -y -hide_banner -i $inputFile -map_metadata -1 -map 0 -c copy $outputFile 2>$null

			if ($LASTEXITCODE -eq 0) {
				Write-Host "  Created: $($_.BaseName)_clean$($_.Extension)" -ForegroundColor Green
				$script:processed++
			} else {
				if (Test-Path $outputFile) { Remove-Item -Path $outputFile -Force }
				Write-Host "  FAILED: $($_.Name)" -ForegroundColor Red
				$script:failed++
			}
		}
	}
}

Write-Host ""
Write-Host "Done. Processed: $processed, Failed: $failed, Total: $numFiles" -ForegroundColor Green
