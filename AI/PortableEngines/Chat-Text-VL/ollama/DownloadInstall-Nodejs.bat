::DownloadInstall-Nodejs.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Node.js Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE NODE.JS
echo        INSIDE ESTABLISHED _NODEJS_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SSL_CERT_FILE (
echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
pause
exit /b 1
)

set "_NODEJS_DIR=%SCRIPT_DIR%\Nodejs"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_NODEJS_DIR%" (
mkdir "%_NODEJS_DIR%"
)

set "_PS_FILE=%TEMP%\nodejs_install.ps1"

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
echo       NODE.JS INSTALL FAILED
echo ====================================================
del "%_PS_FILE%" >nul 2>&1
pause
exit /b 1
)

del "%_PS_FILE%" >nul 2>&1

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_NODEJS_DIR=%%%%SCRIPT_DIR%%%%\Nodejs"
if errorlevel 1 (
echo ERROR: Failed adding _NODEJS_DIR to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%PATH%%%%;%%%%SCRIPT_DIR%%%%\Nodejs"
if errorlevel 1 (
echo ERROR: Failed adding Node.js to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)

echo ====================================================
echo       NODE.JS INSTALL COMPLETE
echo ====================================================
echo.
echo Node.js directory: %_NODEJS_DIR%
echo.

pause

endlocal
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $NodeDir = "%_NODEJS_DIR%"
echo $IndexUrl = "https://nodejs.org/dist/index.json"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $NodeDir)) {
echo     New-Item -ItemType Directory -Path $NodeDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable Node.js LTS release"
echo.
echo $Releases = Invoke-RestMethod `
echo     -Uri $IndexUrl `
echo     -UseBasicParsing
echo.
echo $Latest = $Releases ^|
echo     Where-Object { $_.lts -ne $false -and $_.lts } ^|
echo     Sort-Object { [version]($_.version.TrimStart("v")) } -Descending ^|
echo     Select-Object -First 1
echo.
echo if (-not $Latest) {
echo     throw "Unable to determine the latest stable Node.js LTS release."
echo }
echo.
echo $Version = $Latest.version
echo $FileName = "node-$Version-win-x64.zip"
echo $Url = "https://nodejs.org/dist/$Version/$FileName"
echo $Archive = Join-Path $DownloadDir $FileName
echo $NodeExe = Join-Path $NodeDir "node.exe"
echo $NpmCmd = Join-Path $NodeDir "npm.cmd"
echo $NpxCmd = Join-Path $NodeDir "npx.cmd"
echo $TempDir = Join-Path $DownloadDir "NodejsExtract"
echo.
echo Write-Host "Latest stable Node.js LTS: $Version"
echo.
echo if (-not (Test-Path $Archive)) {
echo     Write-Host "Downloading $FileName"
echo     Invoke-WebRequest `
echo         -Uri $Url `
echo         -OutFile $Archive `
echo         -UseBasicParsing
echo }
echo.
echo if (-not (Test-Path $Archive)) {
echo     throw "Node.js archive was not downloaded."
echo }
echo.
echo $InstallRequired = $true
echo.
echo if ((Test-Path $NodeExe) -and (Test-Path $NpmCmd) -and (Test-Path $NpxCmd)) {
echo     $InstalledVersion = ^& $NodeExe --version
echo     if ($InstalledVersion -eq $Version) {
echo         $InstallRequired = $false
echo         Write-Host "Node.js $Version is already installed."
echo     }
echo }
echo.
echo if ($InstallRequired) {
echo     if (Test-Path $TempDir) {
echo         Remove-Item $TempDir -Recurse -Force
echo     }
echo.
echo     New-Item -ItemType Directory -Path $TempDir -Force ^| Out-Null
echo.
echo     Write-Host "Extracting Node.js $Version"
echo     Expand-Archive `
echo         -Path $Archive `
echo         -DestinationPath $TempDir `
echo         -Force
echo.
echo     $Root = Get-ChildItem $TempDir -Directory ^| Select-Object -First 1
echo     if (-not $Root) {
echo         throw "Node.js archive did not contain an installation directory."
echo     }
echo.
echo     Get-ChildItem $NodeDir -Force ^| Remove-Item -Recurse -Force
echo     Get-ChildItem $Root.FullName -Force ^| Move-Item -Destination $NodeDir -Force
echo.
echo     Remove-Item $TempDir -Recurse -Force
echo }
echo.
echo if (-not (Test-Path $NodeExe)) {
echo     throw "node.exe was not found after installation."
echo }
echo.
echo if (-not (Test-Path $NpmCmd)) {
echo     throw "npm.cmd was not found after installation."
echo }
echo.
echo if (-not (Test-Path $NpxCmd)) {
echo     throw "npx.cmd was not found after installation."
echo }
echo.
echo Write-Host "Verifying Node.js"
echo.
echo $NodeVersion = ^& $NodeExe --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "Node.js verification failed."
echo }
echo.
echo $NpmVersion = ^& $NpmCmd --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "npm verification failed."
echo }
echo.
echo $NpxVersion = ^& $NpxCmd --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "npx verification failed."
echo }
echo.
echo Write-Host $NodeVersion
echo Write-Host "npm $NpmVersion"
echo Write-Host "npx $NpxVersion"
echo Write-Host "Portable Node.js verified"
echo.
exit /b 0
