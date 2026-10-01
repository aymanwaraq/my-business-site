# ============================================================
#  BTS - Add floating WhatsApp button to all pages
#  Targets: services/*.html and locations/*.html
#  - Backs up each file before modifying
#  - Skips files that already have the button
#  - Inserts the button HTML just before </body>
#  - Injects the CSS once per file into the <head> <style> block
# ============================================================

$ErrorActionPreference = "Continue"

# ─── 1. Backup folder ───────────────────────────────────────
$backupDir = ".\_backups"
if (!(Test-Path $backupDir)) {
    New-Item -ItemType Directory $backupDir | Out-Null
    Write-Host "Created $backupDir" -ForegroundColor Green
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"

# ─── 2. Collect target files ────────────────────────────────
$files = @()
$files += Get-ChildItem ".\services\*.html" -File -ErrorAction SilentlyContinue
$files += Get-ChildItem ".\locations\*.html" -File -ErrorAction SilentlyContinue

if ($files.Count -eq 0) {
    Write-Host "No HTML files found in .\services\ or .\locations\" -ForegroundColor Red
    exit 1
}

Write-Host ("Found {0} HTML files to process." -f $files.Count) -ForegroundColor Cyan
Write-Host ""

# ─── 3. HTML snippet — the button itself ────────────────────
$buttonHtml = @'
<!-- ─── Floating WhatsApp button ─── -->
<a href="https://wa.me/447425252625"
   class="whatsapp-float"
   target="_blank"
   rel="noopener"
   aria-label="Chat with BTS on WhatsApp"
   title="WhatsApp BTS">
  <svg viewBox="0 0 24 24" aria-hidden="true">
    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413Z"/>
  </svg>
</a>
'@

# ─── 4. CSS snippet — styles the button ─────────────────────
$buttonCss = @'

/* ═══════════════════════════════════════════════════════════
   Floating WhatsApp button — injected by add-whatsapp-button.ps1
   ═══════════════════════════════════════════════════════════ */
.whatsapp-float {
  position: fixed;
  bottom: 90px;
  inset-inline-end: 24px;
  z-index: 91;
  width: 56px;
  height: 56px;
  border-radius: 50%;
  background: #25D366;
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 8px 24px rgba(37, 211, 102, 0.35);
  transition: transform .2s ease, box-shadow .2s ease;
}
.whatsapp-float:hover {
  transform: translateY(-2px) scale(1.05);
  box-shadow: 0 12px 32px rgba(37, 211, 102, 0.5);
}
.whatsapp-float:focus-visible {
  outline: 2px solid #FFD770;
  outline-offset: 3px;
}
.whatsapp-float svg {
  width: 26px;
  height: 26px;
  fill: currentColor;
}
@media (max-width: 640px) {
  .whatsapp-float {
    width: 52px;
    height: 52px;
    bottom: 82px;
    inset-inline-end: 16px;
  }
  .whatsapp-float svg { width: 24px; height: 24px; }
}
'@

# ─── 5. Process each file ───────────────────────────────────
$processed = 0
$skipped   = 0
$errored   = 0

foreach ($file in $files) {
    try {
        $content = Get-Content $file.FullName -Raw -Encoding UTF8

        # Skip if button already present
        if ($content -match 'whatsapp-float') {
            Write-Host ("SKIP (already has button): {0}" -f $file.Name) -ForegroundColor Gray
            $skipped++
            continue
        }

        # Require a closing </body> tag
        if ($content -notmatch '</body>') {
            Write-Host ("SKIP (no </body> tag): {0}" -f $file.Name) -ForegroundColor Yellow
            $skipped++
            continue
        }

        # Backup
        $backup = Join-Path $backupDir ($file.Name + ".pre-whatsapp-" + $stamp + ".bak")
        Copy-Item $file.FullName $backup -Force

        # 1. Insert the CSS into the last </style> block if one exists
        if ($content -match '(?s)</style>') {
            # Find the LAST </style> in the file (the page-level <style> block)
            $lastStyleIdx = $content.LastIndexOf('</style>')
            if ($lastStyleIdx -gt 0) {
                $content = $content.Substring(0, $lastStyleIdx) + $buttonCss + "`r`n" + $content.Substring($lastStyleIdx)
            }
        } else {
            # No <style> block — create one right before </head>
            $headCloseIdx = $content.IndexOf('</head>')
            if ($headCloseIdx -gt 0) {
                $newStyle = "<style>" + $buttonCss + "`r`n</style>`r`n"
                $content = $content.Substring(0, $headCloseIdx) + $newStyle + $content.Substring($headCloseIdx)
            }
        }

        # 2. Insert the button HTML right before </body>
        $bodyCloseIdx = $content.LastIndexOf('</body>')
        if ($bodyCloseIdx -gt 0) {
            $content = $content.Substring(0, $bodyCloseIdx) + "`r`n" + $buttonHtml + "`r`n" + $content.Substring($bodyCloseIdx)
        }

        # Write back
        Set-Content $file.FullName $content -Encoding UTF8 -NoNewline
        Write-Host ("UPDATED: {0}" -f $file.Name) -ForegroundColor Green
        $processed++

    } catch {
        Write-Host ("ERROR on {0}: {1}" -f $file.Name, $_.Exception.Message) -ForegroundColor Red
        $errored++
    }
}

# ─── 6. Summary ─────────────────────────────────────────────
Write-Host ""
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ("Processed: {0}" -f $processed) -ForegroundColor Green
Write-Host ("Skipped:   {0}" -f $skipped)   -ForegroundColor Yellow
Write-Host ("Errors:    {0}" -f $errored)   -ForegroundColor Red
Write-Host "════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host ("Backups saved to .\_backups\*.pre-whatsapp-{0}.bak" -f $stamp) -ForegroundColor Cyan