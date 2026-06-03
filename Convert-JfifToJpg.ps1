#Requires -Version 5.1

<#
.SYNOPSIS
	Converts .jfif files to .jpg format.

.DESCRIPTION
	Recursively finds all .jfif files in the specified folder and converts them
	to .jpg using ffmpeg. Skips files where the output already exists.

.PARAMETER Path
	Folder to scan for .jfif files. Defaults to the current directory.

.EXAMPLE
	.\Convert-JfifToJpg.ps1 -Path "D:\Downloads"

	Converts all .jfif files in D:\Downloads and subfolders to .jpg.

.NOTES
	Requires ffmpeg to be installed and available in PATH.
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = "."
)

$files = Get-ChildItem -Path $Path -Recurse -File -Filter "*.jfif"
$numFiles = ($files | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No .jfif files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Converting $numFiles .jfif file(s)..."
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

	ffmpeg -v quiet -stats -y -hide_banner -i $inputFile $outputFile

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
