# Prompt da incollare in opencode — installa la famiglia "gestione del contesto"

Installa tre skill collegate per opencode:

- **gestione-contesto** — spiega il sistema dei quattro file di contesto (`AGENTS.md`, `HANDOFF.md`, `TO-DO.md`, `AS-IS.md`).
- **nuovo-progetto** — all'avvio di un progetto genera i quattro file col contenuto vero.
- **handoff** — a fine/ripresa sessione misura il progetto e riscrive `HANDOFF.md` / `AS-IS.md`.

**Come si usa (studente):** apri **opencode** in una cartella qualsiasi e **incolla tutto questo
messaggio** (dall'istruzione qui sotto fino in fondo). opencode creerà i file nei percorsi indicati.
Poi chiudi e riapri opencode: le tre skill saranno attive.

---

## ISTRUZIONE PER OPENCODE

Sei opencode. Installa tre skill creando **esattamente** i file elencati qui sotto, con il contenuto
testuale riportato tra i recinti di codice, **senza modificarlo** e **senza aggiungere commenti tuoi**.
Crea le cartelle mancanti. Se un file esiste già, chiedi prima di sovrascrivere. I percorsi sono
relativi alla home dell'utente (`~` = `%USERPROFILE%` su Windows).

Al termine, scrivi un breve riepilogo dei file creati e ricordami di riavviare opencode per caricare
le skill. Non fare altro.

### File 1 — `~/.config/opencode/skills/gestione-contesto/SKILL.md`

````markdown
---
name: gestione-contesto
description: Use when a project needs its context organized, documented, or kept current - the user mentions context management, project memory, "gestire il contesto", asks where to put notes, asks what AGENTS.md / HANDOFF.md / TO-DO.md / AS-IS.md are for, or asks how to resume work after a break. Also use when a project folder has some of these files but not others.
---

# Gestione del contesto di progetto

## Principio

Un progetto senza contesto scritto è un progetto che si perde alla prima sessione. Quattro file,
quattro ruoli, nessuna sovrapposizione.

## I quattro file

| File | Risponde a | Chi lo aggiorna | Quando |
|---|---|---|---|
| `AGENTS.md` | *Perché esiste e come è fatto* | Solo se l'intento cambia | Mesi |
| `HANDOFF.md` | *Cosa faccio adesso* | `handoff`, a ogni sessione | Una sessione |
| `TO-DO.md` | *Cosa manca adesso* | Durante il lavoro | La sessione |
| `AS-IS.md` | *Dove il progetto si discosta da AGENTS.md* | `handoff`, a ogni sessione | Si riallinea |

**`AGENTS.md`** descrive l'intento: obiettivo, stack, comandi, convenzioni, vincoli, struttura.
È l'unico file che opencode e Claude Code **caricano da solo** all'avvio della sessione — per questo
va tenuto corto. Tutto ciò che non vale per i prossimi due mesi non ci va.

**`HANDOFF.md`** è la consegna. Si riscrive a ogni sessione. Il compito vero va **in cima**, in
dieci righe, con i comandi pronti da copiare.

**`TO-DO.md`** è la checklist viva della sessione. Si consuma: i fatti spuntati migrano in
`HANDOFF.md`.

**`AS-IS.md`** non è lo stato attuale: è il **drift**, la distanza fra ciò che `AGENTS.md` prescrive e
ciò che il codice fa davvero. Si scopre misurando il progetto, non ricordandolo.

## Il ciclo

```
nuovo-progetto  →  genera i quattro file
       ↓
   si lavora     →  TO-DO.md si consuma
       ↓
     handoff     →  riscrive HANDOFF.md
                    riallinea AS-IS.md
                    svuota TO-DO.md
```

## Le due skill

- **`nuovo-progetto`** — quando l'utente dice "nuovo progetto" o la cartella è vuota. Intervista con
  3-4 domande, poi genera i quattro file col contenuto vero.
- **`handoff`** — quando l'utente dice "handoff" o "chiudi la sessione". Misura col codice, scrive.

## Il contratto completo

**REQUIRED: leggi `~/.config/opencode/skills/gestione-contesto/references/struttura-progetto.md`**
prima di scrivere o modificare uno qualsiasi dei quattro file. Contiene le sezioni richieste, i
template e l'elenco degli errori da non ripetere. È l'unica fonte di verità sulla struttura.

## Errori comuni

| Non fare | Perché |
|---|---|
| `Agents.md`, `Hondoff.md`, `todo.md` | Le maiuscole sbagliate fanno perdere il caricamento automatico di `AGENTS.md` |
| File `.txt` | Il contenuto è markdown: niente highlighting, niente link cliccabili |
| `<scrivi qui>` o `TODO` dentro i file | Un file con i segnaposto non verrà mai aggiornato. Usa "da definire" |
| Riscrivere `AGENTS.md` a ogni sessione | Diventa un registro di sessione. Sta in `AGENTS.md` solo ciò che vale per tutto il progetto |
| Far crescere `HANDOFF.md` di sessione in sessione | Dopo tre sessioni nessuno lo legge |
| Lasciare i `[x]` in `TO-DO.md` per settimane | Il file muore. I task chiusi vanno in `HANDOFF.md` |
| Un quinto file per le note | Cinque file che dicono la stessa cosa divergono. Se serve, sta dentro uno dei quattro |
````

### File 2 — `~/.config/opencode/skills/gestione-contesto/gestione-contesto.md`

````markdown
# Gestione del contesto

Come mantenere il filo di un progetto tra una sessione e l'altra, con quattro file e due skill.

---

## Il punto di partenza

Questo metodo nasce da quattro osservazioni:

- In `AGENTS.md` di solito si conserva la memoria generale del progetto.
- In `HANDOFF.md` di solito si conserva la consegna per proseguire il lavoro sul progetto.
- In `TO-DO.md` di solito cadono i task da gestire nella sessione.
- In `AS-IS.md` c'è di solito la distanza fra `AGENTS.md` e lo stato attuale dello sviluppo.

Da queste quattro righe discende tutto il resto: due skill che creano e aggiornano la struttura
(`nuovo-progetto` e `handoff`), e questo documento che spiega perché è fatta così.

---

## I quattro file

| File | Domanda a cui risponde | Chi lo aggiorna | Quanto dura |
|---|---|---|---|
| `AGENTS.md` | *Perché esiste e com'è fatto?* | Solo se cambia l'intento | Mesi |
| `HANDOFF.md` | *Cosa faccio adesso?* | A ogni sessione | Una sessione |
| `TO-DO.md` | *Cosa manca adesso?* | Durante il lavoro | La sessione |
| `AS-IS.md` | *Dove il progetto si discosta da AGENTS.md?* | A ogni sessione | Si riallinea |

### `AGENTS.md` — la memoria generale

Descrive l'**intento**, non il progresso. Contiene:

1. **Obiettivo** — cosa dev'essere vero quando il progetto è finito
2. **Stack** — linguaggio, framework, versioni
3. **Comandi** — build, test, lint, esecuzione
4. **Convenzioni** — stile del codice, dove stanno i test, formato dei commit
5. **Vincoli** — cosa non si tocca e perché
6. **Struttura** — le cartelle e cosa ci sta dentro
7. **Documentazione** — dove trovare altro

È **l'unico file che opencode e Claude Code caricano da soli** all'avvio di ogni sessione. Questo
cambia tutto: tutto ciò che scrivi qui è contesto gratis, duecento volte. Ma vale anche il
contrario: tutto ciò che non vale per i prossimi due mesi non deve stare qui.

**Le maiuscole non sono pignoleria.** `AGENTS.md` viene caricato in automatico, `Agents.md` no.
Lo stesso vale per `HANDOFF.md` (`Hondoff.md` non esiste) e per l'estensione: `.md`, non `.txt`,
perché il contenuto è markdown e deve avere highlighting e link cliccabili.

### `HANDOFF.md` — la consegna

Si riscrive a ogni sessione. Non si accoda.

L'ordine delle sezioni non è decorativo. Chi apre `HANDOFF.md` ha spesso il context window pieno e
salta all'inizio sperando di trovare subito la risposta:

1. **Da fare adesso** — il compito vero, in dieci righe, con i comandi pronti da copiare
2. **Stato verificato** — ✅ e ❌, ciascuno con il comando che lo dimostra
3. **Cosa manca** — per importanza
4. **Trappole note** — cosa fa perdere tempo se non è scritto qui
5. **Riferimenti** — file da aprire, comandi, URL

Intestazione con la data e una riga "cosa è cambiato dall'ultima volta".

Se serve un allegato, vuol dire che è scritto male: l'allegato va in `AGENTS.md` o nei file del
progetto.

### `TO-DO.md` — i task della sessione

Una checklist viva che si consuma:

| Simbolo | Significato |
|---|---|
| `[ ]` | Da fare |
| `[x]` | Fatto **e verificato da un comando** |
| `[x]?` | Fatto ma non verificato |
| `[~]` | Bloccato — il perché è scritto accanto |

Non è un archivio. I `[x]` non restano a occupare spazio: a fine sessione migrano in `HANDOFF.md`
come fatto-verificato e il file si svuota.

### `AS-IS.md` — il drift

Questo è il file che quasi nessuno ha, ed è quello che rende il sistema onesto.

**Non** è "lo stato attuale". Se lo fosse, sarebbe l'ennesimo posto dove scrivere le stesse cose di
`HANDOFF.md`. Invece risponde a una domanda sola: **dove il progetto si è discostato da come
doveva essere?**

Tabella a tre colonne — *cosa dice AGENTS.md* | *cosa c'è davvero* | *scostamento* — più gli
scostamenti aperti e quelli chiusi con la data.

Alla creazione dice `gap non ancora misurato`. E si riallinea a ogni handoff, perché il drift si
scopre **misurando** il progetto, non ricordandolo.

---

## Il ciclo di lavoro

```
nuovo-progetto  →  genera i quattro file
       ↓
   si lavora     →  TO-DO.md si consuma
       ↓
     handoff     →  riscrive HANDOFF.md
                    riallinea AS-IS.md
                    svuota TO-DO.md
```

## Le due skill

Installate in `~/.config/opencode/skills/`, si attivano da sole quando serve.

### `nuovo-progetto`

Si attiva quando dici "nuovo progetto", "partiamo con X", "iniziamo Y", oppure quando la cartella è
vuota.

Chiede quattro cose — obiettivo in una frase, stack, come si builda e si testa, cosa non si tocca —
poi genera i quattro file in italiano **con il contenuto vero**, non con i segnaposto.

Prima di farti le domande le cerca già: legge `~/.claude/CLAUDE.md`, `package.json`,
`pyproject.toml` e via di seguito. Una domanda a cui la risposta è già sul disco è solo tempo perso.

### `handoff`

Si attiva quando dici "handoff", "chiudi la sessione", "salva il contesto", "proseguo domani".

Il suo passo importante è il primo: **misura**. Legge `TO-DO.md`, esegue i comandi di build e test,
confronta `AGENTS.md` con il codice voce per voce, e cerca scostamenti non dichiarati. Solo dopo
scrive. È la differenza fra un handoff e un riassunto della conversazione.

Poi scrive `HANDOFF.md` con l'ordine "urgente in cima", riallinea `AS-IS.md` con i fatti misurati,
svuota `TO-DO.md`.

---

## La regola di fondo

**Mai scrivere "fatto" senza il comando che lo dimostra.**

È l'unica regola che distingue un handoff utile da un riassunto decorativo.

Un handoff pieno di "ho sistemato il bug" e nessun comando non vale niente: la sessione dopo non
può né verificarlo né fidarsi. Un handoff con `✅ test passa — npm test` si verifica in tre secondi
e ci si costruisce sopra.

---

## Errori da non ripetere

| Non fare | Perché |
|---|---|
| Scrivere `<scrivi qui>` o `TODO` dentro i file | Un file pieno di segnaposto non verrà mai aggiornato. Meglio `da definire` |
| Mettere i comandi solo in `HANDOFF.md` | Alla sessione dopo non ci sei e non hai i comandi. Stanno in `AGENTS.md` |
| Riscrivere `AGENTS.md` a ogni sessione | Diventa un registro di sessione. Sta lì solo ciò che vale per tutto il progetto |
| Far crescere `HANDOFF.md` di sessione in sessione | Dopo tre sessioni nessuno lo legge. Si riscrive, non si accoda |
| Lasciare i `[x]` in `TO-DO.md` per settimane | Il file muore |
| Dare nomi diversi ai quattro file | `AGENTS.md` non viene più caricato in automatico e il sistema perde il senso |
| Scrivere in `AS-IS.md` le intenzioni future | `AS-IS.md` vale solo per ciò che hai misurato |
| Aggiungere un quinto file per le note | Cinque file che dicono la stessa cosa divergono. Se serve una nota, sta dentro uno dei quattro |
| Partire col codice prima dei quattro file | Un progetto senza contesto si perde alla prima sessione |

---

## Perché funziona

Il problema non è che l'AI dimentichi. È che **il contesto è dentro una finestra che si chiude**.

Quando finisce la sessione, spariscono tre cose: *cosa stavi facendo*, *perché lo facevi così* e
*cosa hai già scoperto sbagliato*. La sessione dopo si ricomincia da capo, e tu paghi ogni volta il
costo di riscrivere le stesse cose.

I quattro file non sono documentazione. Sono **memoria esterna**. Ognuno copre un buco diverso:

- `AGENTS.md` copre **la ragione** — perché il progetto è fatto così. E non devi rileggerlo
  davvero, perché l'AI lo carica da sola a ogni sessione.
- `HANDOFF.md` copre **il punto esatto** — non "di cosa abbiamo parlato", ma "la riga 44 di
  `auth.js` va sistemata, il test è `npm test`".
- `TO-DO.md` copre **il lavoro aperto** — così non rinasce un task già finito.
- `AS-IS.md` copre **il drift** — perché fra "come dovrebbe essere" e "come è" c'è sempre una
  distanza, e senza un file che la registri quella distanza si accumula in silenzio fino a quando
  nessuno ricorda più perché il codice è fatto in quel modo.

Il ciclo è chiuso proprio per questo: nessuno dei quattro file è una fotografia, sono tutti
**correnti** che si aggiornano a ogni sessione.

---

## Installazione

Le skill sono in `~/.config/opencode/skills/`:

```
~/.config/opencode/skills/
├── gestione-contesto/
│   ├── SKILL.md
│   └── references/struttura-progetto.md   ← il contratto: sezione e template dei 4 file
├── nuovo-progetto/
│   └── SKILL.md
└── handoff/
    └── SKILL.md
```

`references/struttura-progetto.md` è l'unica fonte di verità sulla struttura: se i quattro file
cambiano, si cambia lì e in nessun altro posto.

Su un PC nuovo basta copiare la cartella `skills/` dentro `%USERPROFILE%\.config\opencode\` e il
sistema funziona.

---

## Come si usa, in pratica

**All'inizio di un progetto**

> Nuovo progetto, si chiama `lista-spese`. Una web app per gestire la lista della spesa.

La skill chiede le quattro cose, poi genera i file. Tu non scrivi niente.

**Durante il lavoro**

> Aggiungi questo task: `<descrizione>`

Va in `TO-DO.md`. Quando è fatto, si spunta — solo se c'è un comando che lo dimostra.

**A fine sessione**

> Facciamo l'handoff.

La skill misura, scrive `HANDOFF.md`, riallinea `AS-IS.md` e svuota `TO-DO.md`.

**Domani**

> Riprendiamo.

L'AI ha già letto `AGENTS.md` da sola all'avvio. Tu leggi le prime dieci righe di `HANDOFF.md` e
sai dove mettere le mani.
````

### File 3 — `~/.config/opencode/skills/gestione-contesto/references/struttura-progetto.md`

````markdown
# Struttura di progetto — contratto dei quattro file

Fonte unica. La usano sia la skill `nuovo-progetto` sia la skill `handoff`.
Se la struttura cambia, si cambia **qui** e in nessun altro posto.

Tutti i file sono **markdown**, tutti scritti in **italiano**, tutti con il nome in
maiuscolo esattamente come indicato.

---

## Perché questi nomi

`AGENTS.md` in maiuscolo è il nome che opencode e Claude Code **caricano da soli** all'avvio di
ogni sessione. Se il file si chiama `Agents.md` o `agents.md` non viene caricato e la memoria del
progetto la devi comunque richiamare a mano ogni volta.

`HANDOFF.md` in maiuscolo perché `Hondoff.md` è quello che capita di scrivere sbagliando.

Il `.md` e non il `.txt` perché il contenuto è markdown e deve avere highlighting, link cliccabili
e resa leggibile in anteprima.

---

## `AGENTS.md` — la memoria generale

**Cosa descrive:** l'intento del progetto. Non il progresso, non la cronologia.

**Chi lo modifica:** solo quando l'intento cambia. Non a ogni sessione. Se lo riscrivi ogni volta,
diventa rumore e smetti di poterti fidare.

**Durata:** mesi. È il file più prezioso perché è l'unico che l'AI carica da sola.

**Regola di peso:** tutto ciò che scrivi qui finisce nel contesto di ogni sessione futura. Quindi
tutto ciò che scrivi qui deve valere la pena di rileggere duecento volte. Se un dettaglio conta solo
oggi, va in `HANDOFF.md`.

### Sezioni

| # | Sezione | Contenuto |
|---|---|---|
| 1 | **Obiettivo** | Due o tre righe. Cosa deve essere vero quando il progetto è finito. |
| 2 | **Stack** | Linguaggio, framework, versioni, gestore di pacchetti. Solo ciò che è davvero in uso. |
| 3 | **Comandi** | Build, test, lint, avvio. Il blocco di codice con i comandi esatti, così si copiano e basta. |
| 4 | **Convenzioni** | Come è scritto il codice qui: stile, naming, dove stanno i test, formato dei messaggi di commit. |
| 5 | **Vincoli** | Cosa **non** si tocca e perché. File generati, dipendenze bloccate, cose rotte da sistemare prima. |
| 6 | **Struttura** | Albero delle cartelle, una riga per cartella, cosa ci sta dentro. |
| 7 | **Documentazione** | Punti dove trovare altro. |

### Template

```markdown
# AGENTS — <nome progetto>

## 1. Obiettivo

<Cosa deve essere vero quando il progetto è finito. Due o tre righe.>

## 2. Stack

- **Linguaggio:** <es. Python 3.12>
- **Framework:** <es. none — solo librerie standard>
- **Dipendenze:** <es. nessuna, oppure package.json / requirements.txt>
- **Entry point:** <es. src/main.py>

## 3. Comandi

```bash
# build
<comando>

# test
<comando>

# lint / formattazione
<comando>

# esecuzione
<comando>
```

## 4. Convenzioni

- <linguaggio e stile del codice>
- <dove stanno i test e come si chiamano>
- <formato dei messaggi di commit>

## 5. Vincoli

- <cosa non si tocca, e perché>

## 6. Struttura

```
<albero delle cartelle con una riga di commento>
```

## 7. Documentazione

- <altro materiale utile>
```

---

## `HANDOFF.md` — la consegna

**Cosa descrive:** cosa fa la persona (o l'AI) che apre il progetto **adesso**, in una sessione
futura, magari domani, magari fra un mese.

**Chi lo modifica:** la skill `handoff`, a ogni sessione. Viene riscritto, non accodato.

**Durata:** una sessione. Il prossimo handoff lo sostituisce.

**Durata del file:** deve stare **su una pagina**. Se serve un allegato, vuol dire che è scritto
male: l'allegato va in `AGENTS.md` o nei file del progetto, non qui.

### L'ordine delle sezioni non è negoziabile

Chi apre `HANDOFF.md` spesso ha il context window pieno e legge solo le prime righe, o salta
all'inizio sperando di trovare subito la risposta. **Il compito vero va in cima**, non in fondo.

| # | Sezione | Contenuto |
|---|---|---|
| 0 | **Intestazione** | Data, cosa è cambiato dall'ultima volta, in una riga. |
| 1 | **Da fare adesso** | Il compito vero, in 10 righe. Comandi pronti da copiare. |
| 2 | **Stato verificato** | Cosa funziona, con il comando che lo dimostra. |
| 3 | **Cosa manca** | Quello che non è stato fatto, per importanza. |
| 4 | **Trappole note** | Cose che fanno perdere tempo se non sono scritte qui. |
| 5 | **Riferimenti** | File da aprire, comandi, URL. |

### Template

```markdown
# HANDOFF — <nome progetto>

**Aggiornato:** <YYYY-MM-DD> (prima versione: <YYYY-MM-DD>)
**Cambiato dall'ultima volta:** <una riga, o "prima versione">

---

## 1. Da fare adesso

<Il compito vero. Massimo 10 righe. Se serve un comando, mettilo in un blocco pronto da copiare.>

```bash
<comando>
```

## 2. Stato verificato

- ✅ <cosa funziona> — verificato con `<comando>`
- ❌ <cosa non funziona>

## 3. Cosa manca

1. <cosa manca, per importanza>

## 4. Trappole note

- <trappola: cosa succede, perché, come evitarla>

## 5. Riferimenti

- `<percorso>` — <cosa contiene>
```

---

## `TO-DO.md` — i task della sessione

**Cosa descrive:** il lavoro aperto **in questo momento**. Nient'altro.

**Chi lo modifica:** continuamente, durante il lavoro.

**Durata:** la sessione. Si consuma.

**Regola:** non è un archivio. I `[x]` non restano a occupare spazio. A fine sessione migrano in
`HANDOFF.md` come fatto-verificato e questo file si svuota.

### Stati

| Simbolo | Significato |
|---|---|
| `[ ]` | Da fare |
| `[x]` | Fatto **e verificato da un comando** |
| `[x]?` | Fatto ma non verificato. Da verificare. |
| `[~]` | Bloccato. Perché bloccato è scritto accanto. |

### Template

```markdown
# TO-DO — <nome progetto>

**Aggiornato:** <YYYY-MM-DD>

## Da fare

- [ ] <task>
- [x] <task> — verificato con `<comando>`
- [x]? <task> — non ancora verificato
- [~] <task> — bloccato perché <motivo>

## Note

<Il task critico, quello da cui dipende tutto il resto.>
```

---

## `AS-IS.md` — il drift

**Cosa descrive:** non lo stato attuale, ma **la distanza fra ciò che `AGENTS.md` prescrive e ciò che
il codice fa davvero**.

Questa è la distinzione che conta. Se `AS-IS.md` dicesse solo "lo stato attuale", sarebbe
l'ennesimo posto dove scrivere le stesse cose di `HANDOFF.md`. Invece risponde a una domanda sola:
**dove il progetto si è discostato da come doveva essere?**

Il drift si scopre **misurando** il progetto, non ricordandolo. È per questo che la skill `handoff`
esegue i comandi prima di scrivere.

**Chi lo modifica:** la skill `handoff`, a ogni sessione.

**Durata:** si riallinea a ogni sessione, ma le voci "chiuse" restano con la data.

### Template

```markdown
# AS-IS — dove il progetto si discosta da AGENTS.md

**Aggiornato:** <YYYY-MM-DD>

## Misurato

| Cosa dice AGENTS.md | Cosa c'è davvero | Scostamento |
|---|---|---|
| <prescrizione> | <realtà, con il comando che l'ha verificata> | <scostamento o "allineato"> |

## Scostamenti aperti

- **<descrizione>** — <perché è ancora aperto> — aperto dal <YYYY-MM-DD>

## Scostamenti chiusi

- ~~<descrizione>~~ — chiuso il <YYYY-MM-DD>

---

*Se la tabella è vuota e gli scostamenti chiusi sono vuoti, scrivere: `gap non ancora misurato`.*
```

---

## La regola di fondo

**Mai scrivere "fatto" senza il comando che lo dimostra.**

È l'unica regola che distingue un handoff utile da un riassunto decorativo. Un handoff pieno di
"ho sistemato il bug" e nessun comando non vale niente: la sessione dopo non può né verificarlo né
fidarsi. Un handoff con `✅ test passa — npm test` si verifica in tre secondi e si può costruire
sopra.

---

## Anti-pattern

| Non fare | Perché |
|---|---|
| Scrivere `<scrivi qui>` o `TODO` dentro i file generati | Un file pieno di segnaposto non verrà mai aggiornato. Meglio una sezione vuota detta "da definire". |
| Mettere i comandi solo in `HANDOFF.md` | Alla sessione dopo non ci sei e non hai i comandi. I comandi stanno in `AGENTS.md`. |
| Riscrivere `AGENTS.md` a ogni sessione | Diventa un registro di sessione. Sta in `AGENTS.md` solo ciò che vale per tutto il progetto. |
| Far crescere `HANDOFF.md` di sessione in sessione | Dopo tre sessioni nessuno lo legge. Si riscrive, non si accoda. |
| Lasciare i `[x]` in `TO-DO.md` per settimane | Il file muore. I task chiusi vanno in `HANDOFF.md`. |
| Dare nomi diversi ai quattro file | `AGENTS.md` non viene più caricato in automatico e il sistema perde il senso. |
| Scrivere in `AS-IS.md` le intenzioni future | `AS-IS.md` vale solo per ciò che hai **misurato**. Le intenzioni stanno in `AGENTS.md`. |
````

### File 4 — `~/.config/opencode/skills/handoff/SKILL.md`

````markdown
---
name: handoff
description: Use when ending, pausing or resuming a work session - the user says "handoff", "chiudi la sessione", "salva il contesto", "proseguo domani", "prendo appunti per dopo", "dove eravamo", or asks what to do next. Also use when work stops with tasks still open, or when resuming after a gap and the project's real state must be reconciled with what AGENTS.md prescribes.
---

# Handoff: la consegna per la sessione dopo

## Principio

**Mai scrivere "fatto" senza il comando che lo dimostra.**

Un handoff pieno di "ho sistemato il bug" e nessun comando non vale niente: la sessione dopo non
può né verificarlo né fidarsi. Un handoff con `test passa — npm test` si verifica in tre secondi e
ci si costruisce sopra.

Secondo principio, non meno importante: **il compito vero va in cima.** Chi apre `HANDOFF.md` ha il
context window pieno e spesso salta all'inizio sperando di trovare subito la risposta.

## Il contratto dei quattro file

**REQUIRED: leggi `~/.config/opencode/skills/gestione-contesto/references/struttura-progetto.md`**
prima di scrivere. Contiene le sezioni richieste e l'ordine esatto di ciascun file. L'ordine non è
negoziabile.

---

## Passo 1 — MISURA

Non scrivere l'handoff ricordandoti quello che hai fatto. Misuralo.

1. **Leggi `TO-DO.md`** e fai la lista di cosa risulta aperto.
2. **Esegui i comandi di build e test** presi dalla sezione "Comandi" di `AGENTS.md`. Riporta
   l'output reale, anche se è un errore. Se non ci sono comandi, prova a dedurli dal progetto.
3. **Confronta `AGENTS.md` con il codice**, voce per voce. Ogni riga della sezione 5 (vincoli) e
   della sezione 2 (stack) è un'affermazione da verificare. Questo confronto è il drift.
4. **Guarda il codice in cerca di scostamenti non dichiarati**: import rotti, TODO lasciati nel
   codice, funzioni che `AGENTS.md` descrive ma che non esistono, feature documentate e non
   implementate.

Il passo 3 e il 4 non si saltano. È l'unico motivo per cui esiste `AS-IS.md`.

## Passo 2 — SCRIVI

**`HANDOFF.md`** — si riscrive da capo, non si accoda. Le sezioni, in quest'ordine:

| # | Sezione | Contenuto |
|---|---|---|
| 0 | Intestazione | Data, "cambiato dall'ultima volta" in una riga |
| 1 | **Da fare adesso** | Il compito vero, max 10 righe, comandi pronti da copiare |
| 2 | Stato verificato | ✅/❌ con il comando che lo dimostra |
| 3 | Cosa manca | Per importanza |
| 4 | Trappole note | Cosa fa perdere tempo se non è scritto |
| 5 | Riferimenti | File da aprire, comandi, URL |

**`AS-IS.md`** — riallineato con i fatti misurati al passo 1, non con le intenzioni dichiarate.
Tabella a tre colonne: *cosa dice AGENTS.md* | *cosa c'è davvero* | *scostamento*. Poi gli scostamenti
aperti e quelli chiusi con la data.

**`TO-DO.md`** — si svuota. Ogni `[x]` migra in `HANDOFF.md` come fatto-verificato, con il comando.

## Passo 3 — CHIUDI

Un task che hai spuntato ma che **nessun comando conferma** non è `[x]`, è `[x]?`.

Non spuntare un task per far quadrare i numeri. Se non sei sicuro che il lavoro sia finito, lascialo
aperto e scrivi nella sezione "Da fare adesso" perché è la cosa che va chiarita per prima. È una
decisione onesta e molto più utile di una spunta falsa.

---

## Come scrivere la sezione "Da fare adesso"

Deve stare **in dieci righe** ed essere la prima cosa che si legge. È un pezzo di codice pronto da
copiare, non un paragrafo che descrive un paragrafo.

```markdown
## 1. Da fare adesso

1. Far partire i test: `npm test` fallisce su 3 casi in `auth.test.js`.
2. Il primo è un caso di `expiresAt` non rilett — vedi `src/auth.js:44`.
3. Poi sistemare l'import rotto in `src/report.py` (`from db import` non risolve da `tests/`).
4. Rilanciare `npm test` e aggiornare questo file.
```

Confronto con la stessa informazione scritta male, che è quello che esce di solito:

```markdown
## 1. Stato del lavoro

Ho implementato il sistema di autenticazione con scadenza e refresh token. Manca
ancora sistemare qualche dettaglio nei test e c'è un problema con un import, vediamo
poi. Il progetto è abbastanza avanti.
```

La seconda versione non dice nulla di azionabile, non ha comandi, e mette il compito vero in fondo
dove nessuno lo leggerà.

## Cosa NON fare

| Non fare | Perché |
|---|---|
| Non dimenticare `AS-IS.md` | È l'unico file che dice dove il progetto si discosta da AGENTS.md. Il passo 1 lo misura, il passo 2 lo scrive. Se non lo aggiorni, il drift siaccumula in silenzio |
| Non accodare sessioni a `HANDOFF.md` | Dopo tre sessioni nessuno lo legge. Si riscrive, non si accoda |
| Non dichiarare "tutto verde" senza averlo visto | "Test non eseguiti" è una riga onesta e utile. "Funziona" senza comando è rumore |
| Non riscrivere `AGENTS.md` | Quello si cambia solo quando cambia l'intento. Se durante la sessione hai scoperto un comando nuovo, aggiungilo pure quello, ma non stravolgere il file |
| Non creare file nuovi (`NOTES.md`, `PROGRESS.md`, `SCRATCH.md`) | Cinque file che dicono la stessa cosa divergono. Se serve una nota, sta dentro uno dei quattro |
| Non scrivere in `AS-IS.md` le intenzioni future | `AS-IS.md` vale solo per ciò che hai misurato. Le intenzioni stanno in `AGENTS.md` |
| Non fare un riassunto della conversazione | L'handoff non è "di cosa abbiamo parlato". È "cosa fa la persona che apre il progetto adesso" |

## Red flags — fermati e rifai

- Stai per scrivere `HANDOFF.md` senza aver eseguito nessun comando
- Stai per scrivere l'handoff senza la sezione "Da fare adesso" in cima
- `AS-IS.md` non è stato toccato
- Stai per scrivere "fatto", "risolto", "funziona" senza il comando accanto
- Stai per creare un quinto file per tenere una nota
- `HANDOFF.md` sta crescendo invece di essere riscritto

**Se vale una di queste, il passo 1 non è stato fatto. Torna a misurare.**
````

### File 5 — `~/.config/opencode/skills/nuovo-progetto/SKILL.md`

````markdown
---
name: nuovo-progetto
description: Use when starting a new project - the user says "nuovo progetto", "partiamo con X", "iniziamo Y", "progettiamo Z", "facciamo un'app per", or the working directory is empty or lacks AGENTS.md. Also use when asked to set up project memory, context files, or scaffolding documentation for a fresh codebase.
---

# Avvio di un nuovo progetto

## Principio

**Prima i quattro file di contesto, poi il codice.** Un progetto senza contesto scritto è un
progetto che si perde alla prima sessione.

Il file da creare per primo è `AGENTS.md`: è l'unico che opencode e Claude Code **caricano da
soli** all'avvio di ogni sessione. Se esiste, ogni sessione futura parte già informata.

## Il contratto dei quattro file

**REQUIRED: leggi `~/.config/opencode/skills/gestione-contesto/references/struttura-progetto.md`**
prima di scrivere qualsiasi file. Contiene la specificazione completa di ciascun file, le sezioni
richieste e i template. Non reinventare la struttura: le due skill (`nuovo-progetto` e `handoff`)
devono produrre file identici, e l'unico posto dove la struttura è definita è quel file.

| File | Ruolo | Quando si scrive |
|---|---|---|
| `AGENTS.md` | Memoria generale, l'intento | Una volta, poi solo se l'intento cambia |
| `HANDOFF.md` | La consegna per la sessione dopo | Alla nascita del progetto, poi a ogni handoff |
| `TO-DO.md` | I task aperti | Alla nascita, vuoto |
| `AS-IS.md` | Il drift fra AGENTS.md e la realtà | Alla nascita, con `gap non ancora misurato` |

---

## Passo 1 — Leggi prima di chiedere

L'utente ha spesso già risposto a metà delle domande senza accorgersene. Prima di fargli domande,
leggiti da solo:

- `~/.claude/CLAUDE.md` — istruzioni e convenzioni dell'utente
- `AGENTS.md`, `CLAUDE.md`, `README.md` nella cartella, se esistono già
- `package.json`, `pyproject.toml`, `requirements.txt`, `Cargo.toml`, `go.mod`, `.git/config`
- `CLAUDE.md` in una cartella superiore

Un domanda che hai già la risposta sul disco è una domanda che fa perdere tempo.

## Passo 2 — Fai le domande con il tool `question`

Una domanda per messaggio, mai una sfilza. Al massimo quattro, e solo quelle su cui non hai già
trovato risposta.

| # | Domanda | Opzioni tipiche |
|---|---|---|
| 1 | **Obiettivo**: in una frase, cosa dev'essere vero quando è finito? | libera |
| 2 | **Stack**: che linguaggio e framework? | Python / Node / Go / Rust / PHP / solo librerie standard / "non lo so" |
| 3 | **Comandi**: come si builda e come si testa? | libera + "non lo so ancora" |
| 4 | **Vincoli**: cosa non si deve toccare? | "niente" / "non lo so" |

Ogni domanda deve avere **sempre** l'opzione "non lo (so) ancora". Spesso le ultime due risposte
non le sai all'inizio, e va bene: nel file si scrive "da definire" e si aggiorna dopo.

Usa il campo `custom` per raccogliere risposte libere, non solo scelte multiple.

## Passo 3 — Scrivi i quattro file, in quest'ordine

1. `AGENTS.md` — con il contenuto vero
2. `HANDOFF.md` — con la prima consegna: cosa fare adesso
3. `TO-DO.md` — con i primi task
4. `AS-IS.md` — con la tabella e la riga `gap non ancora misurato`

Poi, e solo dopo, il codice o lo scaffolding che serve.

---

## Mai placeholder

Un file con dentro `<scrivi qui>`, `TODO` o `FIXME` **non verrà mai aggiornato**. Un file con dentro
`da definire — da chiarire con l'utente` invece è onesto e si aggiorna.

Scrivi il contenuto vero usando quello che hai letto al passo 1. Se hai letto un `package.json`,
`AGENTS.md` alla sezione "Stack" riporta i nomi e le versioni che ci sono dentro, non
`<linguaggio>`.

## Se il progetto esiste già

Non distruggere niente. Leggi i file che ci sono, **proponi** quello che manca, e chiedi prima di
sovrascrivere. Un `AGENTS.md` esistente è informazione, non un file da rifare.

Se esiste solo `README.md` o solo `TO-DO.md`, non è un progetto nuovo: è un progetto con contesto
parziale. Aggiungi quello che manca, senza toccare quello che c'è.

## Errori comuni

| Cosa succede | Perché è sbagliato | Cosa fare |
|---|---|---|
| "Nuovo progetto X" → scrivi subito il codice | Il progetto nasce senza contesto e muore alla prima sessione | I quattro file PRIMA. Vedi il principio in alto |
| Crei `README.md` al posto di `AGENTS.md` | `README.md` non viene caricato in automatico, `AGENTS.md` sì | `AGENTS.md`, e il `README.md` solo se serve a qualcuno |
| File chiamati `Agents.md`, `Hondoff.md`, `todo.md` | Le maiuscole sbagliate fanno perdere il caricamento automatico | `AGENTS.md`, `HANDOFF.md`, `TO-DO.md`, `AS-IS.md` — maiuscole |
| Tutti i file con i placeholder | Nessuno verrà mai aggiornato | Contenuto vero, "da definire" solo per ciò che davvero non sai |
| Salti `AS-IS.md` perché "non serve ancora" | È l'unico file che dice dove il progetto si discosta da AGENTS.md | Crealo con `gap non ancora misurato` |
| Crei anche `CLAUDE.md`, `NOTES.md`, `PROGRESS.md` | Cinque file che dicono la stessa cosa divergono | Solo i quattro. Se serve altro, sta dentro uno dei quattro |
| Salti `git init` senza chiederlo | `git init` è una decisione dell'utente, non tua | Chiedilo esplicitamente |

## Red flags — fermati e ricomincia

- Stai per scrivere `server.py`, `index.html` o `main.go` e i quattro file non esistono
- Stai per usare un nome di file diverso da `AGENTS.md` / `HANDOFF.md` / `TO-DO.md` / `AS-IS.md`
- Stai per mettere un `<placeholder>` dentro un file che stai creando adesso
- Stai per non fare nessuna domanda perché "è tutto chiaro"

**Se vale una di queste, il passo 3 non è stato eseguito. Torna indietro.**
````

---

*Fine del prompt. Dopo che opencode ha creato i cinque file, riavvia opencode. Prova a scrivere
"nuovo progetto" per attivare `nuovo-progetto`, o "handoff" per attivare `handoff`.*
