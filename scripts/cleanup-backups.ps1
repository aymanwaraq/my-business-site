# ============================================================
#  BTS - Clean up old backup files
#  Keeps the most recent N backups per base filename.
#  Deletes older ones.
# ============================================================

$ErrorActionPreference = "Continue"

# ─── Configuration ─────────────────────────────────────────
$keepPerFile = 5   # How many recent backups to keep per base name
$backupDir   = ".\_backups"

# ─── Verify backup folder exists ───────────────────────────
if (!(Test-Path $backupDir)) {
    Write-Host "_backups folder does not exist. Nothing to clean." -ForegroundColor Yellow
    exit 0
}

# ─── Get all backup files ──────────────────────────────────
$allBackups = Get-ChildItem "$backupDir\*" -File -ErrorAction SilentlyContinue

if ($allBackups.Count -eq 0) {
    Write-Host "_backups folder is empty. Nothing to clean." -ForegroundColor Yellow
    exit 0
}

Write-Host ("Found {0} backup files in {1}" -f $allBackups.Count, $backupDir) -ForegroundColor Cyan
Write-Host ""

# ─── Group by base name ────────────────────────────────────
# Strips timestamp suffixes so backups of the same source file
# are grouped together. Examples of what gets grouped:
#   ai-automation.html.20260927-004905.bak
#   ai-automation.html.refactor-20260927-093134.bak
#   ai-automation.html.pre-redesign-20260927-001224.bak
# all belong to the "ai-automation.html" group.

$grouped = @{}
foreach ($file in $allBackups) {
    # Remove common suffix patterns to find the base name
    $baseName = $file.Name
    $baseName = $baseName -replace '\.(refactor|pre-redesign|precleanup)-[\d\-]+\.bak$', '.bak'
    $baseName = $baseName -replace '\.\d{8}-\d{6}\.bak$', '.bak'
    $baseName = $baseName -replace '\.\d{8}-\d{6}\.bak$', '.bak'

    if (!$grouped.ContainsKey($baseName)) {
        $grouped[$baseName] = @()
    }
    $grouped[$baseName] += $file
}

# ─── Decide what to keep / delete ──────────────────────────
$toDelete = @()
$toKeep   = @()

foreach ($base in $grouped.Keys) {
    $files = $grouped[$base] | Sort-Object LastWriteTime -Descending
    $keep   = $files | Select-Object -First $keepPerFile
    $remove = $files | Select-Object -Skip $keepPerFile

    $toKeep   += $keep
    $toDelete += $remove
}

# ─── Report before deleting ────────────────────────────────
Write-Host ("Will keep:   {0} files" -f $toKeep.Count)   -ForegroundColor Green
Write-Host ("Will delete: {0} files" -f $toDelete.Count) -ForegroundColor Yellow
Write-Host ""

if ($toDelete.Count -eq 0) {
    Write-Host "Nothing to delete. All backups are within the keep threshold." -ForegroundColor Green
    exit 0
}

# ─── Show what will be deleted (dry run preview) ───────────
Write-Host "Preview of files to be deleted:" -ForegroundColor Cyan
$toDelete | Select-Object -First 20 | ForEach-Object {
    Write-Host ("  {0}  ({1})" -f $_.Name, $_.LastWriteTime.ToString("yyyy-MM-dd HH:mm"))
}
if ($toDelete.Count -gt 20) {
    Write-Host ("  ... and {0} more" -f ($toDelete.Count - 20)) -ForegroundColor Gray
}
Write-Host ""

# ─── Confirm before deleting ───────────────────────────────
$confirm = Read-Host "Delete these files? (y/n)"

if ($confirm -ne "y" -and $confirm -ne "Y") {
    Write-Host "Cancelled. Nothing was deleted." -ForegroundColor Yellow
    exit 0
}

# ─── Delete ────────────────────────────────────────────────
$deleted = 0
foreach ($file in $toDelete) {
    try {
        Remove-Item $file.FullName -Force
        $deleted++
    }
    catch {
        Write-Host ("Failed to delete {0}: {1}" -f $file.Name, $_.Exception.Message) -ForegroundColor Red
    }
}

Write-Host ""
Write-Host ("Deleted {0} old backup file(s)." -f $deleted) -ForegroundColor Green
Write-Host ("Kept {0} recent backup(s)." -f $toKeep.Count) -ForegroundColor Cyan