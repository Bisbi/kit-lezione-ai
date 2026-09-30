# Kit Lezione IA — opencode in classe

Chiavetta USB che prepara i PC di un'aula (Windows) per far usare **[opencode](https://opencode.ai)**
— un assistente di programmazione che vive nel terminale — insieme a **Visual Studio Code** e **[Herdr](https://herdr.dev)**.

Pensato per un laboratorio scolastico reale: **funziona senza privilegi di amministratore**,
installa tutto nel profilo dello studente ed è stato usato con successo su un'intera classe.

> Materiale didattico. Non affiliato a opencode, Microsoft, Google o Herdr.

---

## Cosa fa

Inserita la chiavetta e fatto doppio clic su `AVVIA-Setup.cmd`, lo script:

1. verifica **Git**, **Node.js** e **opencode** e installa solo ciò che manca (versioni *portable*, nessun admin);
2. sistema il **PATH** dell'utente;
3. installa **VS Code** (portable) e **Herdr** in `Documenti\lezioni-AI`;
4. propone il login a **Gemini** (chiave gratuita) per opencode;
5. crea i collegamenti e la cartella `progetti\` dove la classe lavora.

Lo script è **idempotente** (si può rilanciare) e scrive un `setup-log.txt`.
Dettagli completi e note di manutenzione in **[docs/HANDOFF.md](docs/HANDOFF.md)**.

---

## Come costruire la chiavetta

Servono un PC Windows con connessione a internet e una chiavetta da almeno 2 GB.

1. **Scarica questo repo** (pulsante *Code → Download ZIP*, oppure `git clone`).
2. **Scarica i binari** dai siti ufficiali (non sono inclusi nel repo perché grandi):
   ```powershell
   powershell -ExecutionPolicy Bypass -File setup\Scarica-Binari.ps1
   ```
   Scarica ~600 MB (Git, Node, opencode ×2, VS Code) nella cartella `setup\`.
   Per mettere i file direttamente sulla chiavetta: `... -Destinazione E:\Setup-Lezione-AI`
   (sostituisci `E:` con la lettera della tua chiavetta).
3. **Copia sulla chiavetta** il contenuto di `setup\` (script + binari appena scaricati).
   Se vuoi anche i materiali per la classe, aggiungi i file di `docs\`.

La chiavetta pronta contiene: `AVVIA-Setup.cmd`, `Setup-LezioneAI.ps1`, i binari, e (facoltativi) guida e handout.

---

## Come si usa in aula (per ogni PC)

1. **Accedi con l'utente dello studente** (non con l'amministratore).
2. Inserisci la chiavetta e fai **doppio clic su `AVVIA-Setup.cmd`**
   (**non** "Esegui come amministratore": lo script se ne accorge e si ferma).
3. Attendi il riepilogo **FATTO**.
4. Apri VS Code e Herdr **dai collegamenti** in `Documenti\lezioni-AI`.

Su un PC senza niente preinstallato il primo giro dura ~10 minuti (VS Code e opencode
sono le parti lente): conviene avviare i PC in parallelo, meglio il giorno prima.

---

## Materiali per la classe (`docs/`)

- **[GUIDA-STUDENTI.txt](docs/GUIDA-STUDENTI.txt)** — istruzioni essenziali per lo studente.
- **[Handout-Studenti.html](docs/Handout-Studenti.html)** — scheda A4 stampabile (apri nel browser → *Stampa/Salva PDF*). Funziona offline.
- **[HANDOFF.md](docs/HANDOFF.md)** — stato del progetto, scelte tecniche e trappole note.

---

## Skill per opencode: gestione del contesto

Per governare il contesto dei progetti c'è una famiglia di tre skill collegate
(`gestione-contesto`, `nuovo-progetto`, `handoff`) che gestiscono quattro file
(`AGENTS.md`, `HANDOFF.md`, `TO-DO.md`, `AS-IS.md`).

Per installarle su un'altra macchina, apri opencode e incolla il prompt
**[docs/INSTALLA-skill-famiglia-contesto.md](docs/INSTALLA-skill-famiglia-contesto.md)**:
opencode crea da solo i file delle skill nei percorsi giusti (`~/.config/opencode/skills/...`).
Poi riavvia opencode.

## Modelli di IA gratuiti

opencode si collega a un modello tramite `opencode auth login --provider <id>`
(la chiave resta locale, in `%USERPROFILE%\.local\share\opencode\auth.json`).

| Provider | id | Dove prendere la chiave |
|---|---|---|
| Google Gemini (consigliato) | `google` | https://aistudio.google.com/apikey |
| OpenRouter | `openrouter` | https://openrouter.ai/keys |
| Groq | `groq` | https://console.groq.com/keys |

**Importante:** i limiti gratuiti sono **per chiave** → in classe ogni studente usa la **propria** chiave.
Le quote esatte cambiano nel tempo e si vedono in `aistudio.google.com/rate-limit`.

---

## Sicurezza e privacy

- Lo script **non richiede l'amministratore** e agisce solo nel profilo dell'utente.
- **Nessuna chiave o credenziale** è inclusa nel repo; `auth.json` e i log sono esclusi da `.gitignore`.
- opencode è un agente che **può eseguire comandi**: in aula spiega agli studenti di non incollare
  dati personali o sensibili e di non far eseguire comandi che non capiscono.

---

## Requisiti

- Windows 10/11, PowerShell 5.1+ (incluso in Windows).
- Connessione a internet sul PC che **costruisce** la chiavetta (per `Scarica-Binari.ps1`) e,
  in aula, per il login al modello e per Herdr.

---

## Licenza e crediti

Codice e documentazione di questo repo: **[MIT](LICENSE)**.

I binari **non** sono inclusi né ridistribuiti: `Scarica-Binari.ps1` li preleva dalle rispettive
fonti ufficiali, ognuno con la propria licenza — [Git for Windows](https://gitforwindows.org/),
[Node.js](https://nodejs.org/), [opencode](https://github.com/sst/opencode),
[Visual Studio Code](https://code.visualstudio.com/) (build ufficiale Microsoft),
[Herdr](https://herdr.dev).
