::DownloadInstall-Git.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Git Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE GIT
echo        INSIDE ESTABLISHED _GIT_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SSL_CERT_FILE (
echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
pause
exit /b 1
)

set "_GIT_DIR=%SCRIPT_DIR%\Git"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_GIT_DIR%" (
mkdir "%_GIT_DIR%"
)

set "_PS_FILE=%TEMP%\git_install.ps1"

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
echo       GIT INSTALL FAILED
echo ====================================================
pause
exit /b 1
)


call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_GIT_DIR=%%%%SCRIPT_DIR%%%%Git"
if errorlevel 1 (
echo ERROR: Failed adding _GIT_DIR to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%SCRIPT_DIR%%%%Git\cmd;%%%%PATH%%%%"
if errorlevel 1 (
echo ERROR: Failed adding Git to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)

echo ====================================================
echo       GIT INSTALL COMPLETE
echo ====================================================
echo.
echo Git directory: %_GIT_DIR%
echo.

pause

endlocal
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $GitDir = "%_GIT_DIR%"
echo $ApiUrl = "https://api.github.com/repos/git-for-windows/git/releases/latest"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $GitDir)) {
echo     New-Item -ItemType Directory -Path $GitDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable Git for Windows release"
echo.
echo $Release = Invoke-RestMethod `
echo     -Uri $ApiUrl `
echo     -Headers @{ "User-Agent" = "PortableGitInstaller" } `
echo     -UseBasicParsing
echo.
echo if (-not $Release) {
echo     throw "Unable to determine the latest Git for Windows release."
echo }
echo.
echo $Asset = $Release.assets ^|
echo     Where-Object {
echo         $_.name -match '^PortableGit-[0-9]+\.[0-9]+\.[0-9]+.*-64-bit\.7z\.exe$'
echo     } ^|
echo     Select-Object -First 1
echo.
echo if (-not $Asset) {
echo     throw "No 64-bit Portable Git release asset was found."
echo }
echo.
echo $Version = $Release.tag_name.TrimStart("v")
echo $FileName = $Asset.name
echo $Url = $Asset.browser_download_url
echo $Archive = Join-Path $DownloadDir $FileName
echo $GitExe = Join-Path $GitDir "cmd\git.exe"
echo $GitBash = Join-Path $GitDir "git-bash.exe"
echo.
echo Write-Host "Latest Git for Windows: $Version"
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
echo     throw "Portable Git archive was not downloaded."
echo }
echo.
echo $InstallRequired = $true
echo.
echo if ((Test-Path $GitExe) -and (Test-Path $GitBash)) {
echo     $InstalledVersion = ^& $GitExe --version
echo     if ($InstalledVersion -match [regex]::Escape($Version)) {
echo         $InstallRequired = $false
echo         Write-Host "Git $Version is already installed."
echo     }
echo }
echo.
echo if ($InstallRequired) {
echo     Write-Host "Extracting Portable Git $Version"
echo     $Process = Start-Process `
echo         -FilePath $Archive `
echo         -ArgumentList @(
echo             "-y"
echo             "-o$GitDir"
echo         ) `
echo         -Wait `
echo         -PassThru
echo.
echo     if ($Process.ExitCode -ne 0) {
echo         throw "Portable Git extraction failed with exit code $($Process.ExitCode)."
echo     }
echo }
echo.
echo if (-not (Test-Path $GitExe)) {
echo     throw "git.exe was not found after installation."
echo }
echo.
echo if (-not (Test-Path $GitBash)) {
echo     throw "git-bash.exe was not found after installation."
echo }
echo.
echo Write-Host "Verifying Git"
echo.
echo $GitVersion = ^& $GitExe --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "Git verification failed."
echo }
echo.
echo Write-Host $GitVersion
echo Write-Host "Portable Git verified"
echo.
exit /b 0
