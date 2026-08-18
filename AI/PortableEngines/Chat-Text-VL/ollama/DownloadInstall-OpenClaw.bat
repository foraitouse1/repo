::DownloadInstall-OpenClaw.bat

:: Downloads the latest OpenClaw package.
:: Stores the package using its version number.
:: Installs OpenClaw into the isolated project.
:: Adds the OpenClaw environment variable to
:: IsolateEnv-Project.bat.
::
:: This script intentionally performs NO
:: post-install onboarding or daemon setup.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable OpenClaw Installer
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
:: OpenClaw Directories
:: ====================================================

set "_OPENCLAW_HOME=%SCRIPT_DIR%\OpenClaw"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%\Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_OPENCLAW_HOME%" (
mkdir "%_OPENCLAW_HOME%"
)


:: ====================================================
:: Create Temporary PowerShell Worker
:: ====================================================

set "_PS_FILE=%TEMP%\openclaw_install_%RANDOM%.ps1"

call :WritePowerShell > "%_PS_FILE%"

if not exist "%_PS_FILE%" (
echo ERROR: Failed creating PowerShell installer
pause
exit /b 1
)


:: ====================================================
:: Add OpenClaw Environment Variable
:: ====================================================

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "OPENCLAW_HOME=%%%%SCRIPT_DIR%%%%OpenClaw"

if errorlevel 1 (
echo ERROR: Failed adding OPENCLAW_HOME to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%OPENCLAW_HOME%%%%;%%%%PATH%%%%"

if errorlevel 1 (
echo ERROR: Failed adding OpenClaw to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)


:: ====================================================
:: Download / Install OpenClaw
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE OPENCLAW
echo ====================================================
echo.
echo OpenClaw directory: %_OPENCLAW_HOME%
echo.

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-File "%_PS_FILE%"

set "_ERR=%ERRORLEVEL%"


if not "%_ERR%"=="0" (
echo.
echo ====================================================
echo       OPENCLAW INSTALL FAILED
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
echo       OPENCLAW INSTALL COMPLETE
echo ====================================================
echo.
echo OpenClaw directory:
echo %_OPENCLAW_HOME%
echo.
echo This script does not run onboarding.
echo This script does not install a daemon.
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
echo $OpenClawDir = "%_OPENCLAW_HOME%"
echo.
echo $RegistryUrl = "https://registry.npmjs.org/openclaw/latest"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $OpenClawDir)) {
echo     New-Item -ItemType Directory -Path $OpenClawDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable OpenClaw release"
echo.
echo $Curl = Get-Command curl.exe -ErrorAction Stop
echo.
echo $MetadataFile = Join-Path $DownloadDir "openclaw-latest.json"
echo.
echo ^& $Curl.Source `
echo     "--fail" `
echo     "--location" `
echo     "--retry" "3" `
echo     "--retry-delay" "2" `
echo     "-o" $MetadataFile `
echo     $RegistryUrl
echo.
echo if ($LASTEXITCODE -ne 0) {
echo     throw "OpenClaw registry request failed with curl exit code $LASTEXITCODE."
echo }
echo.
echo if (-not (Test-Path $MetadataFile)) {
echo     throw "OpenClaw package metadata was not downloaded."
echo }
echo.
echo $Release = Get-Content -Raw -Path $MetadataFile ^| ConvertFrom-Json
echo.
echo if (-not $Release.version) {
echo     throw "Unable to determine the latest OpenClaw release."
echo }
echo.
echo $LatestVersion = $Release.version
echo $PackageName = "openclaw-$LatestVersion.tgz"
echo $Package = Join-Path $DownloadDir $PackageName
echo $DownloadUrl = $Release.dist.tarball
echo.
echo Write-Host "Latest stable OpenClaw: v$LatestVersion"
echo Write-Host "Package: $PackageName"
echo.
echo if (-not (Test-Path $Package)) {
echo     Write-Host "Downloading OpenClaw v$LatestVersion"
echo     Write-Host "Archive: $PackageName"
echo     Write-Host "Using native Windows curl.exe"
echo     Write-Host
echo.
echo     ^& $Curl.Source `
echo         "--fail" `
echo         "--location" `
echo         "--retry" "3" `
echo         "--retry-delay" "2" `
echo         "-o" $Package `
echo         $DownloadUrl
echo.
echo     if ($LASTEXITCODE -ne 0) {
echo         throw "OpenClaw download failed with curl exit code $LASTEXITCODE."
echo     }
echo }
echo else {
echo     Write-Host "OpenClaw package already exists."
echo     Write-Host "Skipping download."
echo }
echo.
echo if (-not (Test-Path $Package)) {
echo     throw "OpenClaw package was not downloaded."
echo }
echo.
echo Write-Host
echo Write-Host "Checking Node.js and npm"
echo.
echo $Node = Get-Command node.exe -ErrorAction SilentlyContinue
echo $Npm = Get-Command npm.cmd -ErrorAction SilentlyContinue
echo.
echo if (-not $Node) {
echo     throw "Node.js was not found in the isolated PATH."
echo }
echo.
echo if (-not $Npm) {
echo     throw "npm was not found in the isolated PATH."
echo }
echo.
echo $NodeVersion = ^& $Node.Source --version
echo $NpmVersion = ^& $Npm.Source --version
echo.
echo Write-Host "Node.js: $NodeVersion"
echo Write-Host "npm:     $NpmVersion"
echo.
echo Write-Host
echo Write-Host "Installing OpenClaw v$LatestVersion"
echo Write-Host "Installation directory: $OpenClawDir"
echo.
echo $Process = Start-Process `
echo     -FilePath $Npm.Source `
echo     -ArgumentList @(
echo         "install",
echo         "--global",
echo         "--prefix",
echo         $OpenClawDir,
echo         "--allow-scripts=openclaw,@google/genai,tree-sitter-bash,protobufjs",
echo         $Package
echo     ) `
echo     -Wait `
echo     -PassThru `
echo     -NoNewWindow
echo.
echo if ($Process.ExitCode -ne 0) {
echo     throw "OpenClaw npm installation failed with exit code $($Process.ExitCode)."
echo }
echo.
echo $OpenClawCmd = Join-Path $OpenClawDir "openclaw.cmd"
echo.
echo if (-not (Test-Path $OpenClawCmd)) {
echo     throw "OpenClaw executable was not created."
echo }
echo.
echo Write-Host
echo Write-Host "OpenClaw executable installed:"
echo Write-Host $OpenClawCmd
echo.
echo Write-Host "OpenClaw installation verified."
echo.
echo Remove-Item -Path $MetadataFile -Force -ErrorAction SilentlyContinue
echo.
exit /b 0