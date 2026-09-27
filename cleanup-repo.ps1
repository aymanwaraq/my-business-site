# ============================================================
#  BTS - Repo cleanup before the final push
#  1) Backs up current state
#  2) Adds ignore rules
#  3) Stops tracking backup files
#  4) Deletes patch scripts
# ============================================================

$ErrorActionPreference = "Stop"

Write-Host "=== BTS Repo Cleanup ===" -ForegroundColor Cyan
Write-Host ""

# ---- 1. Backup the current .gitignore ------------------------
if (Test-Path ".gitignore") {
    Copy-Item ".gitignore" ".gitignore.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force
    Write-Host "Backed up .gitignore" -ForegroundColor Green
} else {
    New-Item -ItemType File ".gitignore" | Out-Null
    Write-Host "Created .gitignore" -ForegroundColor Green
}

# ---- 2. Append ignore rules ----------------------------------
$ignoreRules = @"

# --- BTS added: dev artifacts ---
_backups/
*.bak
*.backup-*
*.pretighten-*
*.ps1
"@

Add-Content -Path ".gitignore" -Value $ignoreRules -Encoding UTF8
Write-Host "Added ignore rules to .gitignore" -ForegroundColor Green

# ---- 3. Stop tracking backup files ---------------------------
Write-Host ""
Write-Host "Removing tracked backup files from git index..." -ForegroundColor Yellow

# _backups folder
if (Test-Path ".\_backups") {
    git rm -r --cached --quiet .\_backups 2>$null
    Write-Host "  - _backups/ untracked" -ForegroundColor Gray
}

# Any .bak files anywhere
$bakFiles = git ls-files | Select-String -Pattern '\.bak$'
foreach ($f in $bakFiles) {
    git rm --cached --quiet $f.ToString().Trim() 2>$null
}
if ($bakFiles) { Write-Host "  - *.bak files untracked" -ForegroundColor Gray }

# Any .backup-* files
$backupFiles = git ls-files | Select-String -Pattern '\.backup-'
foreach ($f in $backupFiles) {
    git rm --cached --quiet $f.ToString().Trim() 2>$null
}
if ($backupFiles) { Write-Host "  - *.backup-* files untracked" -ForegroundColor Gray }

# Any .pretighten-* files
$pretightenFiles = git ls-files | Select-String -Pattern '\.pretighten-'
foreach ($f in $pretightenFiles) {
    git rm --cached --quiet $f.ToString().Trim() 2>$null
}
if ($pretightenFiles) { Write-Host "  - *.pretighten-* files untracked" -ForegroundColor Gray }

# ---- 4. Delete patch scripts ---------------------------------
Write-Host ""
Write-Host "Removing patch scripts..." -ForegroundColor Yellow

$scriptsToRemove = @(
    "patch-ai-automation.ps1",
    "patch-ai-automation-v2.ps1",
    "patch-ai-automation-v3.ps1",
    "patch-ai-automation-v4.ps1",
    "patch-system-integration.ps1",
    "fix-erp-card.ps1",
    "inspect.ps1"
)

foreach ($s in $scriptsToRemove) {
    if (Test-Path $s) {
        git rm --cached --quiet $s 2>$null
        Remove-Item $s -Force
        Write-Host "  - Removed $s" -ForegroundColor Gray
    }
}

# ---- 5. Show status ------------------------------------------
Write-Host ""
Write-Host "=== Status ===" -ForegroundColor Cyan
git status --short

Write-Host ""
Write-Host "Done. Review the status above, then commit with:" -ForegroundColor Green
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  git commit -m 'Clean repo: remove backups and dev scripts'" -ForegroundColor White