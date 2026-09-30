@echo off
setlocal
title Setup Lezione IA

rem --- NIENTE permessi di amministratore: lo script deve girare come lo studente,
rem --- cosi' cartelle, PATH e chiave opencode finiscono nel profilo giusto.
rem --- Avviare con DOPPIO CLIC, non con "Esegui come amministratore".

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-LezioneAI.ps1" %*

echo.
echo Premi un tasto per chiudere.
pause >nul
