#Requires -Version 5.1

<#
.SYNOPSIS
	Displays folder sizes in a tree-like summary.

.DESCRIPTION
	Scans a directory and shows the size of each immediate subfolder,
	sorted by size descending. Provides a quick overview of disk usage
	similar to WinDirStat or TreeSize.

.PARAMETER Path
	Folder to analyze. Defaults to the current directory.

.PARAMETER Depth
	How many levels deep to report. Defaults to 1 (immediate subfolders only).

.PARAMETER Top
	Show only the top N largest folders. Defaults to showing all.

.PARAMETER IncludeFiles
	Also list individual files in the root alongside folder sizes.

.EXAMPLE
	.\Get-FolderSize.ps1 -Path "D:\"

	Shows size of each folder on D: drive.

.EXAMPLE
	.\Get-FolderSize.ps1 -Path "D:\Projects" -Depth 2

	Shows two levels of folder sizes.

.EXAMPLE
	.\Get-FolderSize.ps1 -Path "C:\Users" -Top 10

	Shows only the 10 largest folders.
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $false)]
	[ValidateScript({ Test-Path $_ -PathType Container })]
	[string]$Path = ".",

	[Parameter(Mandatory = $false)]
	[ValidateRange(1, 10)]
	[int]$Depth = 1,

	[Parameter(Mandatory = $false)]
	[int]$Top = 0,

	[Parameter(Mandatory = $false)]
	[switch]$IncludeFiles
)

function Format-Size {
	param([long]$Bytes)
	if ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
	if ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
	if ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
	return "$Bytes B"
}

function Get-DirectorySize {
	param([string]$DirPath)
	$size = (Get-ChildItem -Path $DirPath -Recurse -File -ErrorAction SilentlyContinue |
		Measure-Object -Property Length -Sum).Sum
	if (-not $size) { $size = 0 }
	return $size
}

function Show-FolderTree {
	param(
		[string]$FolderPath,
		[int]$CurrentDepth,
		[int]$MaxDepth,
		[string]$Indent = ""
	)

	$subfolders = Get-ChildItem -Path $FolderPath -Directory -ErrorAction SilentlyContinue

	$folderSizes = $subfolders | ForEach-Object {
		[PSCustomObject]@{
			Name     = $_.Name
			FullName = $_.FullName
			Size     = Get-DirectorySize $_.FullName
		}
	} | Sort-Object Size -Descending

	if ($Top -gt 0 -and $CurrentDepth -eq 1) {
		$folderSizes = $folderSizes | Select-Object -First $Top
	}

	foreach ($folder in $folderSizes) {
		$sizeFormatted = Format-Size $folder.Size
		$bar = ""

		# Simple visual bar for top level
		if ($CurrentDepth -eq 1 -and $script:totalSize -gt 0) {
			$percentage = [math]::Round(($folder.Size / $script:totalSize) * 100, 1)
			$barLength = [math]::Max(1, [math]::Round($percentage / 2))
			$bar = " [{0}] {1}%" -f ("█" * $barLength), $percentage
		}

		Write-Host "${Indent}$($folder.Name)" -ForegroundColor Cyan -NoNewline
		Write-Host "  $sizeFormatted" -ForegroundColor White -NoNewline
		Write-Host "$bar" -ForegroundColor DarkGray

		if ($CurrentDepth -lt $MaxDepth) {
			Show-FolderTree -FolderPath $folder.FullName -CurrentDepth ($CurrentDepth + 1) -MaxDepth $MaxDepth -Indent "$Indent  "
		}
	}
}

$resolvedPath = (Resolve-Path $Path).Path

Write-Host "Analyzing '$resolvedPath'..."
Write-Host ""

# Calculate total size
$script:totalSize = Get-DirectorySize $resolvedPath
$totalFormatted = Format-Size $script:totalSize

# Count files
$totalFiles = (Get-ChildItem -Path $resolvedPath -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
$totalFolders = (Get-ChildItem -Path $resolvedPath -Recurse -Directory -ErrorAction SilentlyContinue | Measure-Object).Count

Write-Host "Total size: $totalFormatted ($totalFiles files, $totalFolders folders)" -ForegroundColor Green
Write-Host ("-" * 60)

Show-FolderTree -FolderPath $resolvedPath -CurrentDepth 1 -MaxDepth $Depth

# Show root-level files if requested
if ($IncludeFiles) {
	$rootFiles = Get-ChildItem -Path $resolvedPath -File | Sort-Object Length -Descending
	if ($rootFiles.Count -gt 0) {
		Write-Host ""
		Write-Host "Files in root:" -ForegroundColor DarkGray
		$rootFiles | ForEach-Object {
			$sizeFormatted = Format-Size $_.Length
			Write-Host "  $($_.Name)  $sizeFormatted" -ForegroundColor DarkGray
		}
	}
}

Write-Host ("-" * 60)
Write-Host "Total: $totalFormatted" -ForegroundColor Green
