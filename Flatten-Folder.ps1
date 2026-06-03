#Requires -Version 5.1

<#
.SYNOPSIS
	Moves all files from subfolders into a single flat directory.

.DESCRIPTION
	Recursively finds all files in subdirectories and moves them up to the
	root folder. Handles name collisions by appending a counter suffix.
	Optionally removes the now-empty subfolders after flattening.

.PARAMETER Path
	The root folder to flatten. Defaults to the current directory.

.PARAMETER RemoveEmptyFolders
	Remove empty subfolders after moving files up.

.PARAMETER Prefix
	Prepend the original subfolder path to the filename to preserve context.
	E.g. "Vacation\Day1\img.jpg" becomes "Vacation_Day1_img.jpg".

.EXAMPLE
	.\Flatten-Folder.ps1 -Path "D:\Photos"

	Moves all files from subfolders into D:\Photos.

.EXAMPLE
	.\Flatten-Folder.ps1 -Path "D:\Photos" -RemoveEmptyFolders

	Flattens and cleans up empty subfolders afterwards.

.EXAMPLE
	.\Flatten-Folder.ps1 -Path "D:\Photos" -Prefix -WhatIf

	Preview: files get subfolder names prepended to avoid collisions.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[switch]$RemoveEmptyFolders,

	[Parameter(Mandatory = $false)]
	[switch]$Prefix
)

$resolvedPath = (Resolve-Path $Path).Path

# Get all files that are NOT already in the root folder
$files = Get-ChildItem -Path $resolvedPath -Recurse -File | Where-Object {
	$_.DirectoryName -ne $resolvedPath
}

$totalFiles = ($files | Measure-Object).Count

if ($totalFiles -eq 0) {
	Write-Host "No files in subfolders to flatten." -ForegroundColor Yellow
	exit 0
}

Write-Host "Flattening $totalFiles file(s) into '$resolvedPath'..."
if ($Prefix) { Write-Host "Mode: Prefix subfolder path to filenames" -ForegroundColor Cyan }
Write-Host ""

$movedCount = 0
$collisionCount = 0

$files | ForEach-Object {
	if ($Prefix) {
		# Build a filename from the relative path: "Sub\Folder\file.jpg" -> "Sub_Folder_file.jpg"
		$relativePath = $_.FullName.Substring($resolvedPath.Length + 1)
		$newName = $relativePath -replace '[/\\]', '_'
	} else {
		$newName = $_.Name
	}

	$destination = Join-Path $resolvedPath $newName

	# Handle collisions
	if ((Test-Path $destination) -and ($destination -ne $_.FullName)) {
		$counter = 1
		$baseName = [System.IO.Path]::GetFileNameWithoutExtension($newName)
		$extension = [System.IO.Path]::GetExtension($newName)
		while (Test-Path $destination) {
			$newName = "${baseName}_$counter$extension"
			$destination = Join-Path $resolvedPath $newName
			$counter++
		}
		$collisionCount++
	}

	if ($PSCmdlet.ShouldProcess($_.FullName, "Move to '$destination'")) {
		Move-Item -Path $_.FullName -Destination $destination
		$movedCount++
	}
}

# Remove empty folders if requested
$removedFolders = 0
if ($RemoveEmptyFolders) {
	do {
		$emptyFolders = @(Get-ChildItem -Path $resolvedPath -Recurse -Directory |
			Where-Object { (Get-ChildItem -Path $_.FullName -Force).Count -eq 0 } |
			Sort-Object { $_.FullName.Length } -Descending)

		foreach ($folder in $emptyFolders) {
			if ($PSCmdlet.ShouldProcess($folder.FullName, "Remove empty folder")) {
				Remove-Item -Path $folder.FullName -Force
				$removedFolders++
			}
		}
	} while ($emptyFolders.Count -gt 0)
}

Write-Host ""
Write-Host "Done. Moved: $movedCount, Collisions resolved: $collisionCount" -ForegroundColor Green
if ($RemoveEmptyFolders) {
	Write-Host "Removed $removedFolders empty folder(s)." -ForegroundColor Green
}
