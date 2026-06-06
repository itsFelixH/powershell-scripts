# PowerShell Scripts Collection

A collection of utility scripts for media conversion, folder synchronization, and file maintenance.

## Getting Started

Before running these scripts, ensure your PowerShell environment is configured to allow local script execution:

```powershell
# Run this in an elevated PowerShell session or for your current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Folder Structure

- **Media/**: Scripts for converting and processing media files.
  - `Convert-MediaFormat.ps1`: Smart conversion to JPG/MP4 (supports remuxing).
  - `Convert-VideoToHevc.ps1`: Batch compress videos to H.265/HEVC (10-bit).
  - `Convert-VideoToX264.ps1`: Batch compress videos to H.264 (high compatibility).
  - `Convert-HeicToJpg.ps1`: Batch convert HEIC to JPG.
  - `Convert-WebpToJpg.ps1`: Batch convert WebP to JPG.
  - `Repair-FileExtension.ps1`: Fix corrupted suffixes and normalize extensions.
  - `Export-VideoFrames.ps1`: Extract still frames from videos.
  - `Find-BrokenMedia.ps1`: Identify corrupt image/video files.
  - `Rename-FilesByDate.ps1`: Rename files based on EXIF/Metadata date.
  - `Strip-ExifData.ps1`: Remove private metadata from images.
- **Backup/**: Tools for one-way synchronization and verifying backup consistency.
  - `Sync-Folders.ps1`: Robust folder synchronization.
  - `Compare-FolderContents.ps1`: Verify source/destination parity.
- **Maintenance/**: General file system cleanup tools, such as duplicate file removal.
  - `Remove-DuplicateFiles.ps1`: Find and remove duplicates via hashing.
  - `Flatten-Folder.ps1`: Move all files from subfolders to the root.
  - `Rename-FileWithFolderPrefix.ps1`: Prepend folder names to files.
  - `Remove-EmptyFolders.ps1`: Clean up empty directory trees.
  - `Get-FolderSize.ps1`: Analyze and display disk usage summaries.

## Dependencies

### PowerShell
Scripts are compatible with **PowerShell 5.1** (Windows PowerShell) and **PowerShell 7+** (Core).

### FFmpeg
The `Media/` toolset requires **FFmpeg** and **ffprobe**. To verify if they are installed and in your system PATH, run:

```powershell
ffmpeg -version
ffprobe -version
```

## Usage

Most scripts support standard PowerShell parameters like `-WhatIf` (to preview changes) and `-Confirm`. For detailed documentation on any script, use `Get-Help`:

```powershell
Get-Help .\Media\Convert-HeicToJpg.ps1 -Full
```
