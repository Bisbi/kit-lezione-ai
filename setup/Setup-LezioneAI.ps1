#Requires -Version 5.1
<#
    Setup-LezioneAI.ps1
    -------------------
    Prepara un PC Windows per la lezione di IA con opencode.

    Gira come UTENTE NORMALE (niente UAC): tutto finisce nel profilo di chi
    ha fatto l'accesso al PC (Documenti, PATH utente, chiave opencode).

    Per OGNI componente controlla prima se c'e' gia (PATH + cartelle di installazione
    tipiche) e installa solo se manca. Nel log: "gia presente, NON lo installo [percorso]".

    Cosa fa (idempotente: si puo rilanciare senza danni):
      1. Git     -> gia presente | PortableGit dalla chiavetta | winget (utente) | download
      2. Node.js -> gia presente | zip dalla chiavetta         | winget          | download
      3. opencode -> gia presente | zip ufficiale dalla chiavetta (x64 o baseline) | npm i -g opencode-ai
      4. PATH utente (git, node, npm globale, herdr)
      5. VS Code portable in lezioni-AI\vscode
      6. Herdr in lezioni-AI\herdr
      7. Lanciatori + collegamenti in Documenti\lezioni-AI (impostano il PATH da soli)

    File attesi accanto allo script (sulla chiavetta), tutti facoltativi:
      PortableGit-*-64-bit.7z.exe, node-v*-win-x64.zip, vscode-win32-x64.zip,
      opencode-windows-x64.zip, opencode-windows-x64-baseline.zip
#>

[CmdletBinding()]
param(
    [switch]$SkipVSCode,
    [switch]$SkipHerdr,
    [switch]$SkipAuth
)

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'   # Invoke-WebRequest/Expand-Archive molto piu veloci
$Kit = $PSScriptRoot

# ---------------------------------------------------------------------------
# Controllo profilo: lo script deve girare come l'utente che ha fatto l'accesso
# ---------------------------------------------------------------------------
$Me = [Security.Principal.WindowsIdentity]::GetCurrent().Name
$Console = $null
try { $Console = (Get-CimInstance Win32_ComputerSystem).UserName } catch {}
if ($Console -and ($Console -ne $Me)) {
    Write-Host ''
    Write-Host '  ATTENZIONE: lo script sta girando come un altro utente.' -ForegroundColor Red
    Write-Host "    Utente collegato al PC : $Console" -ForegroundColor Yellow
    Write-Host "    Utente dello script    : $Me" -ForegroundColor Yellow
    Write-Host '  I file finirebbero nel profilo sbagliato. Chiudi e rilancia' -ForegroundColor White
    Write-Host '  AVVIA-Setup.cmd con doppio clic (NON "Esegui come amministratore").' -ForegroundColor White
    exit 1
}

# ---------------------------------------------------------------------------
# Percorsi base (tutti nel profilo dell'utente corrente)
# ---------------------------------------------------------------------------
$Documents = [Environment]::GetFolderPath('MyDocuments')
$Base      = Join-Path $Documents 'lezioni-AI'
$Progetti  = Join-Path $Base 'progetti'
$Tools     = Join-Path $Base 'strumenti'
$GitDir    = Join-Path $Tools 'git'
$NodeDir   = Join-Path $Tools 'node'
$OcDir     = Join-Path $Tools 'opencode'
$VSCodeDir = Join-Path $Base 'vscode'
$HerdrDir  = Join-Path $Base 'herdr'
$NpmGlobal = Join-Path $env:APPDATA 'npm'
$LogFile   = Join-Path $Base 'setup-log.txt'

# ---------------------------------------------------------------------------
# Utilita
# ---------------------------------------------------------------------------
function Write-Step  { param($m) Write-Host "`n==> $m" -ForegroundColor Cyan;   Add-Content $LogFile "==> $m" }
function Write-Ok    { param($m) Write-Host "    [OK] $m" -ForegroundColor Green; Add-Content $LogFile "[OK] $m" }
function Write-Info  { param($m) Write-Host "    $m" -ForegroundColor Gray;       Add-Content $LogFile "    $m" }
function Write-Warn2 { param($m) Write-Host "    [!] $m" -ForegroundColor Yellow; Add-Content $LogFile "[!] $m" }

