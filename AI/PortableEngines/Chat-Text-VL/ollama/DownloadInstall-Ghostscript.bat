::DownloadInstall-Ghostscript.bat

:: Downloads and installs the portable Ghostscript distribution.
:: Provides PDF and PostScript processing used by ImageMagick and other components.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Ghostscript Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE GHOSTSCRIPT
echo        INSIDE ESTABLISHED _GHOSTSCRIPT_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SSL_CERT_FILE (
echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
pause
exit /b 1
)

set "_GHOSTSCRIPT_DIR=%SCRIPT_DIR%\Ghostscript"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_GHOSTSCRIPT_DIR%" (
mkdir "%_GHOSTSCRIPT_DIR%"
)

set "_PS_FILE=%TEMP%\ghostscript_install.ps1"

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
echo       GHOSTSCRIPT INSTALL FAILED
echo ====================================================
del "%_PS_FILE%" >nul 2>&1
pause
exit /b 1
)

del "%_PS_FILE%" >nul 2>&1

if not defined _GHOSTSCRIPT_VERSION (
echo ERROR: Ghostscript version was not determined
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_GHOSTSCRIPT_DIR=%%%%SCRIPT_DIR%%%%\Ghostscript"
if errorlevel 1 (
echo ERROR: Failed adding _GHOSTSCRIPT_DIR to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_GHOSTSCRIPT_VERSION=%_GHOSTSCRIPT_VERSION%"
if errorlevel 1 (
echo ERROR: Failed adding _GHOSTSCRIPT_VERSION to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%PATH%%%%;%%%%SCRIPT_DIR%%%%\Ghostscript\gs%_GHOSTSCRIPT_VERSION%\bin"
if errorlevel 1 (
echo ERROR: Failed adding Ghostscript to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "GS_DLL=%%%%SCRIPT_DIR%%%%\Ghostscript\gs%_GHOSTSCRIPT_VERSION%\bin\gsdll64.dll"
if errorlevel 1 (
echo ERROR: Failed adding GS_DLL to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "GS_LIB=%%%%SCRIPT_DIR%%%%\Ghostscript\gs%_GHOSTSCRIPT_VERSION%\bin;%%%%SCRIPT_DIR%%%%\Ghostscript\gs%_GHOSTSCRIPT_VERSION%\lib;%%%%SCRIPT_DIR%%%%\Ghostscript\fonts"
if errorlevel 1 (
echo ERROR: Failed adding GS_LIB to IsolateEnv-Project.bat
pause
exit /b 1
)

echo ====================================================
echo       GHOSTSCRIPT INSTALL COMPLETE
echo ====================================================
echo.
echo Ghostscript directory: %_GHOSTSCRIPT_DIR%
echo Ghostscript version:   %_GHOSTSCRIPT_VERSION%
echo.

pause

endlocal
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $GhostscriptDir = "%_GHOSTSCRIPT_DIR%"
echo $ApiUrl = "https://api.github.com/repos/ArtifexSoftware/ghostpdl-downloads/releases"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $GhostscriptDir)) {
echo     New-Item -ItemType Directory -Path $GhostscriptDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable Ghostscript release"
echo.
echo $Releases = Invoke-RestMethod `
echo     -Uri $ApiUrl `
echo     -Headers @{ "User-Agent" = "PortableGhostscriptInstaller" } `
echo     -UseBasicParsing
echo.
echo $Latest = $Releases ^|
echo     Where-Object { $_.prerelease -eq $false -and $_.tag_name -match '^gs[0-9]+$' } ^|
echo     Select-Object -First 1
echo.
echo if (-not $Latest) {
echo     throw "Unable to determine the latest stable Ghostscript release."
echo }
echo.
echo $Version = $Latest.name -replace '^.*?([0-9]+\.[0-9]+\.[0-9]+).*$', '$1'
echo if ($Version -notmatch '^[0-9]+\.[0-9]+\.[0-9]+$') {
echo     throw "Unable to determine the Ghostscript version."
echo }
echo.
echo $Asset = $Latest.assets ^|
echo     Where-Object { $_.name -match '^gs[0-9]+w64\.exe$' } ^|
echo     Select-Object -First 1
echo.
echo if (-not $Asset) {
echo     throw "No 64-bit Ghostscript Windows installer was found."
echo }
echo.
echo $FileName = $Asset.name
echo $Url = $Asset.browser_download_url
echo $Installer = Join-Path $DownloadDir $FileName
echo $VersionDir = Join-Path $GhostscriptDir "gs$Version"
echo $GhostscriptExe = Join-Path $VersionDir "bin\gswin64c.exe"
echo.
echo Write-Host "Latest stable Ghostscript: $Version"
echo.
echo if (-not (Test-Path $Installer)) {
echo     Write-Host "Downloading $FileName"
echo     Invoke-WebRequest `
echo         -Uri $Url `
echo         -OutFile $Installer `
echo         -UseBasicParsing
echo }
echo.
echo if (-not (Test-Path $Installer)) {
echo     throw "Ghostscript installer was not downloaded."
echo }
echo.
echo $InstallRequired = $true
echo.
echo if (Test-Path $GhostscriptExe) {
echo     $InstalledVersion = ^& $GhostscriptExe --version
echo     if ($InstalledVersion -eq $Version) {
echo         $InstallRequired = $false
echo         Write-Host "Ghostscript $Version is already installed."
echo     }
echo }
echo.
echo if ($InstallRequired) {
echo     Write-Host "Installing Ghostscript $Version"
echo.
echo     $Process = Start-Process `
echo         -FilePath $Installer `
echo         -ArgumentList @(
echo             "/S"
echo             "/D$GhostscriptDir"
echo         ) `
echo         -Wait `
echo         -PassThru
echo.
echo     if ($Process.ExitCode -ne 0) {
echo         throw "Ghostscript installer failed with exit code $($Process.ExitCode)."
echo     }
echo }
echo.
echo if (-not (Test-Path $GhostscriptExe)) {
echo     throw "gswin64c.exe was not found after installation."
echo }
echo.
echo Write-Host "Verifying Ghostscript"
echo.
echo $GhostscriptVersion = ^& $GhostscriptExe --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "Ghostscript verification failed."
echo }
echo.
echo $VersionFile = Join-Path $env:TEMP "ghostscript_version.txt"
echo Set-Content -Path $VersionFile -Value $Version -Encoding ASCII
echo.
echo Write-Host $GhostscriptVersion
echo Write-Host "Portable Ghostscript verified"
echo.
exit /b 0
