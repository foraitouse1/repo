::DownloadInstall-CACert.bat

:: Downloads the current CA certificate bundle for the portable environment.
:: Provides trusted SSL/TLS certificates for secure HTTPS connections.

:: └─ Cdrive
::    └─ Common
::       └─ cacert.pem

@echo off
setlocal EnableExtensions DisableDelayedExpansion

echo ====================================================
echo       INSTALLING PORTABLE CA CERTIFICATE
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

set "SSL_CERT_FILE=%COMMONPROGRAMFILES%\cacert.pem"

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-Command "Invoke-WebRequest -Uri 'https://curl.se/ca/cacert.pem' -OutFile '%SSL_CERT_FILE%' -UseBasicParsing"

if not exist "%SSL_CERT_FILE%" (
    echo ERROR: cacert.pem download failed
    pause
    exit /b 1
)

::add new env var for downline scripts
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "SSL_CERT_FILE=%%%%COMMONPROGRAMFILES%%%%\cacert.pem"

echo.
echo ====================================================
echo       CA CERTIFICATE INSTALL COMPLETE
echo ====================================================
echo.
echo SSL_CERT_FILE: %SSL_CERT_FILE%
echo.
pause

endlocal
exit /b 0