#Requires -Version 5.1

<#
.SYNOPSIS
	Finds and removes duplicate files based on content hash.

.DESCRIPTION
	Scans a folder recursively, groups files by SHA256 hash, and identifies
	duplicates. By default prompts for confirmation before removing.
	Use -Confirm:$false to skip prompts, or -WhatIf to preview.

	When duplicates are found, the first file (alphabetically by full path)
	is kept and the rest are removed or moved.

.PARAMETER Path
	Folder to scan for duplicates. Defaults to the current directory.

.PARAMETER MoveTo
	Instead of deleting duplicates, move them to this folder.

.EXAMPLE
	.\Remove-DuplicateFiles.ps1 -Path "D:\Photos"

	Dry run - shows duplicates without removing anything (use -Confirm:$false to execute).

.EXAMPLE
	.\Remove-DuplicateFiles.ps1 -Path "D:\Photos" -Confirm:$false

	Deletes all duplicate files, keeping one copy of each.

.EXAMPLE
	.\Remove-DuplicateFiles.ps1 -Path "D:\Photos" -MoveTo "D:\Duplicates"

	Moves duplicate files to D:\Duplicates instead of deleting them.
#>

[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[string]$MoveTo
)

# Create move-to folder if specified
if ($MoveTo -and -not (Test-Path $MoveTo)) {
	New-Item -ItemType Directory -Path $MoveTo | Out-Null
}

# Resolve path to handle relative paths correctly
$Path = (Resolve-Path $Path).Path

Write-Host "Scanning '$Path' for duplicate files..."
Write-Host ""

$files = Get-ChildItem -Path $Path -Recurse -File
$totalFiles = ($files | Measure-Object).Count

if ($totalFiles -eq 0) {
	Write-Host "No files found." -ForegroundColor Yellow
	exit 0
}

Write-Host "Found $totalFiles file(s). Computing hashes..."

# Group by size first (quick pre-filter, files with unique sizes can't be duplicates)
$sizeGroups = $files | Group-Object Length | Where-Object { $_.Count -gt 1 }
$candidates = $sizeGroups | ForEach-Object { $_.Group }
$candidateCount = ($candidates | Measure-Object).Count

Write-Host "  $candidateCount file(s) share a size with at least one other file."
Write-Host "  Computing SHA256 hashes for candidates..."

# Hash only the candidates
$hashedFiles = $candidates | ForEach-Object {
	[PSCustomObject]@{
		Hash     = (Get-FileHash -Path $_.FullName -Algorithm SHA256).Hash
		FullName = $_.FullName
		Length   = $_.Length
		Name     = $_.Name
	}
}

# Group by hash to find actual duplicates
$duplicateGroups = $hashedFiles | Group-Object Hash | Where-Object { $_.Count -gt 1 }

if ($duplicateGroups.Count -eq 0) {
	Write-Host ""
	Write-Host "No duplicates found." -ForegroundColor Green
	exit 0
}

$totalDuplicates = ($duplicateGroups | ForEach-Object { $_.Count - 1 } | Measure-Object -Sum).Sum
$savedBytes = ($duplicateGroups | ForEach-Object {
	($_.Count - 1) * $_.Group[0].Length
} | Measure-Object -Sum).Sum
$savedMB = [math]::Round($savedBytes / 1MB, 2)

Write-Host ""
Write-Host "Found $($duplicateGroups.Count) group(s) of duplicates ($totalDuplicates duplicate files, $savedMB MB reclaimable)" -ForegroundColor Cyan
Write-Host ""

$removedCount = 0

foreach ($group in $duplicateGroups) {
	# Keep the first file (sorted alphabetically), remove the rest
	$sorted = $group.Group | Sort-Object FullName
	$keep = $sorted[0]
	$dupes = $sorted[1..($sorted.Count - 1)]

	Write-Host "  Keep: $($keep.FullName)" -ForegroundColor Green
	foreach ($dupe in $dupes) {
		if ($PSCmdlet.ShouldProcess($dupe.FullName, "Remove duplicate")) {
			if ($MoveTo) {
				$destination = Join-Path $MoveTo $dupe.Name
				# Handle name collisions in the move-to folder
				$counter = 1
				while (Test-Path $destination) {
					$destination = Join-Path $MoveTo "$([System.IO.Path]::GetFileNameWithoutExtension($dupe.Name))_$counter$([System.IO.Path]::GetExtension($dupe.Name))"
					$counter++
				}
				Move-Item -Path $dupe.FullName -Destination $destination
				Write-Host "  Moved: $($dupe.FullName)" -ForegroundColor Yellow
			} else {
				Remove-Item -Path $dupe.FullName
				Write-Host "  Removed: $($dupe.FullName)" -ForegroundColor Red
			}
			$removedCount++
		}
	}
	Write-Host ""
}

Write-Host "Done. Processed $removedCount duplicate(s)." -ForegroundColor Green