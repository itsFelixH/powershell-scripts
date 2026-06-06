#Requires -Version 5.1

<#
.SYNOPSIS
	Renames files using their date (EXIF or last modified).

.DESCRIPTION
	Scans a folder and renames files using the pattern "yyyy-MM-dd_HHmmss"
	based on the file's Date Taken (EXIF) metadata. Falls back to LastWriteTime
	if no EXIF data is available. Handles collisions by appending a counter
	suffix. Use -Recurse to include subfolders.

.PARAMETER Path
	Folder to scan. Defaults to the current directory.

.PARAMETER Format
	Date format string for the new filename. Defaults to "yyyy-MM-dd_HHmmss".

.PARAMETER Filter
	File extension filter (e.g. "*.jpg"). Defaults to all files.

.PARAMETER Recurse
	Process subfolders recursively.

.EXAMPLE
	.\Rename-FilesByDate.ps1 -Path "D:\Photos" -Recurse

	Renames all files to their date: 2024-03-15_143022.jpg

.EXAMPLE
	.\Rename-FilesByDate.ps1 -Path "D:\Photos" -Filter "*.jpg" -Format "yyyyMMdd_HHmmss"

	Renames only .jpg files with a compact date format.

.EXAMPLE
	.\Rename-FilesByDate.ps1 -Path "D:\Photos" -WhatIf

	Preview changes without renaming anything.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[string]$Format = "yyyy-MM-dd_HHmmss",

	[Parameter(Mandatory = $false)]
	[string]$Filter = "*",

	[Parameter(Mandatory = $false)]
	[switch]$Recurse
)

function Get-DateTaken {
	param([string]$FilePath)

	try {
		$shell = New-Object -ComObject Shell.Application
		$folder = $shell.Namespace((Split-Path $FilePath))
		$file = $folder.ParseName((Split-Path $FilePath -Leaf))

		# Property 12 is "Date taken" in Windows Shell
		$dateTaken = $folder.GetDetailsOf($file, 12)

		if ($dateTaken) {
			# Remove invisible Unicode characters that Windows sometimes adds
			$dateTaken = $dateTaken -replace '[^\d/: APM]', ''
			$parsed = [DateTime]::MinValue
			if ([DateTime]::TryParse($dateTaken, [ref]$parsed)) {
				return $parsed
			}
		}
	} catch {
		# Shell COM object not available (e.g. on Linux/macOS)
	}

	return $null
}

# Resolve path to handle relative paths correctly
$Path = (Resolve-Path $Path).Path

$getChildItemParams = @{
	Path   = $Path
	File   = $true
	Filter = $Filter
}
if ($Recurse) { $getChildItemParams.Recurse = $true }

$files = @(Get-ChildItem @getChildItemParams)
$totalFiles = $files.Count

if ($totalFiles -eq 0) {
	Write-Host "No files found matching '$Filter' in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Processing $totalFiles file(s)..."
Write-Host ""

$renamedCount = 0
$skippedCount = 0

$files | ForEach-Object {
	# Try EXIF Date Taken first, fall back to LastWriteTime
	$date = Get-DateTaken -FilePath $_.FullName
	$dateSource = "EXIF"

	if (-not $date) {
		$date = $_.LastWriteTime
		$dateSource = "Modified"
	}

	$baseName = $date.ToString($Format)
	$extension = $_.Extension
	$directory = $_.DirectoryName

	# Handle collisions by appending a counter
	$newName = "$baseName$extension"
	$newPath = Join-Path $directory $newName
	$counter = 1

	while ((Test-Path $newPath) -and ($newPath -ne $_.FullName)) {
		$newName = "${baseName}_$counter$extension"
		$newPath = Join-Path $directory $newName
		$counter++
	}

	if ($PSCmdlet.ShouldProcess($_.Name, "Rename to '$newName' ($dateSource)")) {
		$_ | Rename-Item -NewName $newName
		$renamedCount++
	}
}

Write-Host ""
Write-Host "Done. Renamed: $renamedCount, Skipped: $skippedCount" -ForegroundColor Green