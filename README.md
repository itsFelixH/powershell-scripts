# PowerShell Scripts

A collection of useful PowerShell scripts for media file management and organization.

## Requirements

- PowerShell 5.1+
- [ffmpeg](https://ffmpeg.org/) (for conversion and frame extraction scripts)

## Scripts

| Script | Description |
|--------|-------------|
| `Compare-FolderContents.ps1` | Compares source and backup folders, reports missing files and size mismatches |
| `Convert-HeicToJpg.ps1` | Batch converts .heic/.heif files to .jpg (iPhone photos) |
| `Convert-JfifToJpg.ps1` | Batch converts .jfif files to .jpg |
| `Convert-WebpToJpg.ps1` | Batch converts .webp files to .jpg |
| `Export-VideoFrames.ps1` | Extracts evenly-spaced frames and keyframes from video files |
| `Find-BrokenMedia.ps1` | Detects corrupt or unreadable media files using ffprobe |
| `Flatten-Folder.ps1` | Moves all files from subfolders into one flat directory |
| `Get-FolderSize.ps1` | Displays folder sizes in a tree-like summary with visual bars |
| `Remove-DuplicateFiles.ps1` | Finds and removes duplicate files by SHA256 hash |
| `Remove-EmptyFolders.ps1` | Cleans up empty directories recursively |
| `Rename-FilesByDate.ps1` | Renames files using EXIF date or last modified timestamp |
| `Rename-FileWithFolderPrefix.ps1` | Prepends the parent folder name to each file |
| `Strip-ExifData.ps1` | Removes EXIF/metadata from images for privacy |
| `Sync-Folders.ps1` | One-way folder sync with mirror mode and exclude patterns |

## Usage

All scripts support `Get-Help` for detailed documentation:

```powershell
Get-Help .\Compare-FolderContents.ps1 -Full
```

### Compare-FolderContents

```powershell
.\Compare-FolderContents.ps1 -Source "D:\Photos" -Backup "E:\Photos-Backup"
```

### Convert-JfifToJpg / Convert-WebpToJpg

```powershell
.\Convert-JfifToJpg.ps1 -Path "D:\Downloads"
.\Convert-WebpToJpg.ps1 -Path "D:\Downloads"
```

### Export-VideoFrames

```powershell
.\Export-VideoFrames.ps1 -Path "D:\Videos" -NumFrames 12
```

### Convert-HeicToJpg

```powershell
.\Convert-HeicToJpg.ps1 -Path "D:\iPhone-Photos"
.\Convert-HeicToJpg.ps1 -Path "D:\Photos" -Quality 5
```

### Rename-FilesByDate

```powershell
# Rename all files to their date (2024-03-15_143022.jpg)
.\Rename-FilesByDate.ps1 -Path "D:\Photos" -Recurse

# Only rename .jpg files with custom format
.\Rename-FilesByDate.ps1 -Path "D:\Photos" -Filter "*.jpg" -Format "yyyyMMdd_HHmmss"
```

### Remove-DuplicateFiles

```powershell
# Dry run - just show duplicates
.\Remove-DuplicateFiles.ps1 -Path "D:\Photos" -WhatIf

# Delete duplicates (skip confirmation)
.\Remove-DuplicateFiles.ps1 -Path "D:\Photos" -Confirm:$false

# Move duplicates to a separate folder instead of deleting
.\Remove-DuplicateFiles.ps1 -Path "D:\Photos" -MoveTo "D:\Duplicates"
```

### Remove-EmptyFolders

```powershell
# Preview which folders would be removed
.\Remove-EmptyFolders.ps1 -Path "D:\Photos" -WhatIf

# Remove all empty folders (skip confirmation)
.\Remove-EmptyFolders.ps1 -Path "D:\Photos" -Confirm:$false
```

### Find-BrokenMedia

```powershell
# Scan and report broken files
.\Find-BrokenMedia.ps1 -Path "D:\Photos" -Recurse

# Move broken files to a separate folder
.\Find-BrokenMedia.ps1 -Path "D:\Photos" -Recurse -MoveTo "D:\Broken"
```

### Flatten-Folder

```powershell
# Move all files from subfolders into root
.\Flatten-Folder.ps1 -Path "D:\Photos"

# Flatten and clean up empty folders
.\Flatten-Folder.ps1 -Path "D:\Photos" -RemoveEmptyFolders

# Prefix subfolder names to avoid collisions
.\Flatten-Folder.ps1 -Path "D:\Photos" -Prefix
```

### Get-FolderSize

```powershell
# Quick overview of subfolder sizes
.\Get-FolderSize.ps1 -Path "D:\"

# Two levels deep, top 10 only
.\Get-FolderSize.ps1 -Path "D:\Projects" -Depth 2 -Top 10
```

### Strip-ExifData

```powershell
# Create clean copies without metadata (*_clean.jpg)
.\Strip-ExifData.ps1 -Path "D:\Photos\ToShare"

# Strip metadata in-place (overwrites originals)
.\Strip-ExifData.ps1 -Path "D:\Photos" -Recurse -Overwrite
```

### Rename-FileWithFolderPrefix

```powershell
# Preview changes without renaming
.\Rename-FileWithFolderPrefix.ps1 -Path "D:\Photos" -WhatIf

# Apply changes
.\Rename-FileWithFolderPrefix.ps1 -Path "D:\Photos"
```

### Sync-Folders

```powershell
# Copy new and changed files to backup (additive)
.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup\Photos"

# Full mirror: copy + delete files no longer in source
.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup\Photos" -Mirror

# Sync while excluding certain patterns
.\Sync-Folders.ps1 -Source "D:\Projects" -Destination "E:\Backup" -ExcludePattern "node_modules", "*.tmp", ".git"

# Log all operations to a file
.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup" -LogPath "D:\sync.log"

# Preview without making changes
.\Sync-Folders.ps1 -Source "D:\Photos" -Destination "E:\Backup" -WhatIf
```
