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

[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[ValidateRange(2, 31)]
	[int]$Quality = 2
)

function Format-FileSize {
    param([long]$size)
    if ($size -gt 1GB) { "{0:N2} GB" -f ($size / 1GB) }
    elseif ($size -gt 1MB) { "{0:N2} MB" -f ($size / 1MB) }
    elseif ($size -gt 1KB) { "{0:N2} KB" -f ($size / 1KB) }
    else { "$size bytes" }
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
	Write-Error "ffmpeg not found in PATH. Please install ffmpeg to use this script."
	return
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
	$inputFile = $_.FullName
	$outputFile = Join-Path $_.DirectoryName "$($_.BaseName).jpg"

	Write-Host "Processing '$($_.Name)'" -ForegroundColor White
	Write-Host "  Original Size: $(Format-FileSize -size $_.Length)" -ForegroundColor DarkGray

	if (Test-Path $outputFile) {
		Write-Host "  Skipping: Output already exists." -ForegroundColor Yellow
		return
	}

	if ($PSCmdlet.ShouldProcess($_.Name, "Convert HEIC to JPG")) {
		$elapsed = Measure-Command {
			& ffmpeg -v quiet -stats -y -hide_banner -i $inputFile -qscale:v $Quality $outputFile
		}

		if ($LASTEXITCODE -eq 0) {
			$newSize = (Get-Item $outputFile).Length
			Write-Host "  Finished in $($elapsed.TotalSeconds.ToString('F2'))s" -ForegroundColor Gray
			Write-Host "  New Size:      $(Format-FileSize -size $newSize)" -ForegroundColor Green
			$script:converted++
		} else {
			Write-Host "  FAILED to convert." -ForegroundColor Red
			$script:failed++
		}
	} else {
		Write-Host "  FAILED to convert." -ForegroundColor Red
		$script:failed++
	}
}

Write-Host ""
Write-Host "Done. Converted: $converted, Skipped: $($numFiles - $converted - $failed), Failed: $failed" -ForegroundColor Green
