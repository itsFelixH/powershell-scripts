#Requires -Version 5.1

<#
.SYNOPSIS
    Batch converts video files to H.264 MKV format.
.DESCRIPTION
    Scans a source directory for common video formats and compresses them using the 
    libx264 codec. High compatibility for older devices while maintaining high quality.
.PARAMETER Path
    The source directory containing videos.
.PARAMETER Destination
    The directory where converted files will be saved.
.PARAMETER BatchSize
    Number of files to process before pausing for review. Default is 0 (disabled).
.PARAMETER Recurse
    Search for videos in subdirectories.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Path,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$Destination,

    [Parameter(Mandatory = $false)]
    [int]$BatchSize = 0,

    [Parameter(Mandatory = $false)]
    [switch]$Recurse
)

function Format-FileSize {
    param([long]$size)
    if ($size -gt 1GB) { "{0:N2} GB" -f ($size / 1GB) }
    elseif ($size -gt 1MB) { "{0:N2} MB" -f ($size / 1MB) }
    elseif ($size -gt 1KB) { "{0:N2} KB" -f ($size / 1KB) }
    else { "$size bytes" }
}

if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg not found in PATH."
    return
}

$resolvedSource = (Resolve-Path $Path).Path
$resolvedDest = (Resolve-Path $Destination).Path

Write-Host "`n-----------------------" -ForegroundColor Cyan
Write-Host "--- CONVERT TO X264 ---" -ForegroundColor Cyan
Write-Host "-----------------------`n"

$extensions = @(".mp4", ".mov", ".wmv", ".avi", ".flv", ".mkv")
$videoFiles = Get-ChildItem -Path $resolvedSource -File -Recurse:$Recurse | 
              Where-Object { $_.Extension.ToLower() -in $extensions }

$numFiles = ($videoFiles | Measure-Object).Count

if ($numFiles -eq 0) {
    Write-Host "No files found in '$resolvedSource'" -ForegroundColor Yellow
    return
}

Write-Host "Found $numFiles file(s) to process." -ForegroundColor Green

$numConverted = 0

foreach ($file in $videoFiles) {
    $numConverted++
    $outputFile = Join-Path $resolvedDest "$($file.BaseName)_x264.mkv"

    Write-Host "[$numConverted/$numFiles] Processing: $($file.Name)" -ForegroundColor White

    if ($PSCmdlet.ShouldProcess($file.Name, "Convert to X264 MKV")) {
        if (Test-Path $outputFile) {
            Write-Host "  Skipping: Output already exists." -ForegroundColor Yellow
            continue
        }

        $elapsed = Measure-Command {
            $ffmpegArgs = @(
                "-v", "quiet", "-stats", "-y", "-hide_banner",
                "-i", $file.FullName,
                "-map", "0", "-map_chapters", "-1",
                "-c:v", "libx264", "-crf", "18", "-pix_fmt", "yuv420p",
                "-c:a", "copy",
                $outputFile
            )
            & ffmpeg @ffmpegArgs
        }

        if ($LASTEXITCODE -eq 0) {
            $newSize = (Get-Item $outputFile).Length
            Write-Host "  Finished in $($elapsed.TotalSeconds.ToString('F2'))s" -ForegroundColor Gray
            Write-Host "  New Size: $(Format-FileSize -size $newSize)" -ForegroundColor Green
        } else {
            Write-Host "  Error occurred during conversion." -ForegroundColor Red
        }
    }

    $numRemaining = $numFiles - $numConverted
    if ($BatchSize -gt 0 -and $numRemaining -gt 0 -and ($numConverted % $BatchSize) -eq 0) {
        Write-Host "`nBatch complete. $numRemaining remaining." -ForegroundColor Cyan
        Read-Host "Press ENTER to continue..."
    }
}

Write-Host "`nAll files processed!" -ForegroundColor Green
if ($Host.Name -eq "ConsoleHost") {
    Read-Host "Press ENTER to exit..."
}