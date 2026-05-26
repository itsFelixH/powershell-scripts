[cmdletbinding(SupportsShouldProcess)]
param (
    [Parameter(Mandatory = $false)]
    [Alias('Path')]
    [String[]]$BasePath = "$PSScriptRoot"
)

# Wrap Get-ChildItem in parentheses to finish the scan before renaming begins.
# This prevents "moving target" errors in the pipeline.
(Get-ChildItem -Path $BasePath -File -Recurse) | ForEach-Object {
    $prefix = "$($_.Directory.Name) - "
    
    # Only rename if the file doesn't already start with the folder name prefix
    if (-not $_.Name.StartsWith($prefix)) {
        $newName = $prefix + $_.Name
        $_ | Rename-Item -NewName $newName
    }
}