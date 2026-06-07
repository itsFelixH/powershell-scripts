# Parameters
[CmdletBinding(SupportsShouldProcess)]
param (
    [Parameter(Position = 0)]
    [string]$Path = ".",

    [Parameter(Position = 1)]
    [int]$Count = 30,

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
    Where-Object { $_.Extension -match '\.(mkv|mp4|mov|wmv|avi|flv)$' }

$numFiles = ($VideoFiles | Measure-Object).Count

if ($numFiles -eq 0) {
    Write-Log "No video files found in $Path" -foregroundColor $warningColor
    return
}

Write-Log "`n--- SHORTEN VIDEO NAMES ---" -foregroundColor $infoColor
Write-Log "Chars to remove: $Count"
Write-Log "Path:            $Path`n"

$numRenamed = 0

foreach ($file in $VideoFiles) {
    if ($file.BaseName.Length -gt $Count) {
        $newName = $file.Name.Substring($Count)
        
        # Ensure we don't end up with an empty name or just an extension
        if ([string]::IsNullOrWhiteSpace([System.IO.Path]::GetFileNameWithoutExtension($newName))) {
            Write-Log "  Skipping: Shortening would result in empty filename for $($file.Name)" -foregroundColor $warningColor
            continue
        }

        Write-Log "Proposed: $newName" -foregroundColor $infoColor

        if ($Force -or $PSCmdlet.ShouldProcess($file.Name, "Shorten to $newName")) {
            try {
                Rename-Item -LiteralPath $file.FullName -NewName $newName -ErrorAction Stop
                $numRenamed++
            }
            catch {
                Write-Log "  Error: Failed to rename $($file.Name). Details: $_" -foregroundColor $errorColor
            }
        }
    }
    else {
        Write-Log "  Skipping: $($file.Name) is shorter than $Count characters." -foregroundColor $warningColor
    }
}

Write-Log "`nSuccessfully shortened $numRenamed files." -foregroundColor $successColor

if ($Host.Name -eq "ConsoleHost" -and -not $Force) { Read-Host "Press ENTER to exit..." }
