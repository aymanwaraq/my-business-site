# ============================================================
#  BTS — AI Automation page v3
#  Removes Sections 5 (Real workflows), 6 (Before/With BTS),
#  and 7 (Business outcomes).
# ============================================================

$ErrorActionPreference = "Stop"
$file = ".\services\ai-automation.html"

# ---- 1. Back up -----------------------------------------------
if (!(Test-Path ".\_backups")) {
    New-Item -ItemType Directory ".\_backups" | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = ".\_backups\ai-automation.$stamp.bak"
Copy-Item $file $backup -Force
Write-Host "Backup: $backup" -ForegroundColor Green

# ---- 2. Guarded replace helper --------------------------------
function Replace-Once {
    param([string]$Content,[string]$Pattern,[string]$Replacement,[string]$Label)
    if ($Content -notmatch $Pattern) { throw "ANCHOR NOT FOUND: $Label" }
    return [regex]::Replace($Content, $Pattern, $Replacement, 1)
}

$html = Get-Content $file -Raw -Encoding UTF8

# ---- 3. Remove Sections 5, 6, 7 in one pass -------------------
$pattern = '(?s)<section class="bts-section navy">\s*<div class="container">\s*<div class="bts-head">\s*<span class="rule"></span>\s*<span class="kicker">Real workflows, working products</span>.*?(?=<!-- ═+ 8\. WHY BTS ═+ -->)'
if ($html -notmatch $pattern) {
    throw "ANCHOR NOT FOUND: Sections 5+6+7 block"
}
$html = [regex]::Replace($html, $pattern, '', 1)
Write-Host "Step 3 OK - Sections 5, 6, 7 removed" -ForegroundColor Green

# ---- 4. Write back -------------------------------------------
Set-Content $file $html -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "All changes applied." -ForegroundColor Green
Write-Host ("Rollback: Copy-Item ""{0}"" ""{1}"" -Force" -f $backup, $file) -ForegroundColor Yellow