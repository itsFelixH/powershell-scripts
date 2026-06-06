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

.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path "D:\Photos"

	Prompts for confirmation before removing each empty folder.

.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path "D:\Photos" -Confirm:$false

	Removes all empty folders without prompting.

.EXAMPLE
	.\Remove-EmptyFolders.ps1 -Path "D:\Photos" -WhatIf

	Preview what would happen without making changes.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = "."
)

# Resolve path to handle relative paths correctly
$Path = (Resolve-Path $Path).Path
Write-Host "Scanning '$Path' for empty folders..."
Write-Host ""

$removedCount = 0

# Find all empty folders (process deepest first so parents become empty after children are removed)
$emptyFolders = @(Get-ChildItem -Path $Path -Recurse -Directory |
	Where-Object { (Get-ChildItem -Path $_.FullName -Force).Count -eq 0 } |
	Sort-Object { $_.FullName.Length } -Descending)

if ($emptyFolders.Count -eq 0) {
	Write-Host "No empty folders found." -ForegroundColor Green
	exit 0
}

Write-Host "Found $($emptyFolders.Count) empty folder(s)."
Write-Host ""

# Loop to handle nested folders becoming empty after children are removed
$pass = 0
$continue = $true
while ($continue -and $pass -lt 100) {
	$pass++
	$continue = $false
	$emptyFolders = @(Get-ChildItem -Path $Path -Recurse -Directory |
		Where-Object { (Get-ChildItem -Path $_.FullName -Force).Count -eq 0 } |
		Sort-Object { $_.FullName.Length } -Descending)

	foreach ($folder in $emptyFolders) {
		if ($PSCmdlet.ShouldProcess($folder.FullName, "Remove empty folder")) {
			Remove-Item -Path $folder.FullName -Force
			Write-Host "  Removed: $($folder.FullName)" -ForegroundColor Yellow
			$removedCount++
			$continue = $true
		}
	}
}

Write-Host ""
if ($removedCount -gt 0) {
	Write-Host "Done. Removed $removedCount empty folder(s)." -ForegroundColor Green
} else {
	Write-Host "No empty folders found." -ForegroundColor Green
}