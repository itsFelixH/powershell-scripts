# Extracts evenly-spaced frames and keyframes from video files.
# Usage: .\extract-images-from-video.ps1 -Path "C:\Videos" -NumFrames 8
# Outputs images into an "output" subfolder.

param(
	[Parameter(Mandatory = $false)]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[int]$NumFrames = 8
)

# Validate path
if (-not (Test-Path $Path)) {
	Write-Host "ERROR: Path not found: $Path" -ForegroundColor Red
	exit 1
}

# Create output folder
$outputDir = Join-Path $Path "output"
if (-not (Test-Path $outputDir)) {
	New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$videoFiles = Get-ChildItem -Path $Path -Recurse -File | Where-Object { $_.Extension -in ".mp4", ".mkv", ".avi", ".mov" }
$numFiles = ($videoFiles | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No video files found in '$Path'" -ForegroundColor Yellow
	exit 0
}

Write-Host "Processing $numFiles video file(s), extracting $NumFrames frames each..."
Write-Host ""

$videoFiles | ForEach-Object {
	Write-Host "Processing '$($_.Name)'"

	$inputFile = $_.FullName
	$outputFile = Join-Path $outputDir "$($_.BaseName)-%03d.jpg"
	$outputFileKeys = Join-Path $outputDir "$($_.BaseName)-key%02d.jpg"
	$outputFileLast = Join-Path $outputDir "$($_.BaseName)-last.jpg"

	# Get total frame count
	$framesString = (ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=noprint_wrappers=1:nokey=1 -i $inputFile)
	$totalFrames = [int]$framesString

	if ($totalFrames -le 0) {
		Write-Host "  WARNING: Could not determine frame count, skipping." -ForegroundColor Yellow
		return
	}

	$rate = [math]::Floor($totalFrames / $NumFrames)
	Write-Host "  Total frames: $totalFrames, extracting every ${rate}th frame"

	# Extract evenly-spaced frames
	ffmpeg -v quiet -y -hide_banner -i $inputFile -f image2 -vf "select='not(mod(n,$rate))'" -vframes $NumFrames -vsync vfr $outputFile

	# Extract last frame
	ffmpeg -v quiet -y -hide_banner -i $inputFile -f image2 -vf "select='eq(n,$($totalFrames-1))'" -vframes 1 $outputFileLast

	# Extract keyframes (I-frames)
	ffmpeg -v quiet -y -hide_banner -i $inputFile -vf "select=eq(pict_type\,I)" -vsync vfr $outputFileKeys

	Write-Host "  Done." -ForegroundColor Green
}

Write-Host ""
Write-Host "All frames extracted to: $outputDir" -ForegroundColor Green
