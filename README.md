# PowerShell Scripts

A collection of useful PowerShell scripts for media file management and organization.

## Requirements

- PowerShell 5.1+
- [ffmpeg](https://ffmpeg.org/) (for conversion and frame extraction scripts)

## Scripts

| Script | Description |
|--------|-------------|
| `Compare-FolderContents.ps1` | Compares source and backup folders, reports missing files and size mismatches |
| `Convert-JfifToJpg.ps1` | Batch converts .jfif files to .jpg |
| `Convert-WebpToJpg.ps1` | Batch converts .webp files to .jpg |
| `Export-VideoFrames.ps1` | Extracts evenly-spaced frames and keyframes from video files |
| `Rename-FileWithFolderPrefix.ps1` | Prepends the parent folder name to each file |

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

### Rename-FileWithFolderPrefix

```powershell
# Preview changes without renaming
.\Rename-FileWithFolderPrefix.ps1 -Path "D:\Photos" -WhatIf

# Apply changes
.\Rename-FileWithFolderPrefix.ps1 -Path "D:\Photos"
```
