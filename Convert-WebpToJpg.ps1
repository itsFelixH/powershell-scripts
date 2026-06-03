# Converts .webp files to .jpg using ffmpeg.
# Usage: .\webp-to-jpg.ps1 -Path "C:\path\to\images"

param(
	[Parameter(Mandatory = $false)]
	[string]$Path = "."
)

# Validate path
if (-not (Test-Path $Path)) {
	Write-Host "ERROR: Path not found: $Path" -ForegroundColor Red
	exit 1
}

$files = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.Extension -eq ".webp" }
$numFiles = ($files | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No .webp files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Converting $numFiles .webp file(s)..."
Write-Host ""

$converted = 0

$files | ForEach-Object {
	Write-Host "Processing '$($_.Name)'"

	$inputFile = $_.FullName
	$outputFile = Join-Path $_.DirectoryName "$($_.BaseName).jpg"

	# Skip if output already exists
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
	}
}

Write-Host ""
Write-Host "Done. Converted $converted of $numFiles file(s)." -ForegroundColor Green