function Have-Command { param($name) [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Find-KitFile {
    # Primo file della chiavetta che corrisponde al nome (es. 'node-v*-win-x64.zip')
    param([string]$Pattern)
    $f = Get-ChildItem -Path $Kit -Filter $Pattern -File -ErrorAction SilentlyContinue |
         Sort-Object Name -Descending | Select-Object -First 1
    if ($f) { return $f.FullName } else { return $null }
}

function Find-Herdr {
    # Cerca herdr.exe: prima nella cartella lezioni-AI, poi nella posizione predefinita, poi nel PATH
    $hit = Get-ChildItem -Path $HerdrDir -Recurse -Filter 'herdr.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($hit) { return $hit.FullName }
    $def = Join-Path $env:LOCALAPPDATA 'Programs\Herdr\bin\herdr.exe'
    if (Test-Path $def) { return $def }
    $c = Get-Command herdr.exe -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    return $null
}

function Refresh-Path {
    $m = [Environment]::GetEnvironmentVariable('Path','Machine')
    $u = [Environment]::GetEnvironmentVariable('Path','User')
    $env:Path = (($m,$u) -join ';')
}

function Find-Existing {
    # Cerca un programma GIA installato: prima nel PATH (solo .exe/.cmd, mai .ps1),
    # poi nelle cartelle di installazione tipiche. Restituisce il percorso o $null.
    param([string]$Name, [string[]]$Candidates = @())
    $c = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { return $c.Source }
    foreach ($p in $Candidates) { if ($p -and (Test-Path $p)) { return $p } }
    return $null
}

function Add-ToUserPath {
    # -First: mette la cartella IN TESTA al PATH utente (serve per opencode: il suo .exe
    # deve vincere su opencode.ps1 di npm, bloccato se gli script sono disabilitati)
    param([string]$Dir, [switch]$First)
    if (-not $Dir -or -not (Test-Path $Dir)) { return }
    $cur = [Environment]::GetEnvironmentVariable('Path','User')
    if ($null -eq $cur) { $cur = '' }
    $parts = $cur -split ';' | Where-Object { $_ -ne '' }
    if ($First) {
        if ($parts.Count -gt 0 -and $parts[0] -eq $Dir) { Write-Info "Gia in testa al PATH utente: $Dir"; Refresh-Path; return }
        $parts = @($Dir) + @($parts | Where-Object { $_ -ne $Dir })
        [Environment]::SetEnvironmentVariable('Path', ($parts -join ';'), 'User')
        Write-Ok "Messo in testa al PATH utente: $Dir"
        Refresh-Path
        return
    }
    $mach = ([Environment]::GetEnvironmentVariable('Path','Machine') -split ';') | ForEach-Object { $_.TrimEnd('\') }
    if ($mach -contains $Dir.TrimEnd('\')) { Write-Info "Gia nel PATH di sistema: $Dir"; return }
    if ($parts -notcontains $Dir) {
        [Environment]::SetEnvironmentVariable('Path', (($parts + $Dir) -join ';'), 'User')
        Write-Ok "Aggiunto al PATH utente: $Dir"
    } else {
        Write-Info "Gia nel PATH utente: $Dir"
    }
    Refresh-Path
}

function Get-WingetPath {
    # winget puo non essere nel PATH ma esistere sotto WindowsApps
    $c = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    $stub = Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'
    if (Test-Path $stub) { return $stub }
    return $null
}

function Try-Winget {
    # Riserva: non blocca mai lo script. Restituisce $true se winget ha finito senza errori.
    param([string]$Id, [string]$FriendlyName, [string[]]$Extra = @())
    $wg = Get-WingetPath
    if (-not $wg) { Write-Info "winget non disponibile su questo PC: salto."; return $false }
    Write-Info "Provo winget per $FriendlyName ($Id)..."
    try {
        & $wg install --id $Id -e --source winget --accept-package-agreements --accept-source-agreements --silent @Extra 2>&1 | Out-Null
        $ok = ($LASTEXITCODE -eq 0)
    } catch { $ok = $false }
    Refresh-Path
    if (-not $ok) { Write-Warn2 "winget non e riuscito a installare $FriendlyName (codice $LASTEXITCODE)." }
    return $ok
}

function Install-PortableGit {
    param([string]$Exe)
    # PortableGit e un archivio 7-Zip autoestraente: -o<cartella> -y
    New-Item -ItemType Directory -Force -Path $GitDir | Out-Null
    Start-Process -FilePath $Exe -ArgumentList "-o`"$GitDir`"", '-y' -Wait -WindowStyle Hidden
    if (Test-Path (Join-Path $GitDir 'cmd\git.exe')) {
        # post-install di PortableGit (crea /etc, collegamenti interni); se manca non e grave
        $pi = Join-Path $GitDir 'post-install.bat'
        if (Test-Path $pi) { Start-Process -FilePath $pi -WorkingDirectory $GitDir -Wait -WindowStyle Hidden }
        return $true
    }
    return $false
}

function Test-Avx2 {
    # opencode "x64" richiede AVX2; sui PC vecchi serve la versione "baseline"
    try {
        if (-not ('K32.Cpu' -as [type])) {
            Add-Type -Namespace K32 -Name Cpu -MemberDefinition '[DllImport("kernel32.dll")] public static extern bool IsProcessorFeaturePresent(uint f);'
        }
        return [K32.Cpu]::IsProcessorFeaturePresent(40)   # PF_AVX2_INSTRUCTIONS_AVAILABLE
    } catch { return $true }
}

function Test-OpencodeExe {
    param([string]$Exe)
    if (-not (Test-Path $Exe)) { return $false }
    try { $null = (& $Exe --version) 2>&1; return ($LASTEXITCODE -eq 0) } catch { return $false }
}

function Install-NodeZip {
    param([string]$Zip)
    $tmp = Join-Path $Tools '_node-tmp'
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    Expand-Archive -Path $Zip -DestinationPath $tmp -Force
    $inner = Get-ChildItem $tmp -Directory | Select-Object -First 1   # node-vXX-win-x64
    Remove-Item $NodeDir -Recurse -Force -ErrorAction SilentlyContinue
    Move-Item $inner.FullName $NodeDir
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
    return (Test-Path (Join-Path $NodeDir 'node.exe'))
}

# ---------------------------------------------------------------------------
# 0. Cartelle base
# ---------------------------------------------------------------------------
New-Item -ItemType Directory -Force -Path $Base, $Progetti, $Tools | Out-Null
Set-Content -Path $LogFile -Value "Setup lezioni-AI - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - utente $Me" -Encoding utf8
Write-Host "`n===================================================" -ForegroundColor White
Write-Host "  SETUP LEZIONE IA  ->  $Base" -ForegroundColor White
Write-Host "  Utente: $Me" -ForegroundColor White
Write-Host "===================================================" -ForegroundColor White

# ---------------------------------------------------------------------------
# 0b. PowerShell: permette gli script per QUESTO utente (niente admin).
#     Senza, "opencode" in PowerShell/VS Code fallisce su opencode.ps1 di npm
#     ("L'esecuzione di script e disabilitata nel sistema in uso").
# ---------------------------------------------------------------------------
Write-Step 'Criterio di esecuzione di PowerShell (utente)'
try {
    if ((Get-ExecutionPolicy -Scope CurrentUser) -notin @('RemoteSigned','Unrestricted','Bypass')) {
        Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    }
    Write-Ok "CurrentUser = $(Get-ExecutionPolicy -Scope CurrentUser)"
} catch {
    Write-Warn2 "Non riesco a cambiarlo (criteri di gruppo?): $($_.Exception.Message)"
}
$eff = Get-ExecutionPolicy
if ($eff -in @('Restricted','AllSigned')) {
    Write-Warn2 "Criterio effettivo ancora '$eff' (imposto dalla scuola): in PowerShell usare 'opencode.cmd' oppure Herdr/Git Bash."
}

# ---------------------------------------------------------------------------
# 1. Git (Git Bash)
# ---------------------------------------------------------------------------
Refresh-Path   # legge il PATH aggiornato dal registro (la finestra potrebbe averne uno vecchio)

Write-Step 'Controllo Git (Git Bash)'
$gitExe = Find-Existing 'git.exe' @(
    (Join-Path $GitDir 'cmd\git.exe'),
    "$env:ProgramFiles\Git\cmd\git.exe",
    "${env:ProgramFiles(x86)}\Git\cmd\git.exe",
    "$env:LOCALAPPDATA\Programs\Git\cmd\git.exe")
if ($gitExe) {
    Add-ToUserPath (Split-Path $gitExe -Parent)
    Write-Ok "Git gia presente, NON lo installo: $((& $gitExe --version) 2>&1)  [$gitExe]"
} else {
    $done = $false
    $pg = Find-KitFile 'PortableGit-*-64-bit.7z.exe'
    if ($pg) {
        Write-Info "Estraggo Git portable dalla chiavetta in $GitDir ..."
        $done = Install-PortableGit $pg
    }
    if (-not $done) { $done = Try-Winget -Id 'Git.Git' -FriendlyName 'Git for Windows' -Extra @('--scope','user') }
    if (-not $done) {
        try {
            Write-Info 'Scarico Git portable da GitHub...'
            $rel = Invoke-RestMethod 'https://api.github.com/repos/git-for-windows/git/releases/latest' -UseBasicParsing
            $a = $rel.assets | Where-Object { $_.name -like 'PortableGit-*-64-bit.7z.exe' } | Select-Object -First 1
            $dl = Join-Path $env:TEMP $a.name
            Invoke-WebRequest $a.browser_download_url -OutFile $dl -UseBasicParsing
            $done = Install-PortableGit $dl
            Remove-Item $dl -Force -ErrorAction SilentlyContinue
        } catch { Write-Warn2 "Download di Git fallito: $($_.Exception.Message)" }
    }
    if (Test-Path (Join-Path $GitDir 'cmd\git.exe')) { Add-ToUserPath (Join-Path $GitDir 'cmd') }
    if (Have-Command git) { Write-Ok "Git installato: $((git --version) 2>&1)" }
    else { Write-Warn2 'Git NON installato: controlla i messaggi sopra.' }
}

# Individua bash.exe (serve per il collegamento di Herdr)
$BashExe = $null
$gitNow = Find-Existing 'git.exe'
foreach ($p in @(
        $(if ($gitNow) { Join-Path (Split-Path (Split-Path $gitNow -Parent) -Parent) 'bin\bash.exe' }),
        (Join-Path $GitDir 'bin\bash.exe'),
        "$env:ProgramFiles\Git\bin\bash.exe",
        "${env:ProgramFiles(x86)}\Git\bin\bash.exe",
        "$env:LOCALAPPDATA\Programs\Git\bin\bash.exe")) {
    if ($p -and (Test-Path $p)) { $BashExe = $p; break }
}
$GitCmdDir = $null
if ($BashExe) {
    $GitCmdDir = Join-Path (Split-Path (Split-Path $BashExe -Parent) -Parent) 'cmd'
    Add-ToUserPath $GitCmdDir
    Write-Info "bash.exe: $BashExe"
} else {
    Write-Warn2 'bash.exe non trovato: il collegamento a Herdr usera cmd come ripiego.'
}

# ---------------------------------------------------------------------------
# 2. Node.js / npm
# ---------------------------------------------------------------------------
Write-Step 'Controllo Node.js / npm'
$nodeCand = @(
    (Join-Path $NodeDir 'node.exe'),
    "$env:ProgramFiles\nodejs\node.exe",
    "$env:LOCALAPPDATA\Programs\nodejs\node.exe")
if ($env:NVM_SYMLINK) { $nodeCand += (Join-Path $env:NVM_SYMLINK 'node.exe') }
$nodeExe = Find-Existing 'node.exe' $nodeCand
$npmCmd  = if ($nodeExe) { Join-Path (Split-Path $nodeExe -Parent) 'npm.cmd' } else { $null }
if ($nodeExe -and (Test-Path $npmCmd)) {
    Add-ToUserPath (Split-Path $nodeExe -Parent)
    Write-Ok "Node/npm gia presenti, NON li installo: $((& $nodeExe -v) 2>&1) / npm $((& $npmCmd -v) 2>&1)  [$nodeExe]"
} else {
    if ($nodeExe) { Write-Warn2 "Trovato node.exe ma senza npm accanto ($nodeExe): installo Node completo in lezioni-AI." }
    $done = $false
    $nz = Find-KitFile 'node-v*-win-x64.zip'
    if ($nz) {
        Write-Info "Estraggo Node.js dalla chiavetta in $NodeDir ..."
        $done = Install-NodeZip $nz
    }
    if (-not $done) {
        try {
            Write-Info 'Scarico Node.js LTS (zip) da nodejs.org...'
            $idx = Invoke-RestMethod 'https://nodejs.org/dist/index.json' -UseBasicParsing
            $lts = @($idx | Where-Object { $_.lts -ne $false })[0].version
            $dl  = Join-Path $env:TEMP "node-$lts-win-x64.zip"
            Invoke-WebRequest "https://nodejs.org/dist/$lts/node-$lts-win-x64.zip" -OutFile $dl -UseBasicParsing
            $done = Install-NodeZip $dl
            Remove-Item $dl -Force -ErrorAction SilentlyContinue
        } catch { Write-Warn2 "Download di Node fallito: $($_.Exception.Message)" }
    }
    if ($done) { Add-ToUserPath $NodeDir }
    else { $null = Try-Winget -Id 'OpenJS.NodeJS.LTS' -FriendlyName 'Node.js LTS' }
    if (Have-Command npm) { Write-Ok "Node installato: $((node -v) 2>&1) / npm $((npm -v) 2>&1)" }
    else { Write-Warn2 'Node/npm NON installato: controlla i messaggi sopra.' }
}
$NodeExeDir = $null
$nc = Get-Command node.exe -ErrorAction SilentlyContinue
if ($nc) { $NodeExeDir = Split-Path $nc.Source -Parent }

# Cartella dei binari globali di npm (li finisce opencode), sempre nel profilo utente
New-Item -ItemType Directory -Force -Path $NpmGlobal | Out-Null
Add-ToUserPath $NpmGlobal
if (Have-Command npm) { try { npm config set prefix "$NpmGlobal" --location=user 2>&1 | Out-Null } catch {} }

# ---------------------------------------------------------------------------
# 3. opencode
# ---------------------------------------------------------------------------
Write-Step 'Controllo opencode'
$openCodeOk = $false
$OcExe = Join-Path $OcDir 'opencode.exe'
# a/b) gia presente: estratto in un giro precedente, installer ufficiale, npm, oppure nel PATH.
#      Si usa il .exe vero (mai opencode.ps1, bloccato se gli script sono disabilitati).
$ocCand = @(
    $OcExe,
    (Join-Path $env:USERPROFILE '.opencode\bin\opencode.exe'),
    (Join-Path $NpmGlobal 'node_modules\opencode-ai\bin\opencode.exe'))
foreach ($n in 'opencode.exe','opencode.cmd') {
    $c = Get-Command $n -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { $ocCand += $c.Source }
}
foreach ($p in $ocCand) {
    if (Test-OpencodeExe $p) {
        $openCodeOk = $true; $OcExe = $p
        Write-Ok "opencode gia presente, NON lo installo: $((& $p --version) 2>&1)  [$p]"
        break
    }
}
# c) dalla chiavetta: zip ufficiale (x64, oppure baseline per CPU senza AVX2) - niente download
if (-not $openCodeOk) {
    $zx = Find-KitFile 'opencode-windows-x64.zip'
    $zb = Find-KitFile 'opencode-windows-x64-baseline.zip'
    $order = if (Test-Avx2) { @($zx, $zb) } else { @($zb, $zx) }
    foreach ($z in ($order | Where-Object { $_ })) {
        Write-Info "Estraggo opencode dalla chiavetta ($(Split-Path $z -Leaf))..."
        Remove-Item $OcDir -Recurse -Force -ErrorAction SilentlyContinue
        Expand-Archive -Path $z -DestinationPath $OcDir -Force
        if (Test-OpencodeExe $OcExe) {
            $openCodeOk = $true
            Write-Ok "opencode installato dalla chiavetta: $((& $OcExe --version) 2>&1)"
            break
        }
        Write-Warn2 'Questa versione non parte su questo PC: provo l''altra.'
    }
}
# d) ultima possibilita: npm (serve internet)
if (-not $openCodeOk) {
    if (-not (Have-Command npm)) {
        Write-Warn2 'Salto opencode: npm non disponibile.'
    } else {
        Write-Info 'Installazione di opencode (npm i -g opencode-ai)...'
        Write-Info 'Scarica ~180 MB: puo richiedere 5-10 minuti. Le righe "http fetch" indicano che procede.'
        try { npm install -g opencode-ai --prefix "$NpmGlobal" --loglevel http --no-audit --no-fund } catch {}
        Refresh-Path
        # Su alcune versioni recenti di npm il postinstall viene bloccato: il binario resta uno stub
        $stub = Join-Path $NpmGlobal 'node_modules\opencode-ai\bin\opencode.exe'
        if ((Test-Path $stub) -and ((Get-Item $stub).Length -lt 1MB)) {
            Write-Warn2 'Postinstall di opencode bloccato: provo a sbloccarlo.'
            try { npm config set allow-scripts=opencode-ai --location=user 2>&1 | Out-Null } catch {}
            $pi = Join-Path $NpmGlobal 'node_modules\opencode-ai\postinstall.mjs'
            if (Test-Path $pi) { Push-Location (Split-Path $pi -Parent); try { node postinstall.mjs 2>&1 | Out-Null } catch {}; Pop-Location }
        }
        Refresh-Path
        if (Have-Command opencode) {
            try { $v = (opencode --version) 2>&1 } catch { $v = '?' }
            Write-Ok "opencode installato: $v"
        } else {
            Write-Warn2 'opencode NON installato: serve internet per npm. Controlla la rete e rilancia.'
        }
    }
}
# Da qui in poi usa l'opencode della chiavetta se c'e' (evita un eventuale npm installato a meta)
$OcCmd = $null
foreach ($p in @($OcExe, (Join-Path $OcDir 'opencode.exe'), (Join-Path $NpmGlobal 'node_modules\opencode-ai\bin\opencode.exe'))) {
    if (Test-OpencodeExe $p) { $OcCmd = $p; break }
}
if (-not $OcCmd -and (Have-Command opencode)) { $OcCmd = 'opencode' }
# La cartella del .exe scelto va IN TESTA al PATH utente: cosi anche VS Code aperto
# dal menu Start (senza il nostro lanciatore) trova opencode.exe e non opencode.ps1
if ($OcCmd -and $OcCmd.EndsWith('.exe')) { Add-ToUserPath (Split-Path $OcCmd -Parent) -First }

# ---------------------------------------------------------------------------
# 4. VS Code portable
# ---------------------------------------------------------------------------
# Prima cerca un VS Code gia presente (portable di lezioni-AI o installato sul PC)
$codeExe = Find-Existing 'Code.exe' @(
    (Join-Path $VSCodeDir 'Code.exe'),
    "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe",
    "$env:ProgramFiles\Microsoft VS Code\Code.exe")
if (-not $SkipVSCode) {
    Write-Step 'Visual Studio Code (portable)'
    if ($codeExe) {
        Write-Ok "VS Code gia presente, NON lo installo  [$codeExe]"
    } else {
        $codeExe = Join-Path $VSCodeDir 'Code.exe'
        # Usa il pacchetto dalla chiavetta se presente (accanto a questo script), altrimenti scarica
        $localZip = Join-Path $Kit 'vscode-win32-x64.zip'
        $downloaded = $false
        if (Test-Path $localZip) {
            Write-Info 'Uso VS Code dalla chiavetta (nessun download)...'
            $zip = $localZip
        } else {
            $zip = Join-Path $env:TEMP 'vscode-portable.zip'
            Write-Info 'Scarico VS Code (stabile, win32-x64)...'
            Invoke-WebRequest -Uri 'https://update.code.visualstudio.com/latest/win32-x64-archive/stable' -OutFile $zip -UseBasicParsing
            $downloaded = $true
        }
        Write-Info 'Estraggo (qualche minuto)...'
        New-Item -ItemType Directory -Force -Path $VSCodeDir | Out-Null
        Expand-Archive -Path $zip -DestinationPath $VSCodeDir -Force
        if ($downloaded) { Remove-Item $zip -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Force -Path (Join-Path $VSCodeDir 'data') | Out-Null  # attiva modalita portable
        if (Test-Path $codeExe) { Write-Ok 'VS Code installato (portable).' }
        else { Write-Warn2 'Code.exe non trovato dopo estrazione: controlla la connessione.' }
    }
} else { Write-Info 'VS Code saltato (-SkipVSCode).' }

# ---------------------------------------------------------------------------
# 5. Herdr (dentro lezioni-AI)
# ---------------------------------------------------------------------------
if (-not $SkipHerdr) {
    Write-Step 'Herdr'
    New-Item -ItemType Directory -Force -Path $HerdrDir | Out-Null
    $herdrPath = Find-Herdr
    if ($herdrPath) {
        Write-Ok "Herdr gia presente, NON lo installo  [$herdrPath]"
    } else {
        Write-Info 'Installo Herdr (script ufficiale herdr.dev)...'
        # Prova a installarlo dentro lezioni-AI; sui PC puliti dell'aula finisce qui
        $env:HERDR_HOME        = $HerdrDir
        $env:HERDR_INSTALL_DIR = Join-Path $HerdrDir 'bin'
        $herdrScript = Join-Path $env:TEMP 'herdr-install.ps1'
        try {
            Invoke-RestMethod -Uri 'https://herdr.dev/install.ps1' -OutFile $herdrScript -UseBasicParsing
            & $herdrScript -Channel stable   # -Channel evita che si blocchi se Herdr esiste gia'
            Refresh-Path
            $herdrPath = Find-Herdr
            if ($herdrPath) { Write-Ok "Herdr disponibile: $herdrPath" }
            else { Write-Warn2 'Herdr non trovato dopo installazione: controlla il log sopra.' }
        } catch {
            Write-Warn2 "Installazione Herdr fallita: $($_.Exception.Message)"
            $herdrPath = Find-Herdr
        } finally {
            Remove-Item $herdrScript -Force -ErrorAction SilentlyContinue
        }
    }
    if ($herdrPath) { Add-ToUserPath (Split-Path $herdrPath -Parent) }
} else { Write-Info 'Herdr saltato (-SkipHerdr).' }

# ---------------------------------------------------------------------------
# 6. Lanciatori + collegamenti in lezioni-AI
#    I .cmd impostano da soli il PATH con percorsi assoluti: funzionano anche
#    se Windows non ha ancora "visto" il nuovo PATH utente (niente riavvio).
# ---------------------------------------------------------------------------
Write-Step 'Creo i collegamenti'
$herdrPath = Find-Herdr
$OcCmdDir = if ($OcCmd -and (Test-Path $OcCmd)) { Split-Path $OcCmd -Parent } else { $null }
$pathDirs = @($OcCmdDir, $GitCmdDir, $NodeExeDir, $NpmGlobal)   # l'opencode scelto per primo
if ($herdrPath) { $pathDirs += (Split-Path $herdrPath -Parent) }
$pathDirs = $pathDirs | Where-Object { $_ -and (Test-Path $_) } | Select-Object -Unique
$setPath  = "set `"PATH=$($pathDirs -join ';');%PATH%`""
Write-Info "PATH dei lanciatori: $($pathDirs -join ';')"

$WShell = New-Object -ComObject WScript.Shell

# --- VS Code: launcher .cmd (PATH) + collegamento che apre la cartella progetti ---
if ($codeExe -and (Test-Path $codeExe)) {
    $launcher = Join-Path $Base 'avvia-vscode.cmd'
    $cmdBody  = "@echo off`r`n$setPath`r`nstart `"`" `"$codeExe`" `"$Progetti`"`r`n"
    Set-Content -Path $launcher -Value $cmdBody -Encoding Default
    $lnk = $WShell.CreateShortcut((Join-Path $Base 'Visual Studio Code.lnk'))
    $lnk.TargetPath       = $launcher
    $lnk.WorkingDirectory = $Progetti
    $lnk.IconLocation     = $codeExe
    $lnk.WindowStyle      = 7   # finestra del .cmd ridotta a icona
    $lnk.Description      = 'VS Code - Lezione IA (cartella progetti)'
    $lnk.Save()
    Write-Ok 'Collegamento: Visual Studio Code.lnk'
}

# --- Herdr: launcher .cmd + collegamento ---
if ($herdrPath) {
    $launcher = Join-Path $Base 'avvia-herdr.cmd'
    if ($BashExe) {
        $cmdBody = "@echo off`r`n$setPath`r`ncd /d `"$Progetti`"`r`n`"$BashExe`" -l -i -c herdr`r`n"
    } else {
        $cmdBody = "@echo off`r`n$setPath`r`ncd /d `"$Progetti`"`r`n`"$herdrPath`"`r`n"
    }
    Set-Content -Path $launcher -Value $cmdBody -Encoding Default
    $lnk = $WShell.CreateShortcut((Join-Path $Base 'Herdr.lnk'))
    $lnk.TargetPath       = $launcher
    $lnk.WorkingDirectory = $Progetti
    $lnk.Description      = 'Herdr - Lezione IA'
    $lnk.Save()
    Write-Ok 'Collegamento: Herdr.lnk'
}

# ---------------------------------------------------------------------------
# 7. Accesso a opencode (chiave Gemini gratuita)
# ---------------------------------------------------------------------------
$AuthFile = Join-Path $env:USERPROFILE '.local\share\opencode\auth.json'
function Test-GoogleKey {
    if (-not (Test-Path $AuthFile)) { return $false }
    $txt = Get-Content $AuthFile -Raw -ErrorAction SilentlyContinue
    return ($txt -match '"google"')
}
if (-not $SkipAuth -and $OcCmd) {
    Write-Step 'Accesso a opencode (Gemini gratuito)'
    if (Test-GoogleKey) {
        Write-Ok 'Una chiave Google/Gemini risulta gia configurata.'
    } else {
        Write-Host ''
        Write-Host '  Per usare opencode serve una chiave (gratuita) di Google AI Studio.' -ForegroundColor White
        Write-Host '  1) Vai su https://aistudio.google.com/apikey  (account Google, niente carta)' -ForegroundColor White
        Write-Host '  2) Crea la chiave e copiala' -ForegroundColor White
        Write-Host ''
        $risp = ''
        try { $risp = Read-Host '  Vuoi incollarla adesso e configurare opencode? (S/N)' } catch { $risp = 'n' }
        if ($risp -match '^[sSyY]') {
            Write-Info 'Si apre la procedura: se chiede il metodo scegli "API Key", poi incolla la chiave.'
            try { & $OcCmd auth login --provider google } catch { Write-Warn2 "Login non completato: $($_.Exception.Message)" }
        } else {
            Write-Info 'Saltato. Piu tardi da Git Bash:  opencode auth login --provider google'
        }
    }
}

# ---------------------------------------------------------------------------
# Riepilogo
# ---------------------------------------------------------------------------
$sGit  = if (Have-Command git)      { (git --version) 2>&1 } else { 'NON trovato' }
$sNode = if (Have-Command npm)      { "$((node -v) 2>&1) / npm $((npm -v) 2>&1)" } else { 'NON trovato' }
$sOc   = if ($OcCmd) { "$((& $OcCmd --version) 2>&1)  [$OcCmd]" } else { 'NON trovato' }
$sKey  = if (Test-GoogleKey) { 'chiave Gemini configurata' } else { 'nessuna chiave (vedi guida)' }
Add-Content $LogFile "RIEPILOGO git=$sGit | node=$sNode | opencode=$sOc | $sKey"

Write-Host "`n===================================================" -ForegroundColor White
Write-Host '  FATTO' -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor White
Write-Host "Utente:    $Me" -ForegroundColor White
Write-Host "Cartella:  $Base" -ForegroundColor White
Write-Host '  - Visual Studio Code.lnk' -ForegroundColor Gray
Write-Host '  - Herdr.lnk' -ForegroundColor Gray
Write-Host '  - progetti\  (qui lavora la classe)' -ForegroundColor Gray
Write-Host "`nStrumenti:" -ForegroundColor White
Write-Host "  git      : $sGit"  -ForegroundColor Gray
Write-Host "  node/npm : $sNode" -ForegroundColor Gray
Write-Host "  opencode : $sOc"   -ForegroundColor Gray
Write-Host "  accesso  : $sKey" -ForegroundColor Gray
Write-Host "`nApri gli strumenti SOLO dai collegamenti in lezioni-AI (impostano il PATH da soli)." -ForegroundColor Yellow
Write-Host "Log: $LogFile`n" -ForegroundColor DarkGray
