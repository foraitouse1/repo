::DownloadInstall-Ollama.bat

:: Downloads the latest Ollama Windows installer.
:: Stores the installer using its version number.
:: Adds Ollama environment variables to IsolateEnv-Project.bat.
:: Launches the Ollama Windows installer and then terminates.
::
:: The Windows installer is responsible for installing and
:: launching the Ollama Windows application.
::
:: This script intentionally performs NO post-install verification.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Ollama Windows Installer Launcher
:: ====================================================


:: ====================================================
:: Initialize Isolated Environment
:: ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined SSL_CERT_FILE (
    echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
    pause
    exit /b 1
)


:: ====================================================
:: Ollama Directories
:: ====================================================

set "_ENGINE_DIR=%SCRIPT_DIR%\Ollama"
set "_OLLAMA_MODELS=%SCRIPT_DIR%\Models"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%\Downloads"

if not exist "%_DOWNLOAD_DIR%" (
    mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_ENGINE_DIR%" (
    mkdir "%_ENGINE_DIR%"
)

if not exist "%_OLLAMA_MODELS%" (
    mkdir "%_OLLAMA_MODELS%"
)


:: ====================================================
:: Create Temporary PowerShell Worker
:: ====================================================

set "_PS_FILE=%TEMP%\ollama_install_%RANDOM%.ps1"

call :WritePowerShell > "%_PS_FILE%"

if not exist "%_PS_FILE%" (
    echo ERROR: Failed creating PowerShell installer
    pause
    exit /b 1
)


:: ====================================================
:: Add Ollama Environment Variables
:: ====================================================

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_ENGINE_DIR=%%%%SCRIPT_DIR%%%%Ollama"

if errorlevel 1 (
    echo ERROR: Failed adding _ENGINE_DIR to IsolateEnv-Project.bat
    pause
    exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "OLLAMA_MODELS=%%%%SCRIPT_DIR%%%%Models"

if errorlevel 1 (
    echo ERROR: Failed adding OLLAMA_MODELS to IsolateEnv-Project.bat
    pause
    exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%SCRIPT_DIR%%%%Ollama;%%%%PATH%%%%"
if errorlevel 1 (
echo ERROR: Failed adding Ollama to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)


:: ====================================================
:: Download / Launch Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE OLLAMA
echo ====================================================
echo.
echo Ollama directory: %_ENGINE_DIR%
echo Model directory:  %_OLLAMA_MODELS%
echo Ollama port:      11434
echo.

powershell.exe ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -File "%_PS_FILE%"

set "_ERR=%ERRORLEVEL%"


if not "%_ERR%"=="0" (
    echo.
    echo ====================================================
    echo       OLLAMA INSTALLER LAUNCH FAILED
    echo ====================================================
    pause
    endlocal
    exit /b %_ERR%
)


:: ====================================================
:: Done
:: ====================================================

echo.
echo ====================================================
echo       OLLAMA INSTALLER LAUNCHED
echo ====================================================
echo.
echo The Ollama Windows installer is now running.
echo This script does not wait for or verify the installation.
echo.

endlocal
exit /b 0


:: ====================================================
:: PowerShell Worker
:: ====================================================

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $OllamaDir = "%_ENGINE_DIR%"
echo.
echo $ReleaseApi = "https://api.github.com/repos/ollama/ollama/releases/latest"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $OllamaDir)) {
echo     New-Item -ItemType Directory -Path $OllamaDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable Ollama release"
echo.
echo $Headers = @{
echo     "User-Agent" = "Portable-Ollama-Installer"
echo     "Accept" = "application/vnd.github+json"
echo }
echo.
echo $Release = Invoke-RestMethod `
echo     -Uri $ReleaseApi `
echo     -Headers $Headers
echo.
echo if (-not $Release.tag_name) {
echo     throw "Unable to determine the latest Ollama release."
echo }
echo.
echo $LatestVersion = $Release.tag_name.TrimStart("v")
echo.
echo Write-Host "Latest stable Ollama: v$LatestVersion"
echo.
echo $InstallerName = "OllamaSetup-$LatestVersion.exe"
echo $Installer = Join-Path $DownloadDir $InstallerName
echo $DownloadUrl = "https://github.com/ollama/ollama/releases/download/v$LatestVersion/$InstallerName"
echo.
echo Write-Host "Installer: $InstallerName"
echo.
echo if (-not (Test-Path $Installer)) {
echo     Write-Host "Downloading Ollama v$LatestVersion"
echo     Write-Host "Archive: $InstallerName"
echo     Write-Host "Using native Windows curl.exe"
echo     Write-Host
echo.
echo     $Curl = Get-Command curl.exe -ErrorAction Stop
echo.
echo     ^& $Curl.Source `
echo         "--fail" `
echo         "--location" `
echo         "--retry" "3" `
echo         "--retry-delay" "2" `
echo         "-o" $Installer `
echo         $DownloadUrl
echo.
echo     if ($LASTEXITCODE -ne 0) {
echo         throw "Ollama download failed with curl exit code $LASTEXITCODE."
echo     }
echo }
echo else {
echo     Write-Host "Ollama installer already exists."
echo     Write-Host "Skipping download."
echo }
echo.
echo if (-not (Test-Path $Installer)) {
echo     throw "Ollama installer was not downloaded."
echo }
echo.
echo Write-Host
echo Write-Host "Launching Ollama Windows application v$LatestVersion"
echo Write-Host "Installation directory: $OllamaDir"
echo.
echo Start-Process `
echo     -FilePath $Installer `
echo     -ArgumentList "/DIR=`"$OllamaDir`""
echo.
echo Write-Host "Ollama Windows installer launched."
echo.
exit /b 0
