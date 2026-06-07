# Parameters
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Position = 0)]
    [string]$Path = ".",

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Pattern,

    [Parameter()]
    [switch]$Force
)

# Custom color definitions
$successColor = "Green"
$warningColor = "Yellow"
$errorColor = "Red"
$infoColor = "Cyan"

function Write-Log {
    param (
        [Parameter(Mandatory = $true)]
        [string]$message,
        [string]$foregroundColor = "White"
    )
    Write-Host "$message" -ForegroundColor $foregroundColor
}

# Validate input folder
if (-not (Test-Path -LiteralPath $Path)) {
    Write-Log "Source path not found: $Path" -foregroundColor $errorColor
    return
}

$VideoFiles = Get-ChildItem -LiteralPath $Path -File | 
              Where-Object { $_.Extension -match '\.(mkv|mp4|mov|wmv|avi|flv)$' -and $_.Name -like "*$Pattern*" }

$numFiles = ($VideoFiles | Measure-Object).Count

if ($numFiles -eq 0) {
    Write-Log "No files found containing pattern '$Pattern' in $Path" -foregroundColor $warningColor
    return
}

Write-Log "`n--- REMOVE & STANDARDIZE PATTERN ---" -foregroundColor $infoColor
Write-Log "Pattern: $Pattern"
Write-Log "Path:    $Path`n"

$numRenamed = 0

foreach ($file in $VideoFiles) {
    $name = $file.BaseName
    $ext  = $file.Extension

    # Remove ALL occurrences of the pattern
    $clean = $name -replace [regex]::Escape($Pattern), ""

    # Remove duplicate separators (e.g. "--", "  ")
    $clean = $clean -replace "\s{2,}", " " -replace "[-_]{2,}", "-" -replace "- -", "-"

    # Trim whitespace / separators
    $clean = $clean.Trim(" -_")

    # Add ONE clean instance of the pattern at the front
    $newName = "$Pattern - $clean$ext"

    if ($file.Name -eq $newName) {
        continue
    }

    Write-Log "Proposed: $newName" -foregroundColor $infoColor

    if ($Force -or $PSCmdlet.ShouldProcess($file.Name, "Rename to $newName")) {
        try {
            Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction Stop
            $numRenamed++
        }
        catch {
            Write-Log "  Error: Failed to rename $($file.Name)" -foregroundColor $errorColor
        }
    }
}

Write-Log "`nSuccessfully standardized $numRenamed files." -foregroundColor $successColor

if ($Host.Name -eq "ConsoleHost" -and -not $Force) { Read-Host "Press ENTER to exit..." }
