# Prepends the parent folder name to each file's name.
# Usage: .\add-foldername-to-filename.ps1 -Path "C:\path\to\folder"
# Example: Photos\Vacation\img001.jpg -> Photos\Vacation\Vacation - img001.jpg

[cmdletbinding(SupportsShouldProcess)]
param (
	[Parameter(Mandatory = $false)]
	[Alias('Path')]
	[String[]]$BasePath = "$PSScriptRoot"
)

# Validate path
if (-not (Test-Path $BasePath)) {
	Write-Host "ERROR: Path not found: $BasePath" -ForegroundColor Red
	exit 1
}

# Wrap Get-ChildItem in parentheses to finish the scan before renaming begins.
# This prevents "moving target" errors in the pipeline.
$files = @(Get-ChildItem -Path $BasePath -File -Recurse)
$totalFiles = $files.Count
$renamedCount = 0
$skippedCount = 0

Write-Host "Found $totalFiles file(s) in '$BasePath'"

$files | ForEach-Object {
	$prefix = "$($_.Directory.Name) - "

	# Only rename if the file doesn't already start with the folder name prefix
	if (-not $_.Name.StartsWith($prefix)) {
		$newName = $prefix + $_.Name
		$_ | Rename-Item -NewName $newName
		$renamedCount++
	} else {
		$skippedCount++
	}
}

Write-Host ""
Write-Host "Done. Renamed: $renamedCount, Skipped (already prefixed): $skippedCount" -ForegroundColor Green
