#Requires -Version 5.1

<#
.SYNOPSIS
	Converts .webp files to .jpg format.

.DESCRIPTION
	Recursively finds all .webp files in the specified folder and converts them
	to .jpg using ffmpeg. Skips files where the output already exists.

.PARAMETER Path
	Folder to scan for .webp files. Defaults to the current directory.

.EXAMPLE
	.\Convert-WebpToJpg.ps1 -Path "D:\Downloads"

	Converts all .webp files in D:\Downloads and subfolders to .jpg.

.NOTES
	Requires ffmpeg to be installed and available in PATH.
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = "."
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
	Write-Error "ffmpeg not found in PATH. Please install ffmpeg to use this script."
	exit 1
}

# Resolve path to handle relative paths correctly
$Path = (Resolve-Path $Path).Path

$files = Get-ChildItem -Path $Path -Recurse -File -Filter "*.webp"
$numFiles = ($files | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No .webp files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Converting $numFiles .webp file(s)..."
Write-Host ""

$converted = 0
$failed = 0

$files | ForEach-Object {
	Write-Host "Processing '$($_.Name)'"

	$inputFile = $_.FullName
	$outputFile = Join-Path $_.DirectoryName "$($_.BaseName).jpg"

	if (Test-Path $outputFile) {
		Write-Host "  Skipped (output already exists)" -ForegroundColor Yellow
		return
	}

	ffmpeg -v quiet -stats -y -hide_banner -i $inputFile -vframes 1 -update true $outputFile

	if ($LASTEXITCODE -eq 0) {
		Write-Host "  Converted." -ForegroundColor Green
		$script:converted++
	} else {
		Write-Host "  FAILED to convert." -ForegroundColor Red
		$script:failed++
	}
}

Write-Host ""
Write-Host "Done. Converted: $converted, Skipped: $($numFiles - $converted - $failed), Failed: $failed" -ForegroundColor Green