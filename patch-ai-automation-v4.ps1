# ============================================================
#  BTS — AI Automation v4
#  Removes Section 5 (Why BTS) — now redundant with
#  Section 4 (How we work) + Section 6 (UK + GCC advantage).
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

# ---- 2. Find Section 5 and Section 6 boundaries ---------------
$lines = Get-Content $file -Encoding UTF8
Write-Host ("Total lines before: {0}" -f $lines.Count) -ForegroundColor Cyan

# Find "Why BTS" section header and "UK + GCC advantage" header
$whyBtsIdx = -1
$ukGccIdx  = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($whyBtsIdx -lt 0 -and $lines[$i] -match '8\.\s*WHY BTS') { $whyBtsIdx = $i }
    if ($ukGccIdx  -lt 0 -and $lines[$i] -match 'UK \+ GCC advantage') { $ukGccIdx = $i }
}

if ($whyBtsIdx -lt 0) { throw "ABORT: could not find '8. WHY BTS' comment" }
if ($ukGccIdx  -lt 0) { throw "ABORT: could not find 'UK + GCC advantage' section" }

Write-Host ("Why BTS starts at line:       {0}" -f ($whyBtsIdx + 1)) -ForegroundColor Cyan
Write-Host ("UK + GCC starts at line:      {0}" -f ($ukGccIdx + 1)) -ForegroundColor Cyan

# ---- 3. Walk backwards from UK+GCC to find the section-9 comment ----
# The section 9 comment (`9. UK + GCC ADVANTAGE`) is a few lines above.
# Delete from the blank line before "8. WHY BTS" up to (but not
# including) the "9. UK + GCC" section comment.
$startDel = $whyBtsIdx - 1     # the blank line before the "8. WHY BTS" comment
# Find the "9. UK + GCC" comment line (usually 1–3 lines above section 9)
$endDel = $ukGccIdx
for ($i = $ukGccIdx; $i -ge $ukGccIdx - 10 -and $i -ge 0; $i--) {
    if ($lines[$i] -match '9\.\s*UK \+ GCC') { $endDel = $i; break }
}
if ($endDel -eq $ukGccIdx) {
    # Fallback: no section-9 comment found. Delete to the <section> line directly.
    for ($i = $ukGccIdx; $i -ge 0; $i--) {
        if ($lines[$i] -match '^\s*<!--') { $endDel = $i; break }
    }
}

Write-Host ("Deleting lines {0} through {1}" -f ($startDel + 1), $endDel) -ForegroundColor Yellow

# ---- 4. Sanity check: is the range what we expect? -----------
$rangeLen = $endDel - $startDel
if ($rangeLen -lt 5) {
    throw ("ABORT: range too small ({0} lines). Something is wrong." -f $rangeLen)
}
if ($rangeLen -gt 300) {
    throw ("ABORT: range too large ({0} lines). Something is wrong." -f $rangeLen)
}

# ---- 5. Delete the range -------------------------------------
$newLines = @()
if ($startDel -gt 0) { $newLines += $lines[0..($startDel - 1)] }
if ($endDel -lt $lines.Count - 1) { $newLines += $lines[$endDel..($lines.Count - 1)] }

Write-Host ("Total lines after:  {0}" -f $newLines.Count) -ForegroundColor Cyan
Write-Host ("Removed:            {0} lines" -f ($lines.Count - $newLines.Count)) -ForegroundColor Cyan

# ---- 6. Write back --------------------------------------------
$newLines -join "`r`n" | Set-Content $file -Encoding UTF8 -NoNewline

Write-Host ""
Write-Host "Why BTS section removed." -ForegroundColor Green
Write-Host ("Rollback: Copy-Item ""{0}"" ""{1}"" -Force" -f $backup, $file) -ForegroundColor Yellow