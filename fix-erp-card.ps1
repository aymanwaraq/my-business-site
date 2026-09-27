# ============================================================
#  Fix ERP & CRM card - line-based, no regex
# ============================================================

$ErrorActionPreference = "Stop"
$enFile = ".\services\system-integration.html"

# --- Backup ---
if (!(Test-Path ".\_backups")) { New-Item -ItemType Directory ".\_backups" | Out-Null }
$stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = ".\_backups\system-integration.html.$stamp.bak"
Copy-Item $enFile $backup -Force
Write-Host "Backup: $backup" -ForegroundColor Green

# --- Load ---
$lines = Get-Content $enFile -Encoding UTF8
Write-Host ("Total lines: {0}" -f $lines.Count) -ForegroundColor Cyan

# --- Find the ERP & CRM line by content (no punctuation assumptions) ---
$idx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match 'SAP.*Dynamics.*Odoo.*Zoho.*Salesforce') {
        $idx = $i
        break
    }
}

if ($idx -lt 0) {
    throw "Could not find the ERP line"
}

Write-Host ("Found at line: {0}" -f ($idx + 1)) -ForegroundColor Cyan
Write-Host ("Current: {0}" -f $lines[$idx].Trim()) -ForegroundColor Yellow

# --- Replace ---
$lines[$idx] = '        <p>ERP and CRM platforms including SAP, Microsoft Dynamics, Odoo, Salesforce and HubSpot — orders, customers, invoices and pipelines in sync.</p>'

# --- Write ---
$lines -join "`r`n" | Set-Content $enFile -Encoding UTF8 -NoNewline

Write-Host "EN page updated." -ForegroundColor Green
Write-Host ""
Write-Host "Verify with: Select-String -Path $enFile -Pattern 'including SAP'" -ForegroundColor Cyan