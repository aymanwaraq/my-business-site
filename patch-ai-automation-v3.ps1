# ============================================================
#  BTS — AI Automation v3
#  Deletes lines 712..926 (Sections 5, 6, 7 + surrounding blanks)
#  Uses line-based deletion — no regex, no Unicode ambiguity.
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

# ---- 2. Read all lines ----------------------------------------
$lines = Get-Content $file -Encoding UTF8
Write-Host ("Total lines before: {0}" -f $lines.Count) -ForegroundColor Cyan

# ---- 3. Safety check: confirm anchors at expected lines -------
if ($lines[712] -notmatch '5\. REAL WORKFLOWS') {
    throw ("ABORT: expected '5. REAL WORKFLOWS' at line 713, found: {0}" -f $lines[712])
}
if ($lines[927] -notmatch '8\. WHY BTS') {
    throw ("ABORT: expected '8. WHY BTS' at line 928, found: {0}" -f $lines[927])
}
Write-Host "Anchors verified at lines 713 and 928." -ForegroundColor Green

# ---- 4. Delete lines 712..926 (0-indexed: 711..925) ----------
# Keep lines 0..710 (up to and including line 711: </section>)
# Then skip 711..925 (which is lines 712..926)
# Then resume at 926 (which is line 927: blank line before Section 8)
$newLines = @()
$newLines += $lines[0..710]
$newLines += $lines[926..($lines.Count - 1)]

Write-Host ("Total lines after:  {0}" -f $newLines.Count) -ForegroundColor Cyan
Write-Host ("Removed:            {0} lines" -f ($lines.Count - $newLines.Count)) -ForegroundColor Cyan

# ---- 5. Write back --------------------------------------------
$newLines -join "`r`n" | Set-Content $file -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Sections 5, 6, 7 removed." -ForegroundColor Green
Write-Host ("Rollback: Copy-Item ""{0}"" ""{1}"" -Force" -f $backup, $file) -ForegroundColor Yellow