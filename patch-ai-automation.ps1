# ============================================================
#  BTS — AI Automation page refinement (v3)
# ============================================================

$ErrorActionPreference = "Stop"
$file = ".\services\ai-automation.html"

# ---- 1. Back up ------------------------------------------------
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

# ---- 3. Remove Section 10 (BTS Labs) + its <style> block ------
$html = Replace-Once $html `
    '(?s)<section class="bts-section light" id="labs">.*?</style>' `
    '' `
    "Remove Section 10 (BTS Labs) block"
Write-Host "Step 3 OK" -ForegroundColor Green

# ---- 4. Fix hero secondary CTA --------------------------------
$html = Replace-Once $html `
    '<a href="#labs" class="btn btn-outline">See BTS Labs</a>' `
    '<a href="#how" class="btn btn-outline">See how it works</a>' `
    "Hero secondary CTA -> #how"
Write-Host "Step 4 OK" -ForegroundColor Green

# ---- 5. Add id="how" to Section 4 -----------------------------
$html = Replace-Once $html `
    '(?s)(<section class="bts-section light">)(\s*<div class="container">\s*<div class="bts-head">\s*<span class="rule"></span>\s*<span class="kicker">How it works</span>)' `
    '<section class="bts-section light" id="how">$2' `
    "Add id=how to Section 4"
Write-Host "Step 5 OK" -ForegroundColor Green

# ---- 6. Preconnect to fonts.gstatic.com -----------------------
$html = Replace-Once $html `
    '(<link rel="preconnect" href="https://fonts\.googleapis\.com">)' `
    '$1
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>' `
    "Add preconnect fonts.gstatic.com"
Write-Host "Step 6 OK" -ForegroundColor Green

# ---- 7. Focus-visible styles + polish (string-insert, no regex) ----
$polish = @'

/* ─── Accessibility: keyboard focus on CTAs ───────────────────── */
.bts-hero-cta a:focus-visible,
.bts-product-cta:focus-visible,
.bts-hero-eyebrow:focus-visible,
.btn:focus-visible {
  outline: 2px solid #FFD770;
  outline-offset: 3px;
  border-radius: 4px;
}

/* ─── Decorative SVGs in CTAs ─────────────────────────────────── */
.bts-product-cta svg { pointer-events: none; }
'@

$headEnd = $html.IndexOf('</head>')
if ($headEnd -lt 0) { throw "ANCHOR NOT FOUND: </head>" }
$lastStyle = $html.Substring(0, $headEnd).LastIndexOf('</style>')
if ($lastStyle -lt 0) { throw "ANCHOR NOT FOUND: last </style> before </head>" }
$html = $html.Substring(0, $lastStyle) + $polish + "`n</style>" + $html.Substring($headEnd)
Write-Host "Step 7 OK" -ForegroundColor Green

# ---- 8. Add aria-hidden to arrow SVGs -------------------------
$html = $html -replace '(<a class="bts-product-cta"[^>]*>\s*Request a demo on WhatsApp\s*)<svg viewBox="0 0 24 24">', '$1<svg viewBox="0 0 24 24" aria-hidden="true">'
Write-Host "Step 8 OK" -ForegroundColor Green

# ---- 9. Write back --------------------------------------------
Set-Content $file $html -Encoding UTF8 -NoNewline

Write-Host "`nAll changes applied." -ForegroundColor Green
Write-Host "Rollback: Copy-Item '$backup' '$file' -Force" -ForegroundColor Yellow