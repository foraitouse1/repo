::DownloadInstall-Python.bat

:: Install Python (and ensure PIP is also installed)

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Python Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE PYTHON
echo        INSIDE ESTABLISHED _PYTHON_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SSL_CERT_FILE (
echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
pause
exit /b 1
)

set "_PYTHON_DIR=%SCRIPT_DIR%\Python"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%\Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_PYTHON_DIR%" (
mkdir "%_PYTHON_DIR%"
)

set "_PS_FILE=%TEMP%\python_install.ps1"

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
echo       PYTHON INSTALL FAILED
echo ====================================================
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_PYTHON_DIR=%%%%SCRIPT_DIR%%%%Python"
if errorlevel 1 (
echo ERROR: Failed adding _PYTHON_DIR to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%SCRIPT_DIR%%%%Python;%%%%SCRIPT_DIR%%%%Python\Scripts;%%%%PATH%%%%"
if errorlevel 1 (
echo ERROR: Failed adding Python to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)

echo ====================================================
echo       PYTHON INSTALL COMPLETE
echo ====================================================
echo.
echo Python directory: %_PYTHON_DIR%
echo.

pause

endlocal
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $PythonDir = "%_PYTHON_DIR%"
echo $DownloadsPage = "https://www.python.org/downloads/windows/"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $PythonDir)) {
echo     New-Item -ItemType Directory -Path $PythonDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable Python release"
echo.
echo $Page = Invoke-WebRequest `
echo     -Uri $DownloadsPage `
echo     -UseBasicParsing
echo.
echo $Matches = [regex]::Matches(
echo     $Page.Content,
echo     'https://www\.python\.org/ftp/python/([0-9]+\.[0-9]+\.[0-9]+)/python-([0-9]+\.[0-9]+\.[0-9]+)-amd64\.exe'
echo )
echo.
echo if ($Matches.Count -eq 0) {
echo     throw "No stable 64-bit Python Windows installer was found."
echo }
echo.
echo $Releases = foreach ($Match in $Matches) {
echo     [PSCustomObject]@{
echo         Version = [version]$Match.Groups[1].Value
echo         Url = $Match.Value
echo         FileName = "python-$($Match.Groups[2].Value)-amd64.exe"
echo     }
echo }
echo.
echo $Latest = $Releases ^|
echo     Sort-Object Version -Descending ^|
echo     Select-Object -First 1
echo.
echo if (-not $Latest) {
echo     throw "Unable to determine the latest stable Python release."
echo }
echo.
echo Write-Host "Latest stable Python: $($Latest.Version)"
echo.
echo $Installer = Join-Path $DownloadDir $Latest.FileName
echo $PythonExe = Join-Path $PythonDir "python.exe"
echo.
echo if (-not (Test-Path $Installer)) {
echo     Write-Host "Downloading $($Latest.FileName)"
echo     Invoke-WebRequest `
echo         -Uri $Latest.Url `
echo         -OutFile $Installer `
echo         -UseBasicParsing
echo }
echo.
echo if (-not (Test-Path $Installer)) {
echo     throw "Python installer was not downloaded."
echo }
echo.
echo if (-not (Test-Path $PythonExe)) {
echo     Write-Host "Installing full Python $($Latest.Version)"
echo     $Process = Start-Process `
echo         -FilePath $Installer `
echo         -ArgumentList @(
echo             "/quiet"
echo             "InstallAllUsers=0"
echo             "TargetDir=$PythonDir"
echo             "PrependPath=0"
echo             "AppendPath=0"
echo             "Include_launcher=0"
echo             "InstallLauncherAllUsers=0"
echo             "Include_pip=1"
echo             "Include_exe=1"
echo             "Include_lib=1"
echo             "Include_dev=1"
echo             "Include_tools=1"
echo             "Include_tcltk=1"
echo             "Include_doc=1"
echo             "Include_test=1"
echo             "CompileAll=1"
echo         ) `
echo         -Wait `
echo         -PassThru
echo.
echo     if ($Process.ExitCode -ne 0) {
echo         throw "Python installer failed with exit code $($Process.ExitCode)."
echo     }
echo }
echo.
echo if (-not (Test-Path $PythonExe)) {
echo     throw "python.exe was not found after installation."
echo }
echo.
echo Write-Host "Checking for pip"
echo.
echo $PipVersion = ^& $PythonExe -m pip --version
echo if ($LASTEXITCODE -ne 0) {
echo     Write-Host "pip is missing. Installing pip from Python's bundled ensurepip."
echo     ^& $PythonExe -m ensurepip --upgrade
echo     if ($LASTEXITCODE -ne 0) {
echo         throw "Failed installing pip with ensurepip."
echo     }
echo }
echo.
echo $PipVersion = ^& $PythonExe -m pip --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "Python pip verification failed."
echo }
echo.
echo Write-Host "Verifying full Python installation"
echo.
echo $Version = ^& $PythonExe --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "Python verification failed."
echo }
echo.
echo Write-Host $Version
echo Write-Host $PipVersion
echo Write-Host "Full Python installation verified"
echo.
exit /b 0
