#Requires -Version 5.1

<#
.SYNOPSIS
	Converts .heic files to .jpg format.

.DESCRIPTION
	Recursively finds all .heic/.heif files in the specified folder and
	subfolders, and converts them to .jpg using ffmpeg. Skips files where
	the output already exists.

.PARAMETER Path
	Folder to scan for .heic files. Defaults to the current directory.

.PARAMETER Quality
	JPEG output quality (2-31, lower is better). Defaults to 2.

.EXAMPLE
	.\Convert-HeicToJpg.ps1 -Path "D:\iPhone-Photos"

	Converts all .heic files in the folder to .jpg.

.EXAMPLE
	.\Convert-HeicToJpg.ps1 -Path "D:\Photos" -Quality 5

	Converts with slightly lower quality (smaller file size).

.NOTES
	Requires ffmpeg to be installed and available in PATH.
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[ValidateRange(2, 31)]
	[int]$Quality = 2
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
	Write-Error "ffmpeg not found in PATH. Please install ffmpeg to use this script."
	exit 1
}

$Path = (Resolve-Path $Path).Path
$files = Get-ChildItem -Path $Path -Recurse -File -Include *.heic, *.heif
$numFiles = ($files | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No .heic/.heif files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Converting $numFiles .heic file(s)..."
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

	ffmpeg -v quiet -stats -y -hide_banner -i $inputFile -qscale:v $Quality $outputFile

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
