#Requires -Version 5.1

<#
.SYNOPSIS
	Prepends the parent folder name to each file's name.

.DESCRIPTION
	Recursively scans a directory and renames every file by adding its parent
	folder name as a prefix (e.g. "Vacation - img001.jpg"). Files that already
	have the correct prefix are skipped.

.PARAMETER Path
	The root folder to process. Defaults to the script's own directory.

.EXAMPLE
	.\Rename-FileWithFolderPrefix.ps1 -Path "D:\Photos"

	Before: D:\Photos\Vacation\img001.jpg
	After:  D:\Photos\Vacation\Vacation - img001.jpg

.EXAMPLE
	.\Rename-FileWithFolderPrefix.ps1 -Path "D:\Photos" -WhatIf

	Shows what would be renamed without making changes.
#>

[CmdletBinding(SupportsShouldProcess)]
param (
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[String[]]$Path = "$PSScriptRoot"
)

$files = @(Get-ChildItem -Path $Path -File -Recurse)
$totalFiles = $files.Count
$renamedCount = 0
$skippedCount = 0

Write-Host "Found $totalFiles file(s) in '$Path'"

$files | ForEach-Object {
	$prefix = "$($_.Directory.Name) - "

	if (-not $_.Name.StartsWith($prefix)) {
		$newName = $prefix + $_.Name
		if ($PSCmdlet.ShouldProcess($_.FullName, "Rename to '$newName'")) {
			$_ | Rename-Item -NewName $newName
			$renamedCount++
		}
	} else {
		$skippedCount++
	}
}

Write-Host ""
Write-Host "Done. Renamed: $renamedCount, Skipped (already prefixed): $skippedCount" -ForegroundColor Green
