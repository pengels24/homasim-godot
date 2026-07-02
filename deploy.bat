@echo off
echo ==============================================
echo  HO-MA-SIM: itch.io Deployment Script
echo ==============================================
echo.

:: Konfiguration
set BUTLER_PATH=_work\butler\butler.exe
set TARGET=angelus2010/homasim-hotel-manager-simulation

echo Pruefe, ob Butler installiert ist...
if not exist "%BUTLER_PATH%" (
    echo [FEHLER] butler.exe wurde nicht unter %BUTLER_PATH% gefunden!
    echo Bitte lade butler herunter und entpacke es in den Ordner _work\butler.
    echo Download: https://broth.itch.ovh/butler/windows-amd64/LATEST/archive/default
    pause
    exit /b
)

echo Lese Version aus version.txt...
set /p VERSION=<version.txt
echo Aktuelle Version: %VERSION%

echo.
echo ==============================================
echo  Pushe Windows-Build...
echo ==============================================
"%BUTLER_PATH%" push builds\windows %TARGET%:win64 --userversion "%VERSION%"

echo.
echo ==============================================
echo  Pushe Linux-Build...
echo ==============================================
"%BUTLER_PATH%" push builds\linux %TARGET%:linux --userversion "%VERSION%"

echo.
echo ==============================================
echo  Pushe Mac-Build...
echo ==============================================
"%BUTLER_PATH%" push builds\macos %TARGET%:mac --userversion "%VERSION%"
echo.
echo ==============================================
echo  Deployment abgeschlossen!
echo ==============================================
pause
