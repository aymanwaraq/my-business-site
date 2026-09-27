# ============================================================
#  BTS - Soften ERP-CRM vendor card on System Integration page
# ============================================================

$ErrorActionPreference = "Stop"

function Replace-Once {
    param([string]$Content,[string]$Pattern,[string]$Replacement,[string]$Label)
    if ($Content -notmatch $Pattern) { throw "ANCHOR NOT FOUND: $Label" }
    return [regex]::Replace($Content, $Pattern, $Replacement, 1)
}

function Backup-File {
    param([string]$Path)
    if (!(Test-Path ".\_backups")) {
        New-Item -ItemType Directory ".\_backups" | Out-Null
    }
    $stamp  = Get-Date -Format "yyyyMMdd-HHmmss"
    $name   = Split-Path $Path -Leaf
    $backup = ".\_backups\$name.$stamp.bak"
    Copy-Item $Path $backup -Force
    Write-Host "Backup: $backup" -ForegroundColor Green
}

# --- EN page -----------------------------------------------------
$enFile = ".\services\system-integration.html"

if (Test-Path $enFile) {
    Backup-File $enFile
    $en = Get-Content $enFile -Raw -Encoding UTF8

    $en = Replace-Once $en `
        '<p>SAP, Microsoft Dynamics, Odoo, Zoho, Salesforce, HubSpot — orders, customers, invoices and pipelines in sync\.</p>' `
        '<p>ERP and CRM platforms including SAP, Microsoft Dynamics, Odoo, Salesforce and HubSpot — orders, customers, invoices and pipelines in sync.</p>' `
        "EN ERP-CRM card"

    Set-Content $enFile $en -Encoding UTF8 -NoNewline
    Write-Host "EN page updated." -ForegroundColor Green
} else {
    Write-Host "EN page not found - skipping." -ForegroundColor Yellow
}

# --- AR page (skip if not yet created) ---------------------------
$arFile = ".\services\system-integration.ar.html"

if (Test-Path $arFile) {
    Backup-File $arFile
    $ar = Get-Content $arFile -Raw -Encoding UTF8

    $ar = Replace-Once $ar `
        '<p>SAP وMicrosoft Dynamics وOdoo وZoho وSalesforce وHubSpot — طلبات وعملاء وفواتير وصفقات متزامنة\.</p>' `
        '<p>منصات ERP وCRM تشمل SAP وMicrosoft Dynamics وOdoo وSalesforce وHubSpot — طلبات وعملاء وفواتير وصفقات متزامنة.</p>' `
        "AR ERP-CRM card"

    Set-Content $arFile $ar -Encoding UTF8 -NoNewline
    Write-Host "AR page updated." -ForegroundColor Green
} else {
    Write-Host "AR page not yet created - will use softened wording from the start." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green