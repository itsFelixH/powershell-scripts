#Requires -Version 5.1

<#
.SYNOPSIS
	Extracts evenly-spaced frames and keyframes from video files.

.DESCRIPTION
	Scans a folder for video files and uses ffmpeg/ffprobe to extract a
	specified number of evenly-distributed frames, the last frame, and all
	keyframes (I-frames). Output is saved to an "output" subfolder.
	Only processes videos in the specified folder (not recursive).

.PARAMETER Path
	Folder containing video files. Defaults to the current directory.

.PARAMETER NumFrames
	Number of evenly-spaced frames to extract per video. Defaults to 8.

.EXAMPLE
	.\Export-VideoFrames.ps1 -Path "D:\Videos" -NumFrames 12

	Extracts 12 frames, the last frame, and all keyframes from each video.

.NOTES
	Requires ffmpeg and ffprobe to be installed and available in PATH.
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[ValidateRange(1, 1000)]
	[int]$NumFrames = 8
)

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
	Write-Error "ffmpeg not found in PATH. Please install ffmpeg to use this script."
	exit 1
}
if (-not (Get-Command ffprobe -ErrorAction SilentlyContinue)) {
	Write-Error "ffprobe not found in PATH. Please install ffmpeg to use this script."
	exit 1
}

# Resolve path to handle relative paths correctly
$Path = (Resolve-Path $Path).Path

# Create output folder
$outputDir = Join-Path $Path "output"
if (-not (Test-Path $outputDir)) {
	New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$supportedExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".wmv", ".flv")
$videoFiles = Get-ChildItem -Path $Path -File | Where-Object { $_.Extension -in $supportedExtensions }
$numFiles = ($videoFiles | Measure-Object).Count

if ($numFiles -eq 0) {
	Write-Host "No video files found in '$Path'" -ForegroundColor Yellow
	Write-Host "Supported formats: $($supportedExtensions -join ', ')"
	exit 0
}

Write-Host "Processing $numFiles video file(s), extracting $NumFrames frames each..."
Write-Host "Output: $outputDir"
Write-Host ""

$videoFiles | ForEach-Object {
	Write-Host "Processing '$($_.Name)'"

	$inputFile = $_.FullName
	$outputFile = Join-Path $outputDir "$($_.BaseName)-%03d.jpg"
	$outputFileKeys = Join-Path $outputDir "$($_.BaseName)-key%02d.jpg"
	$outputFileLast = Join-Path $outputDir "$($_.BaseName)-last.jpg"

	# Get total frame count
	$framesString = (ffprobe -v error -select_streams v:0 -show_entries stream=nb_frames -of default=noprint_wrappers=1:nokey=1 -i $inputFile 2>$null)
	$totalFrames = 0
	if (-not [int]::TryParse($framesString, [ref]$totalFrames) -or $totalFrames -le 0) {
		Write-Host "  WARNING: Could not determine frame count, skipping." -ForegroundColor Yellow
		return
	}

	$rate = [math]::Max(1, [math]::Floor($totalFrames / $NumFrames))
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