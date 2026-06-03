#Requires -Version 5.1

<#
.SYNOPSIS
	One-way folder sync from source to destination.

.DESCRIPTION
	Copies new and updated files from source to destination. Compares files by
	last modified date and size. Optionally removes files from the destination
	that no longer exist in the source (mirror mode).

	Does NOT modify the source folder.

.PARAMETER Source
	Path to the source folder (the "truth").

.PARAMETER Destination
	Path to the destination folder (the copy to update).
	Will be created if it doesn't exist.

.PARAMETER Mirror
	Remove files from destination that don't exist in source.
	Without this flag, only new/updated files are copied (additive sync).
	Prompts for confirmation before deleting.

.PARAMETER ExcludePattern
	Array of wildcard patterns to exclude (e.g. "*.tmp", "Thumbs.db").
	Patterns are matched against each path segment and the full relative path.

.EXAMPLE
	.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup\Photos"

	Copies new and changed files from D:\Photos to E:\Backup\Photos.

.EXAMPLE
	.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup\Photos" -Mirror

	Full mirror: copies new/changed files AND removes files from destination
	that no longer exist in source.

.EXAMPLE
	.\Sync-Folders.ps1 -Source "D:\Projects" -Destination "E:\Backup" -ExcludePattern "node_modules", "*.tmp", ".git"

	Syncs while skipping node_modules, tmp files, and .git folders.

.EXAMPLE
	.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup" -WhatIf

	Preview all operations without making changes.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
	[Parameter(Mandatory)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Source,

	[Parameter(Mandatory)]
	[ValidateScript({
		if (Test-Path $_ -PathType Leaf) { throw "Destination must be a folder, not a file: $_" }
		return $true
	})]
	[string]$Destination,

	[Parameter(Mandatory = $false)]
	[switch]$Mirror,

	[Parameter(Mandatory = $false)]
	[string[]]$ExcludePattern
)

function Format-Size {
	param([long]$Bytes)
	if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
	if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
	if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
	return "$Bytes B"
}

function Test-Excluded {
	param(
		[string]$RelativePath,
		[string[]]$Patterns
	)
	if (-not $Patterns) { return $false }
	foreach ($pattern in $Patterns) {
		$segments = $RelativePath -split '[/\\]'
		foreach ($segment in $segments) {
			if ($segment -like $pattern) { return $true }
		}
		if ($RelativePath -like $pattern) { return $true }
	}
	return $false
}

