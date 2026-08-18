::DownloadInstall-Ollama.bat

:: Downloads and installs the portable Ollama application.
:: Determines the latest Ollama release and stores the downloaded
:: archive using the Ollama version number.
:: Provides the local Ollama engine and its model-serving functionality.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Ollama Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE OLLAMA
echo        INSIDE ESTABLISHED _ENGINE_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SSL_CERT_FILE (
echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
pause
exit /b 1
)

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

set "_PS_FILE=%TEMP%\ollama_install.ps1"

call :WritePowerShell > "%_PS_FILE%"

if not exist "%_PS_FILE%" (
echo ERROR: Failed creating PowerShell installer
pause
exit /b 1
)

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-File "%_PS_FILE%"

if errorlevel 1 (
echo ====================================================
echo       OLLAMA INSTALL FAILED
echo ====================================================
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_ENGINE_DIR=%%%%SCRIPT_DIR%%%%\Ollama"
if errorlevel 1 (
echo ERROR: Failed adding _ENGINE_DIR to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "OLLAMA_MODELS=%%%%SCRIPT_DIR%%%%\Models"
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

echo ====================================================
echo       OLLAMA INSTALL COMPLETE
echo ====================================================
echo.
echo Ollama directory: %_ENGINE_DIR%
echo Model directory:  %_OLLAMA_MODELS%
echo.

pause

endlocal
exit /b 0


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
echo     -Headers $Headers `
echo     -UseBasicParsing
echo.
echo if (-not $Release.tag_name) {
echo     throw "Unable to determine the latest Ollama release."
echo }
echo.
echo $LatestVersion = $Release.tag_name
echo $LatestVersion = $LatestVersion.TrimStart("v")
echo.
echo Write-Host "Latest stable Ollama: v$LatestVersion"
echo.
echo $ArchiveName = "ollama-windows-amd64-$LatestVersion.zip"
echo $Archive = Join-Path $DownloadDir $ArchiveName
echo $OllamaExe = Join-Path $OllamaDir "ollama.exe"
echo.
echo $DownloadUrl = "https://github.com/ollama/ollama/releases/download/v$LatestVersion/ollama-windows-amd64.zip"
echo.
echo $InstalledVersion = $null
echo.
echo if (Test-Path $OllamaExe) {
echo     Write-Host "Checking installed Ollama version"
echo     try {
echo         $VersionOutput = ^& $OllamaExe --version 2^>^&1
echo         if ($LASTEXITCODE -eq 0) {
echo             $InstalledVersion = [regex]::Match(
echo                 ($VersionOutput ^| Out-String),
echo                 '(\d+\.\d+\.\d+)'
echo             ).Value
echo         }
echo     }
echo     catch {
echo         $InstalledVersion = $null
echo     }
echo }
echo.
echo if ($InstalledVersion) {
echo     Write-Host "Installed Ollama: v$InstalledVersion"
echo }
echo.
echo if ($InstalledVersion -eq $LatestVersion) {
echo     Write-Host "Ollama v$LatestVersion is already installed."
echo     Write-Host "No download or extraction required."
echo }
echo else {
echo     if (-not (Test-Path $Archive)) {
echo         Write-Host "Downloading Ollama v$LatestVersion"
echo         Write-Host "Archive: $ArchiveName"
echo         Write-Host "Using native Windows curl.exe"
echo.
echo         ^& curl.exe `
echo             -L `
echo             --fail `
echo             --retry 3 `
echo             --retry-delay 2 `
echo             -o $Archive `
echo             $DownloadUrl
echo.
echo         if ($LASTEXITCODE -ne 0) {
echo             throw "Ollama download failed with curl exit code $LASTEXITCODE."
echo         }
echo     }
echo     else {
echo         Write-Host "Ollama v$LatestVersion archive already exists."
echo         Write-Host "Skipping download."
echo     }
echo.
echo     if (-not (Test-Path $Archive)) {
echo         throw "Ollama archive was not downloaded."
echo     }
echo.
echo     Write-Host "Installing Ollama v$LatestVersion"
echo.
echo     Expand-Archive `
echo         -Path $Archive `
echo         -DestinationPath $OllamaDir `
echo         -Force
echo.
echo     if (-not (Test-Path $OllamaExe)) {
echo         throw "ollama.exe was not found after extraction."
echo     }
echo }
echo.
echo Write-Host "Verifying portable Ollama"
echo.
echo if (-not (Test-Path $OllamaExe)) {
echo     throw "ollama.exe was not found: $OllamaExe"
echo }
echo.
echo $FileInfo = Get-Item $OllamaExe
echo.
echo if ($FileInfo.Length -le 0) {
echo     throw "ollama.exe is empty."
echo }
echo.
echo Write-Host "Ollama executable found:"
echo Write-Host $OllamaExe
echo Write-Host ("Executable size: {0:N0} bytes" -f $FileInfo.Length)
echo Write-Host "Portable Ollama verified"
echo.
exit /b 0
