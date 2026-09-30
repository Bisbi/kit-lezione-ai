# HANDOFF — Kit "Lezione IA" (opencode in classe)

**Aggiornato:** 30 settembre 2026 (prima versione: 27/09/2026)
**Scopo:** chiavetta USB che prepara i PC dell'aula (Windows) per far usare
**opencode** agli studenti, con VS Code e Herdr.

---

## Aggiornamento del 30/09

- **✅ Test in aula superato:** l'intera classe ha usato la chiavetta con successo (script no-admin).
- **Pubblicato come repo:** questo documento vive ora anche in un repo pubblico con gli script e i materiali.
  I binari non sono nel repo: si scaricano con `setup/Scarica-Binari.ps1` dalle fonti ufficiali.
- **✅ Skill opencode "gestione del contesto":** prompt d'installazione pronto in
  `docs/INSTALLA-skill-famiglia-contesto.md` (linkato dal README). Da incollare in opencode per
  installare le 3 skill collegate (`gestione-contesto`, `nuovo-progetto`, `handoff`).
- **Arricchimenti proposti (da fare):** progetto starter + esercizi in `progetti\`; `AGENTS.md` per far
  rispondere opencode in italiano; paletti di sicurezza all'agente (conferma comandi, telemetria off);
  `VERIFICA.cmd` e `RIMUOVI-Lezione-AI.cmd`; `git init` in `progetti\`.

---

## 0. Novità del 28/09 — perché lo script è cambiato

In aula **3 PC su 5** hanno l'account amministratore **diverso** dall'utente che fa l'accesso.
Con la versione precedente:

- `AVVIA-Setup.cmd` chiedeva l'elevazione (UAC). Inserendo le credenziali dell'admin, lo script
  girava **come l'admin**: Documenti, `lezioni-AI`, PATH utente, npm e chiave opencode finivano
  nel **profilo dell'admin**, invisibili allo studente.
- winget è registrato **per utente**: nell'account admin elevato spesso non esiste. Lo script
  faceva `throw` e **si fermava al primo passo**, per questo Git, Node e opencode fallivano tutti insieme.

**Soluzione adottata:** lo script **non chiede più l'amministratore** e gira come lo studente.
Git e Node sono **portable sulla chiavetta** e vengono estratti nel profilo dello studente.
winget resta solo come riserva e non blocca più lo script.

---

## 1. Cosa c'è sulla chiavetta (`D:\Setup-Lezione-AI\`)

| File | Cosa fa |
|---|---|
| `AVVIA-Setup.cmd` | **Doppio clic per partire** (NON "Esegui come amministratore"). Nessuna richiesta UAC. |
| `Setup-LezioneAI.ps1` | Lo script vero di installazione/configurazione. |
| `PortableGit-2.55.0.5-64-bit.7z.exe` | Git for Windows portable (~59 MB), senza installazione né admin. |
| `node-v24.21.0-win-x64.zip` | Node.js 24 LTS (zip, ~38 MB, checksum verificato con nodejs.org). |
| `opencode-windows-x64.zip` | opencode 1.18.33 ufficiale (binario unico, ~62 MB): **niente npm, niente download**. |
| `opencode-windows-x64-baseline.zip` | Stessa versione per CPU senza AVX2 (PC vecchi). Lo script sceglie da solo. |
| `vscode-win32-x64.zip` | VS Code portable (~321 MB): niente download in aula. |
| `GUIDA-STUDENTI.txt` | Guida in testo semplice per gli studenti. |
| `Handout-Studenti.html` | Handout A4 stampabile (browser → Stampa/Salva PDF). Offline. |
| `HANDOFF.md` | Questo documento. |

Lo script trova i file per **nome con jolly** (`PortableGit-*-64-bit.7z.exe`, `node-v*-win-x64.zip`):
per aggiornarli basta sostituirli sulla chiavetta, senza toccare lo script.

**Copia master permanente:** `%USERPROFILE%\Documents\lezioni-AI\_setup-master\`
(lo zip di VS Code sta solo sulla chiavetta).

---

## 2. Cosa fa lo script (in ordine)

**Regola generale:** per OGNI componente lo script controlla prima se c'è già. Cerca nel PATH,
usando solo `.exe`/`.cmd` e mai `.ps1`, e nelle cartelle di installazione tipiche: `Program Files\Git`,
`Program Files\nodejs`, `%APPDATA%\npm\node_modules\opencode-ai`, `~\.opencode\bin`, VS Code installato,
Herdr ovunque. Se lo trova non installa niente e lo scrive nel log: `gia presente, NON lo installo [percorso]`.

0. **Controllo profilo:** confronta l'utente dello script con l'utente che ha fatto l'accesso al PC
   (`Win32_ComputerSystem.UserName`). Se sono diversi **si ferma** e spiega di rilanciare con doppio clic.
1. **Git:** già presente → ok. Altrimenti PortableGit dalla chiavetta → `lezioni-AI\strumenti\git`.
   Altrimenti winget `--scope user`. Altrimenti download da GitHub.
2. **Node.js/npm:** già presente → ok. Altrimenti zip dalla chiavetta → `lezioni-AI\strumenti\node`.
   Altrimenti download da nodejs.org. Altrimenti winget come ultima riserva.
3. **opencode:** già in `strumenti\opencode` | già sul PC | **zip dalla chiavetta** → `lezioni-AI\strumenti\opencode`
   (x64 se la CPU ha AVX2, altrimenti baseline; se una non parte prova l'altra) | come ultima possibilità npm (serve internet).
   Dopo l'installazione lo script usa sempre l'`opencode.exe` della chiavetta, anche se c'è un npm installato a metà.
   Prima di tutto questo (passo 0b) imposta `Set-ExecutionPolicy -Scope CurrentUser RemoteSigned` (niente admin).
4. **PATH utente:** aggiunge git\cmd, node, `%APPDATA%\npm`, herdr (registro HKCU dello studente).
5. **VS Code portable** da chiavetta (o download) in `lezioni-AI\vscode`.
6. **Herdr** in `lezioni-AI\herdr` (script ufficiale, `-Channel stable`). **Richiede internet.**
7. **Lanciatori e collegamenti:** `avvia-vscode.cmd` e `avvia-herdr.cmd` fanno `set PATH=<percorsi assoluti>;%PATH%`
   prima di partire. I collegamenti `Visual Studio Code.lnk` e `Herdr.lnk` puntano a questi.
   → **Non serve riavviare né attendere che Windows aggiorni il PATH.**
8. **Accesso opencode:** se manca la chiave, propone `opencode auth login --provider google`.

Lo script è **idempotente** e scrive `setup-log.txt` (con nome utente e riga RIEPILOGO).
Parametri: `-SkipVSCode`, `-SkipHerdr`, `-SkipAuth` (passabili anche al .cmd).

Struttura risultante (nel profilo dello **studente**):
```
Documenti\lezioni-AI\
├── Visual Studio Code.lnk  → avvia-vscode.cmd  (PATH + apre progetti)
├── Herdr.lnk               → avvia-herdr.cmd   (PATH + Git Bash + herdr)
├── progetti\               (qui lavora la classe)
├── strumenti\git\          (Git portable, se non c'era)
├── strumenti\node\         (Node portable, se non c'era)
├── vscode\                 (VS Code portable + data)
├── herdr\                  (binario Herdr)
└── setup-log.txt
%APPDATA%\npm\              (opencode)
%USERPROFILE%\.local\share\opencode\auth.json   (chiave Gemini)
```

---

## 3. Stato — cosa è VERIFICATO

Il 27/09 (versione precedente, su questo PC con utente admin):
- ✅ VS Code portable dalla chiavetta, Herdr 0.9.1, collegamenti, rilevamento chiave in `auth.json`.
- ✅ Comandi opencode: `opencode`, `opencode auth login --provider google`, `opencode auth list`.
- ✅ Handout in una pagina A4.

Il 28/09 (nuova versione):
- ✅ Script senza errori di sintassi.
- ✅ Estrazione PortableGit dalla chiavetta in cartella di prova: 32 s, `git 2.55.0.windows.5`, `bash.exe` presente.
- ✅ Estrazione Node zip: 73 s, `node v24.21.0`, `npm 11.19.0`.
- ✅ Installazione opencode con il Node portable (npm 11): `opencode 1.18.33` funziona, il postinstall
  NON è bloccato (binario reale ~180 MB). **Ha impiegato ~6 minuti**: scarica ~180 MB per PC.
- ✅ **30/09: test in aula superato** — l'intera classe ha usato la chiavetta con successo.

---

## 4. DA FARE prima della lezione

1. **Prova completa su un PC d'aula con utente NON amministratore** (priorità).
   Controllare: nessuna richiesta UAC, `lezioni-AI` nei Documenti dello studente, riepilogo tutto verde,
   e **apertura dai collegamenti** → nel terminale `opencode --version` risponde.
2. **Internet in aula:** opencode (npm) e Herdr si scaricano dalla rete. Git, Node e VS Code no.
   Se in aula la rete è filtrata, verificare che `registry.npmjs.org` e `herdr.dev` siano raggiungibili.
3. **Autenticazione opencode (ancora aperta).** Ogni studente crea la **propria** chiave gratuita
   su `https://aistudio.google.com/apikey`. I limiti sono **per chiave**: una chiave condivisa fra 20 persone si blocca subito.
4. **Tempi:** su PC senza niente installato il primo giro dura ~10 min. Le parti lente sono
   l'estrazione di VS Code e il download di opencode (~180 MB per PC). Conviene avviare tutti i PC
   insieme e, se possibile, **il giorno prima** della lezione.

---

## 5. Procedura in aula (per ogni PC)

1. **Fai l'accesso con l'utente dello studente** (non con l'admin).
2. Inserisci la chiavetta, apri `D:\Setup-Lezione-AI\`, **doppio clic su `AVVIA-Setup.cmd`**.
   **Non** usare "Esegui come amministratore": lo script se ne accorge e si ferma.
3. Attendi il riepilogo "FATTO".
4. Gli studenti aprono **sempre** VS Code/Herdr dai collegamenti in `Documenti\lezioni-AI`.
   Git Bash dal menu Start **non esiste** se Git è portable.
5. Se qualcosa risulta "NON installato": leggi `setup-log.txt`, correggi (di solito è la rete) e rilancia.

---

## 6. Trappole note (gestite nello script)

- **Account admin diverso dallo studente** → niente elevazione + controllo profilo all'avvio.
- **winget assente o non registrato** → non è più indispensabile e non blocca lo script (`Try-Winget` restituisce vero/falso).
- **PATH non aggiornato nelle finestre già aperte** → i lanciatori .cmd impostano il PATH da soli.
- **"L'esecuzione di script è disabilitata" su `opencode.ps1`** (visto il 28/09 su un PC d'aula con un utente standard):
  npm crea `opencode.ps1`, che PowerShell preferisce al `.cmd`, e il criterio di esecuzione predefinito lo blocca.
  → Lo script mette la cartella dell'`opencode.exe` **in testa al PATH utente**, prima di `%APPDATA%\npm`.
  Così anche VS Code aperto dal menu Start trova l'`.exe` (verificato con gli script bloccati).
  Eccezione: se npm è nel PATH *di sistema* (come sul PC che costruisce la chiavetta) vince comunque il `.ps1`; lì
  aiutano il collegamento e l'ExecutionPolicy. → Lo script imposta anche `RemoteSigned` per CurrentUser. Se i criteri della scuola lo impediscono, usare `opencode.cmd`,
  oppure Herdr/Git Bash, oppure l'`opencode.exe` della chiavetta (è un .exe, quindi non viene bloccato).
- **Installazione npm di opencode lenta** (~180 MB, sembrava bloccata perché l'output era nascosto) → ora opencode
  si prende dallo zip sulla chiavetta; con npm l'output è visibile (`--loglevel http`).
- **npm 12 blocca il postinstall di opencode** (binario stub < 1 MB) → `allow-scripts` + `postinstall.mjs`.
- **Herdr si blocca se già presente** → `-Channel stable`.
- **Estrazione lenta** → `$ProgressPreference='SilentlyContinue'` la velocizza, ma VS Code resta il passo lungo.
- **Criteri di gruppo che bloccano PowerShell o i .exe nel profilo utente** → non gestibile dallo script.
  Se succede su qualche PC, serve il tecnico di laboratorio.

---

## 7. Modelli gratuiti per opencode (riserve se finisce la quota)

`opencode auth login --provider <id>`, poi dentro opencode `/models`.

| Provider | id | Dove prendere la chiave |
|---|---|---|
| Google Gemini (consigliato) | `google` | https://aistudio.google.com/apikey |
| OpenRouter (tanti modelli) | `openrouter` | https://openrouter.ai/keys |
| Groq (velocissimo) | `groq` | https://console.groq.com/keys |

Le quote gratuite cambiano: si vedono in `aistudio.google.com/rate-limit`.
