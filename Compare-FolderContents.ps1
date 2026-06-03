# Compare two folders to verify that a backup contains all files from the source.
# Usage: .\compare-folders.ps1 -Source "C:\path\to\source" -Backup "C:\path\to\backup"

param(
	[Parameter(Mandatory=$true)]
	[string]$Source,

	[Parameter(Mandatory=$true)]
	[string]$Backup
)

# Validate paths
if (-not (Test-Path $Source)) {
	Write-Host "ERROR: Source folder not found: $Source" -ForegroundColor Red
	exit 1
}
if (-not (Test-Path $Backup)) {
	Write-Host "ERROR: Backup folder not found: $Backup" -ForegroundColor Red
	exit 1
}

Write-Host "Source: $Source"
Write-Host "Backup: $Backup"
Write-Host ""

# Get all files with relative paths
$sourceFiles = Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
	[PSCustomObject]@{
		RelativePath = $_.FullName.Substring($Source.TrimEnd('\', '/').Length + 1)
		FullName     = $_.FullName
		Length       = $_.Length
	}
}

$backupFiles = Get-ChildItem -Path $Backup -Recurse -File | ForEach-Object {
	[PSCustomObject]@{
		RelativePath = $_.FullName.Substring($Backup.TrimEnd('\', '/').Length + 1)
		FullName     = $_.FullName
		Length       = $_.Length
	}
}

$sourceCount = ($sourceFiles | Measure-Object).Count
$backupCount = ($backupFiles | Measure-Object).Count

Write-Host "Files in source: $sourceCount"
Write-Host "Files in backup: $backupCount"
Write-Host ""

# Build a lookup of backup files by relative path
$backupLookup = @{}
$backupFiles | ForEach-Object { $backupLookup[$_.RelativePath] = $_ }

# Find files missing from backup
$missingFiles = @()
$sizeMismatch = @()

$sourceFiles | ForEach-Object {
	if (-not $backupLookup.ContainsKey($_.RelativePath)) {
		$missingFiles += $_.RelativePath
	} elseif ($backupLookup[$_.RelativePath].Length -ne $_.Length) {
		$sizeMismatch += [PSCustomObject]@{
			File       = $_.RelativePath
			SourceSize = $_.Length
			BackupSize = $backupLookup[$_.RelativePath].Length
		}
	}
}

# Report results
if ($missingFiles.Count -eq 0 -and $sizeMismatch.Count -eq 0) {
	Write-Host "ALL GOOD - Backup contains all $sourceCount source files with matching sizes." -ForegroundColor Green
} else {
	if ($missingFiles.Count -gt 0) {
		Write-Host "MISSING FILES ($($missingFiles.Count)):" -ForegroundColor Red
		$missingFiles | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
		Write-Host ""
	}
	if ($sizeMismatch.Count -gt 0) {
		Write-Host "SIZE MISMATCH ($($sizeMismatch.Count)):" -ForegroundColor Red
		$sizeMismatch | ForEach-Object {
			Write-Host "  $($_.File)  (source: $($_.SourceSize) bytes, backup: $($_.BackupSize) bytes)" -ForegroundColor Yellow
		}
		Write-Host ""
	}
}

# Also report extra files in backup that aren't in source
$sourceLookup = @{}
$sourceFiles | ForEach-Object { $sourceLookup[$_.RelativePath] = $_ }

$extraFiles = $backupFiles | Where-Object { -not $sourceLookup.ContainsKey($_.RelativePath) }

if (($extraFiles | Measure-Object).Count -gt 0) {
	Write-Host "EXTRA FILES in backup (not in source): $(($extraFiles | Measure-Object).Count)" -ForegroundColor Cyan
	$extraFiles | ForEach-Object { Write-Host "  $($_.RelativePath)" -ForegroundColor Cyan }
}
