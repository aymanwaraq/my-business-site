# ============================================================
#  BTS - Refactor shared CSS out of service pages
# ============================================================

$ErrorActionPreference = "Stop"

$servicePages = @(
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

if (!(Test-Path ".\_backups")) {
    New-Item -ItemType Directory ".\_backups" | Out-Null
}
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

$processed = 0
$skipped   = 0
$errors    = @()

foreach ($f in $servicePages) {
    if (!(Test-Path $f)) {
        Write-Host ("SKIP (not found): {0}" -f $f) -ForegroundColor Yellow
        $skipped++
        continue
    }

    try {
        $content  = Get-Content $f -Raw -Encoding UTF8
        $original = $content

        # 1. Backup
        $name   = Split-Path $f -Leaf
        $backup = ".\_backups\$name.refactor-$stamp.bak"
        Copy-Item $f $backup -Force

        # 2. Add <link> to services.css if not already present
        if ($content -notmatch 'assets/css/services\.css') {
            $insert = '<link rel="stylesheet" href="../assets/css/style.css">' + "`r`n" + '<link rel="stylesheet" href="../assets/css/services.css">'
            $content = $content -replace '<link rel="stylesheet" href="\.\./assets/css/style\.css">', $insert
        }

        # 3. Remove inline <style>...</style> block
        $pattern = '(?s)\s*<style>.*?</style>\s*</head>'
        if ($content -match $pattern) {
            $content = $content -replace $pattern, "`r`n</head>"
        }

        # 4. Write back if changed
        if ($content -ne $original) {
            Set-Content $f $content -Encoding UTF8 -NoNewline
            Write-Host ("UPDATED: {0}" -f $f) -ForegroundColor Green
            $processed++
        } else {
            Write-Host ("NO CHANGE: {0}" -f $f) -ForegroundColor Gray
        }
    }
    catch {
        Write-Host ("ERROR on {0}: {1}" -f $f, $_.Exception.Message) -ForegroundColor Red
        $errors += $f
    }
}

Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ("Processed: {0}" -f $processed) -ForegroundColor Green
Write-Host ("Skipped:   {0}" -f $skipped) -ForegroundColor Yellow
Write-Host ("Errors:    {0}" -f $errors.Count) -ForegroundColor Red
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "Verify one file:" -ForegroundColor Cyan
Write-Host '  Get-Content .\services\ai-automation.html -TotalCount 25' -ForegroundColor White
Write-Host ""
Write-Host ("Backup timestamp: {0}" -f $stamp) -ForegroundColor Cyan