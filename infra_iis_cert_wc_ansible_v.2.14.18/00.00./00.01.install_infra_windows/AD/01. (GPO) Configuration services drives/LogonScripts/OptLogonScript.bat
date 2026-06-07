@echo off
setlocal enabledelayedexpansion
chcp 1252 >nul

:: =============================================================================
:: AUTHOR  : Driss BENELKAID - optimedit.fr@gmail.com
:: DATE    : 28/12/2025
:: VERSION : 0.1
:: DESC    : Mappage reseau universel base sur les droits d'acces.
:: =============================================================================

:: =============================================================================
:: 1. CONFIGURATION - A ADAPTER POUR AUTRE CLIENT
:: =============================================================================
set "ServerName=opt-dc01"
set "FileServer=\\%ServerName%"
set "PathToTest=%FileServer%\OPT_Commun"
set "LogFile=%TEMP%\LogonDrives_OptimedIt.log"

:: Nettoyage du vieux log pour eviter les conflits d'encodage
if exist "%LogFile%" del /f /q "%LogFile%"

:: Commande de log avec heure reelle (PowerShell)
set "WriteLog=powershell -Command "$now = Get-Date -Format 'dd/MM/yyyy HH:mm:ss'; Out-File -FilePath '%LogFile%' -Append -InputObject \"[$now] "

:: =============================================================================
:: 2. INITIALISATION ET ATTENTE RESEAU
:: =============================================================================
%WriteLog% --- DEBUT DE SESSION : %username% ---\""
%WriteLog% Execution script netlogon : OptLogonScript.bat\""
%WriteLog% Stabilisation reseau (20s)...\"""

:: On attend reellement 20 secondes
timeout /t 20 /nobreak >nul

set /a RetryCount=0
:WAIT_LOOP
if exist "%PathToTest%" goto NETWORK_READY
if %RetryCount% geq 10 goto NETWORK_FAILED
set /a RetryCount+=1
%WriteLog% ATTENTE : Serveur injoignable (Tentative %RetryCount%/10)\""
timeout /t 5 /nobreak >nul
goto :WAIT_LOOP

:NETWORK_FAILED
%WriteLog% FATAL : Reseau ou serveur injoignable apres 10 tentatives.\""
goto :END_LOG

:NETWORK_READY
:: =============================================================================
:: 3. NETTOYAGE ET MAPPAGE
:: =============================================================================
%WriteLog% Nettoyage des anciennes connexions reseau...\""
net use * /delete /y >nul 2>&1
timeout /t 2 /nobreak >nul

:: --- LISTE DES LECTEURS - A ADAPTER POUR AUTRE CLIENT ---
call :MapDrive K: "%FileServer%\OPT_Commun"
call :MapDrive T: "%FileServer%\OPT_Direction"
call :MapDrive R: "%FileServer%\OPT_RH"
call :MapDrive M: "%FileServer%\OPT_Compta"
call :MapDrive V: "%FileServer%\OPT_Dev"
call :MapDrive W: "%FileServer%\OPT_Prod"
call :MapDrive I: "%FileServer%\OPT_IT"

:: =============================================================================
:: 4. FIN DU SCRIPT ET OUVERTURE LOG
:: =============================================================================
:END_LOG
%WriteLog% --- FIN DU SCRIPT POUR %username% ---\""

:: OUVERTURE DU LOG POUR VERIFICATION (A desactiver avant GPO)
start "" notepad "%LogFile%"

exit /b

:: =============================================================================
:: FONCTION DE MAPPAGE
:: =============================================================================
:MapDrive
set "DriveLtr=%~1"
set "DrivePath=%~2"

if exist "%DrivePath%\*" (
    net use %DriveLtr% /delete /y >nul 2>&1
    net use %DriveLtr% "%DrivePath%" /persistent:no >nul 2>&1
    
    if exist %DriveLtr% (
        %WriteLog% SUCCES : %DriveLtr% monte sur %DrivePath%\""
    ) else (
        %WriteLog% ERREUR : Echec montage %DriveLtr%\""
    )
) else (
    %WriteLog% INFO : Acces non autorise pour %DrivePath%\""
)
goto :eof