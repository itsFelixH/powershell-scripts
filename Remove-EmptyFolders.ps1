#Requires -Version 5.1

<#
.SYNOPSIS
	Removes empty folders recursively.

.DESCRIPTION
	Scans a directory tree bottom-up and removes any folders that contain no
	files (or only contain other empty folders). Useful for cleanup after
	batch file operations like moving or deduplication.

.PARAMETER Path
	Root folder to scan. Defaults to the current directory.

.PARAMETER Force
	Remove empty folders without prompting for confirmation.

.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path "D:\Photos"

	Dry run - shows which empty folders would be removed.

.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path "D:\Photos" -Force

	Removes all empty folders immediately.

.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path "D:\Photos" -WhatIf

	Preview what would happen without making changes.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[switch]$Force
)

Write-Host "Scanning '$Path' for empty folders..."
Write-Host ""

$removedCount = 0
$pass = 0

# Loop until no more empty folders are found (handles nested empty folders)
do {
	$pass++
	$emptyFolders = @(Get-ChildItem -Path $Path -Recurse -Directory |
		Where-Object { (Get-ChildItem -Path $_.FullName -Force).Count -eq 0 } |
		Sort-Object { $_.FullName.Length } -Descending)  # Process deepest first

	if ($emptyFolders.Count -eq 0) {
		break
	}

	foreach ($folder in $emptyFolders) {
		if ($Force -or $PSCmdlet.ShouldProcess($folder.FullName, "Remove empty folder")) {
			Remove-Item -Path $folder.FullName -Force
			Write-Host "  Removed: $($folder.FullName)" -ForegroundColor Yellow
			$removedCount++
		} else {
			Write-Host "  Empty: $($folder.FullName)" -ForegroundColor DarkGray
		}
	}
} while ($emptyFolders.Count -gt 0 -and $pass -lt 100)

Write-Host ""
if ($removedCount -gt 0) {
	Write-Host "Done. Removed $removedCount empty folder(s)." -ForegroundColor Green
} else {
	Write-Host "No empty folders found." -ForegroundColor Green
}
