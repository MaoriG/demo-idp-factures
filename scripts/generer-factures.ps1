# Régénère les 4 factures PDF de test depuis les sources HTML
# Prérequis : Microsoft Edge (présent sur Windows 10/11)
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
if (-not (Test-Path $edge)) { $edge = 'C:\Program Files\Microsoft\Edge\Application\msedge.exe' }
$src = Join-Path $PSScriptRoot '..\sources-html'
$dst = Join-Path $PSScriptRoot '..\factures'
New-Item -ItemType Directory -Force $dst | Out-Null
Get-ChildItem "$src\*.html" | ForEach-Object {
    $pdf = Join-Path $dst ($_.BaseName + '.pdf')
    & $edge --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="$pdf" ("file:///" + ($_.FullName -replace '\\','/')) 2>$null
    Start-Sleep -Milliseconds 800
    Write-Host "OK : $pdf"
}
