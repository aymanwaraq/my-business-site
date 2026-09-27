# BTS Project Inspector
$here = (Get-Location).Path
if ($here -notlike "*aymankhalil-business-site*") {
    Write-Host "Wrong folder: $here" -ForegroundColor Red
    Write-Host "Run:  cd C:\Users\Admin\Documents\aymankhalil-business-site" -ForegroundColor Yellow
    return
}

function Show-Tree {
    param([string]$Path = ".", [string]$Indent = "")
    $items = Get-ChildItem -LiteralPath $Path -Force |
             Where-Object { $_.Name -notin @('.git','node_modules','.vscode') } |
             Sort-Object @{Expression={-not $_.PSIsContainer}}, Name
    for ($i = 0; $i -lt $items.Count; $i++) {
        $item    = $items[$i]
        $last    = ($i -eq $items.Count - 1)
        $branch  = if ($last) { "└── " } else { "├── " }
        $nextInd = $Indent + $(if ($last) { "    " } else { "│   " })
        if ($item.PSIsContainer) {
            $count = (Get-ChildItem -LiteralPath $item.FullName -Recurse -File -ErrorAction SilentlyContinue).Count
            Write-Host "$Indent$branch$($item.Name)/" -ForegroundColor Cyan -NoNewline
            Write-Host "  ($count files)" -ForegroundColor DarkGray
            Show-Tree -Path $item.FullName -Indent $nextInd
        } else {
            $kb = [math]::Round($item.Length / 1KB, 1)
            Write-Host "$Indent$branch$($item.Name)" -NoNewline
            Write-Host "  ${kb} KB" -ForegroundColor DarkGray
        }
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " BTS PROJECT STRUCTURE" -ForegroundColor Yellow
Write-Host " Root: $(Get-Location)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ""
Show-Tree -Path "."

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " SUMMARY" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

$allFiles = Get-ChildItem -Recurse -File -ErrorAction SilentlyContinue
$totalKB  = [math]::Round((($allFiles | Measure-Object Length -Sum).Sum / 1KB), 1)
$html = ($allFiles | Where-Object Extension -eq '.html').Count
$css  = ($allFiles | Where-Object Extension -eq '.css').Count
$js   = ($allFiles | Where-Object Extension -eq '.js').Count
$img  = ($allFiles | Where-Object Extension -in '.png','.jpg','.jpeg','.svg','.webp','.gif').Count

Write-Host ("  Total files : {0}" -f $allFiles.Count)
Write-Host ("  Total size  : {0} KB" -f $totalKB)
Write-Host ("  HTML        : {0}" -f $html)
Write-Host ("  CSS         : {0}" -f $css)
Write-Host ("  JS          : {0}" -f $js)
Write-Host ("  Images      : {0}" -f $img)

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " EXPECTED FILES CHECK" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

$expected = @(
  @{ Path='index.html';                              Desc='Auto language redirect' },
  @{ Path='en.html';                                 Desc='English homepage' },
  @{ Path='ar.html';                                 Desc='Arabic homepage (RTL)' },
  @{ Path='assets\css\style.css';                    Desc='Shared stylesheet' },
  @{ Path='assets\js\main.js';                       Desc='Shared behaviour' },
  @{ Path='services\ai-automation.html';             Desc='Service: AI Automation' },
  @{ Path='services\business-intelligence.html';     Desc='Service: Business Intelligence' },
  @{ Path='services\custom-software.html';           Desc='Service: Custom Software' },
  @{ Path='services\bilingual-systems.html';         Desc='Service: Bilingual Systems' },
  @{ Path='services\system-integration.html';        Desc='Service: System Integration' },
  @{ Path='services\digital-marketing.html';         Desc='Service: Digital Marketing' },
  @{ Path='locations\uk.html';                       Desc='Location: United Kingdom' },
  @{ Path='locations\ksa.html';                      Desc='Location: Saudi Arabia' },
  @{ Path='locations\uae.html';                      Desc='Location: UAE' },
  @{ Path='locations\qatar.html';                    Desc='Location: Qatar' },
  @{ Path='locations\oman.html';                     Desc='Location: Oman' },
  @{ Path='locations\kuwait.html';                   Desc='Location: Kuwait' },
  @{ Path='locations\bahrain.html';                  Desc='Location: Bahrain' },
  @{ Path='privacy-policy.html';                     Desc='Optional: Privacy' },
  @{ Path='terms-of-service.html';                   Desc='Optional: Terms' },
  @{ Path='sitemap.xml';                             Desc='Optional: Sitemap' },
  @{ Path='robots.txt';                              Desc='Optional: Robots' },
  @{ Path='.htaccess';                               Desc='Optional: Redirects' }
)

$ok = 0; $missing = 0; $optional = 0
foreach ($e in $expected) {
    if (Test-Path $e.Path) {
        Write-Host ("  [OK]      {0,-45} {1}" -f $e.Path, $e.Desc) -ForegroundColor Green
        $ok++
    } elseif ($e.Desc -like 'Optional*') {
        Write-Host ("  [NEXT]    {0,-45} {1}" -f $e.Path, $e.Desc) -ForegroundColor DarkYellow
        $optional++
    } else {
        Write-Host ("  [MISSING] {0,-45} {1}" -f $e.Path, $e.Desc) -ForegroundColor Red
        $missing++
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " UNEXPECTED FILES (leftover from old site)" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow

$expectedPaths = $expected | ForEach-Object { $_.Path.ToLower() }
$unexpected = $allFiles | Where-Object {
    $rel = Resolve-Path -Relative $_.FullName | ForEach-Object { $_.TrimStart('.\').ToLower() }
    $rel -notin $expectedPaths -and
    $_.Extension -notin @('.png','.jpg','.jpeg','.svg','.webp','.gif') -and
    $_.Name      -notlike 'btsapp-backup*' -and
    $_.Name      -ne 'inspect.ps1'
}

if ($unexpected.Count -eq 0) {
    Write-Host "  None - the tree is clean." -ForegroundColor Green
} else {
    $unexpected | ForEach-Object {
        Write-Host ("  {0}" -f (Resolve-Path -Relative $_.FullName)) -ForegroundColor Magenta
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host " RESULT" -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Yellow
Write-Host ("  Ready       : {0}" -f $ok)        -ForegroundColor Green
Write-Host ("  Missing     : {0}" -f $missing)   -ForegroundColor $(if ($missing -gt 0) { 'Red' } else { 'Green' })
Write-Host ("  To build    : {0}" -f $optional)  -ForegroundColor DarkYellow
Write-Host ("  Leftovers   : {0}" -f $unexpected.Count) -ForegroundColor $(if ($unexpected.Count -gt 0) { 'Magenta' } else { 'Green' })
Write-Host ""