# Resolve source path (trim trailing separator for consistent substring math)
$Source = (Resolve-Path $Source).Path.TrimEnd('\', '/')

# Create destination if it doesn't exist
if (-not (Test-Path $Destination)) {
	New-Item -ItemType Directory -Path $Destination -Force | Out-Null
	Write-Host "Created destination: $Destination" -ForegroundColor Cyan
}
$Destination = (Resolve-Path $Destination).Path.TrimEnd('\', '/')

Write-Host "Source:      $Source"
Write-Host "Destination: $Destination"
Write-Host "Mode:        $(if ($Mirror) { 'Mirror (copy + delete)' } else { 'Additive (copy only)' })"
if ($ExcludePattern) { Write-Host "Excluding:   $($ExcludePattern -join ', ')" }
Write-Host ""

# Get all source files with relative paths
$sourceFiles = Get-ChildItem -Path $Source -Recurse -File | ForEach-Object {
	$relativePath = $_.FullName.Substring($Source.Length + 1)
	[PSCustomObject]@{
		RelativePath  = $relativePath
		FullName      = $_.FullName
		Length        = $_.Length
		LastWriteTime = $_.LastWriteTime
	}
} | Where-Object { -not (Test-Excluded -RelativePath $_.RelativePath -Patterns $ExcludePattern) }

# Get all destination files with relative paths
$destFiles = @{}
Get-ChildItem -Path $Destination -Recurse -File | ForEach-Object {
	$relativePath = $_.FullName.Substring($Destination.Length + 1)
	if (-not (Test-Excluded -RelativePath $relativePath -Patterns $ExcludePattern)) {
		$destFiles[$relativePath] = [PSCustomObject]@{
			RelativePath  = $relativePath
			FullName      = $_.FullName
			Length        = $_.Length
			LastWriteTime = $_.LastWriteTime
		}
	}
}

$copiedCount = 0
$updatedCount = 0
$deletedCount = 0
$skippedCount = 0
$failedCount = 0
$copiedBytes = 0

# Copy new and updated files
foreach ($file in $sourceFiles) {
	$destPath = Join-Path $Destination $file.RelativePath

	if ($destFiles.ContainsKey($file.RelativePath)) {
		$destFile = $destFiles[$file.RelativePath]

		# Skip if same size and destination is same age or newer
		if ($destFile.Length -eq $file.Length -and $destFile.LastWriteTime -ge $file.LastWriteTime) {
			$skippedCount++
			continue
		}

		# File exists but is outdated or different size
		if ($PSCmdlet.ShouldProcess($file.RelativePath, "Update (size: $(Format-Size $file.Length))")) {
			try {
				$destDir = Split-Path $destPath -Parent
				if (-not (Test-Path $destDir)) {
					New-Item -ItemType Directory -Path $destDir -Force | Out-Null
				}
				Copy-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
				Write-Host "  Updated: $($file.RelativePath)" -ForegroundColor Yellow
				$updatedCount++
				$copiedBytes += $file.Length
			} catch {
				Write-Host "  FAILED:  $($file.RelativePath) - $($_.Exception.Message)" -ForegroundColor Red
				$failedCount++
			}
		}
	} else {
		# New file
		if ($PSCmdlet.ShouldProcess($file.RelativePath, "Copy (size: $(Format-Size $file.Length))")) {
			try {
				$destDir = Split-Path $destPath -Parent
				if (-not (Test-Path $destDir)) {
					New-Item -ItemType Directory -Path $destDir -Force | Out-Null
				}
				Copy-Item -Path $file.FullName -Destination $destPath -Force -ErrorAction Stop
				Write-Host "  Copied:  $($file.RelativePath)" -ForegroundColor Green
				$copiedCount++
				$copiedBytes += $file.Length
			} catch {
				Write-Host "  FAILED:  $($file.RelativePath) - $($_.Exception.Message)" -ForegroundColor Red
				$failedCount++
			}
		}
	}
}

# Mirror mode: remove files from destination that don't exist in source
if ($Mirror) {
	$sourceLookup = @{}
	$sourceFiles | ForEach-Object { $sourceLookup[$_.RelativePath] = $true }

	$toDelete = @($destFiles.Keys | Where-Object { -not $sourceLookup.ContainsKey($_) })

	if ($toDelete.Count -gt 0) {
		Write-Host ""
		Write-Host "  $($toDelete.Count) file(s) in destination not in source." -ForegroundColor DarkGray

		if ($PSCmdlet.ShouldProcess("$($toDelete.Count) file(s) no longer in source", "Delete from destination")) {
			foreach ($relativePath in $toDelete) {
				$fullPath = Join-Path $Destination $relativePath
				try {
					Remove-Item -Path $fullPath -Force -ErrorAction Stop
					Write-Host "  Deleted: $relativePath" -ForegroundColor Red
					$deletedCount++
				} catch {
					Write-Host "  FAILED:  Could not delete $relativePath - $($_.Exception.Message)" -ForegroundColor Red
					$failedCount++
				}
			}

			# Clean up empty folders after deletions
			do {
				$emptyFolders = @(Get-ChildItem -Path $Destination -Recurse -Directory |
					Where-Object { (Get-ChildItem -Path $_.FullName -Force).Count -eq 0 })
				foreach ($folder in $emptyFolders) {
					Remove-Item -Path $folder.FullName -Force
				}
			} while ($emptyFolders.Count -gt 0)
		}
	}
}

# Summary
Write-Host ""
Write-Host ("-" * 50)
Write-Host "Done." -ForegroundColor Green
Write-Host "  Copied:  $copiedCount new file(s)" -ForegroundColor Green
Write-Host "  Updated: $updatedCount changed file(s)" -ForegroundColor Yellow
if ($Mirror) {
	Write-Host "  Deleted: $deletedCount file(s)" -ForegroundColor Red
}
Write-Host "  Skipped: $skippedCount unchanged file(s)" -ForegroundColor DarkGray
if ($failedCount -gt 0) {
	Write-Host "  Failed:  $failedCount file(s)" -ForegroundColor Red
}
Write-Host "  Data transferred: $(Format-Size $copiedBytes)"
