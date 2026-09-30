#Requires -Version 5.1
<#
    Scarica-Binari.ps1
    ------------------
    Scarica dai siti UFFICIALI i binari che AVVIA-Setup.cmd / Setup-LezioneAI.ps1
    si aspettano di trovare accanto a se (il repo non li contiene: sono grandi e
    ridistribuibili a parte).

    Scarica, con i nomi giusti:
      - PortableGit-*-64-bit.7z.exe      (git-for-windows/git, ultima release)
      - node-v*-win-x64.zip              (nodejs.org, ultima LTS)
      - opencode-windows-x64.zip         (sst/opencode, ultima release)
      - opencode-windows-x64-baseline.zip (idem, per CPU senza AVX2)
      - vscode-win32-x64.zip             (update.code.visualstudio.com, stable)

    Uso:
      powershell -ExecutionPolicy Bypass -File Scarica-Binari.ps1
      powershell -ExecutionPolicy Bypass -File Scarica-Binari.ps1 -Destinazione E:\Setup-Lezione-AI

    Per default scarica nella cartella di questo script. Poi copia TUTTO
    (script + binari) sulla chiavetta, insieme a AVVIA-Setup.cmd.
#>

[CmdletBinding()]
param(
    [string]$Destinazione = $PSScriptRoot,
    [switch]$SkipVSCode   # salta il file piu' grande (~330 MB) se non ti serve offline
)

$ErrorActionPreference = 'Stop'
$ProgressPreference     = 'SilentlyContinue'   # velocizza molto Invoke-WebRequest
New-Item -ItemType Directory -Force -Path $Destinazione | Out-Null

function Get-File {
    param([string]$Url, [string]$OutName)
    $out = Join-Path $Destinazione $OutName
    if (Test-Path $out) {
        Write-Host "  [gia presente] $OutName" -ForegroundColor DarkGray
        return
    }
    Write-Host "  scarico $OutName ..." -ForegroundColor Cyan
    $tmp = "$out.parziale"
    Invoke-WebRequest -Uri $Url -OutFile $tmp -UseBasicParsing
    Move-Item $tmp $out -Force
    Write-Host ("    OK ({0:N1} MB)" -f ((Get-Item $out).Length/1MB)) -ForegroundColor Green
}

function Get-GitHubAsset {
    param([string]$Repo, [string]$Pattern, [string]$OutName)
    $rel = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" `
        -Headers @{ 'User-Agent' = 'kit-lezione-ai' } -UseBasicParsing
    $asset = $rel.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
    if (-not $asset) { throw "Asset '$Pattern' non trovato nell'ultima release di $Repo" }
    Get-File -Url $asset.browser_download_url -OutName $OutName
}

Write-Host "`n=== Scarico i binari in: $Destinazione ===`n" -ForegroundColor White

# 1. PortableGit (nome esatto dell'asset, es. PortableGit-2.55.0.5-64-bit.7z.exe)
Write-Host "Git (PortableGit)" -ForegroundColor White
$rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/git-for-windows/git/releases/latest' `
    -Headers @{ 'User-Agent' = 'kit-lezione-ai' } -UseBasicParsing
$gitAsset = $rel.assets | Where-Object { $_.name -like 'PortableGit-*-64-bit.7z.exe' } | Select-Object -First 1
if (-not $gitAsset) { throw 'PortableGit non trovato nella release di git-for-windows.' }
Get-File -Url $gitAsset.browser_download_url -OutName $gitAsset.name

# 2. Node.js LTS
Write-Host "Node.js (LTS)" -ForegroundColor White
$idx = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' -UseBasicParsing
$lts = ($idx | Where-Object { $_.lts } | Select-Object -First 1).version   # es. v24.21.0
Get-File -Url "https://nodejs.org/dist/$lts/node-$lts-win-x64.zip" -OutName "node-$lts-win-x64.zip"

# 3. opencode (x64 + baseline)
Write-Host "opencode" -ForegroundColor White
Get-GitHubAsset -Repo 'sst/opencode' -Pattern 'opencode-windows-x64.zip'          -OutName 'opencode-windows-x64.zip'
Get-GitHubAsset -Repo 'sst/opencode' -Pattern 'opencode-windows-x64-baseline.zip' -OutName 'opencode-windows-x64-baseline.zip'

# 4. VS Code portable (il piu' grande)
if (-not $SkipVSCode) {
    Write-Host "Visual Studio Code (portable)" -ForegroundColor White
    Get-File -Url 'https://update.code.visualstudio.com/latest/win32-x64-archive/stable' -OutName 'vscode-win32-x64.zip'
} else {
    Write-Host "Visual Studio Code saltato (-SkipVSCode)" -ForegroundColor DarkGray
}

Write-Host "`n=== FATTO ===" -ForegroundColor Green
Write-Host "Contenuto di $Destinazione :" -ForegroundColor White
Get-ChildItem $Destinazione | Sort-Object Length -Descending |
    Select-Object Name, @{n='MB';e={[math]::Round($_.Length/1MB,1)}} | Format-Table -AutoSize
Write-Host "Ora copia TUTTO (script + binari + i file in ..\docs se vuoi) sulla chiavetta." -ForegroundColor Yellow
