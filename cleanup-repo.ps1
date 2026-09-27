# ============================================================
#  BTS - Repo cleanup before final push
#  Stops tracking backups + deletes patch scripts.
# ============================================================

$ErrorActionPreference = "Continue"

Write-Host "=== REPO CLEANUP ===" -ForegroundColor Cyan
Write-Host ""

# --- Backup current .gitignore --------------------------------
if (Test-Path ".gitignore") {
    Copy-Item ".gitignore" ".gitignore.precleanup-$(Get-Date -Format 'yyyyMMdd-HHmmss')" -Force
    Write-Host "Backed up existing .gitignore" -ForegroundColor Green
}

# --- Append ignore rules --------------------------------------
$rules = @"

# --- BTS: dev artifacts ---
_backups/
*.bak
*.backup-*
*.pretighten-*
*.precleanup-*
*.pre-redesign-*
patch-*.ps1
inspect.ps1
fix-*.ps1
cleanup-*.ps1
"@

Add-Content -Path ".gitignore" -Value $rules -Encoding UTF8
Write-Host "Updated .gitignore" -ForegroundColor Green

# --- Stop tracking _backups folder ----------------------------
Write-Host ""
Write-Host "Untracking _backups/ folder..." -ForegroundColor Yellow
if (Test-Path ".\_backups") {
    git rm -r --cached --quiet .\_backups 2>$null
    Write-Host "  Done" -ForegroundColor Gray
}

# --- Stop tracking loose backup files -------------------------
Write-Host ""
Write-Host "Untracking loose backup files..." -ForegroundColor Yellow

$tracked = git ls-files
$toUntrack = $tracked | Where-Object {
    $_ -match '\.bak$' -or
    $_ -match '\.backup-' -or
    $_ -match '\.pretighten-' -or
    $_ -match '\.pre-redesign-' -or
    $_ -match '\.precleanup-'
}

if ($toUntrack) {
    foreach ($f in $toUntrack) {
        git rm --cached --quiet $f 2>$null
    }
    Write-Host ("  Untracked {0} file(s)" -f $toUntrack.Count) -ForegroundColor Gray
} else {
    Write-Host "  None found" -ForegroundColor Gray
}

# --- Delete patch scripts from disk ---------------------------
Write-Host ""
Write-Host "Removing patch scripts..." -ForegroundColor Yellow

$scriptsToRemove = @(
    "patch-ai-automation.ps1",
    "patch-ai-automation-v2.ps1",
    "patch-ai-automation-v3.ps1",
    "patch-ai-automation-v4.ps1",
    "patch-system-integration.ps1",
    "fix-erp-card.ps1",
    "fix-hero-stats.ps1",
    "inspect.ps1"
)

foreach ($s in $scriptsToRemove) {
    if (Test-Path $s) {
        git rm --cached --quiet $s 2>$null
        Remove-Item $s -Force
        Write-Host "  Removed $s" -ForegroundColor Gray
    }
}

# --- Verify service pages still exist -------------------------
Write-Host ""
Write-Host "Verifying service pages still intact..." -ForegroundColor Yellow
$expected = @(
    ".\services\ai-automation.html",
    ".\services\ai-automation.ar.html",
    ".\services\business-intelligence.html",
    ".\services\business-intelligence.ar.html",
    ".\services\custom-software.html",
    ".\services\custom-software.ar.html",
    ".\services\bilingual-systems.html",
    ".\services\bilingual-systems.ar.html",
    ".\services\system-integration.html",
    ".\services\system-integration.ar.html",
    ".\services\logistics-warehouse.html",
    ".\services\logistics-warehouse.ar.html"
)
$allOk = $true
foreach ($f in $expected) {
    if (!(Test-Path $f)) {
        Write-Host "  MISSING: $f" -ForegroundColor Red
        $allOk = $false
    }
}
if ($allOk) {
    Write-Host "  All 12 service pages intact." -ForegroundColor Green
}

# --- Show current status --------------------------------------
Write-Host ""
Write-Host "=== GIT STATUS (summary) ===" -ForegroundColor Cyan
git status --short | Group-Object { $_.Substring(0,2) } | ForEach-Object {
    Write-Host ("  {0} : {1} file(s)" -f $_.Name, $_.Count) -ForegroundColor Gray
}

Write-Host ""
Write-Host "Cleanup complete." -ForegroundColor Green
Write-Host ""
Write-Host "Next: review 'git status --short' output, then commit with:" -ForegroundColor Cyan
Write-Host "  git add -A" -ForegroundColor White
Write-Host "  git commit -m 'Clean repo: stop tracking backups, remove dev scripts'" -ForegroundColor White