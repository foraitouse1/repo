::DownloadInstall-VC++Runtime.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable MSVC Runtime Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE MSVC RUNTIME 
echo        INSIDE ESTABLISHED _LLAMA_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined _LLAMA_DIR (
echo ERROR: IsolateEnv-Project.bat failed to define _LLAMA_DIR
pause
exit /b 1
)


set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

set "_PS_FILE=%TEMP%\msvc_runtime_install.ps1"

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
echo       MSVC INSTALL FAILED
echo ====================================================
pause
exit /b 1
)

del "%_PS_FILE%" >nul 2>&1

echo ====================================================
echo       MSVC RUNTIME INSTALL COMPLETE
echo ====================================================

pause

endlocal
exit /b 0



:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.

echo $TargetDir = "%_LLAMA_DIR%"
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo.

echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }

echo.

echo $Url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"

echo.

echo $Installer = Join-Path $DownloadDir "vc_redist.x64.exe"

echo.

echo if (-not (Test-Path $Installer)) {

echo     Write-Host "Downloading latest Microsoft Visual C++ Redistributable"

echo.

echo     Invoke-WebRequest `
echo         -Uri $Url `
echo         -OutFile $Installer `
echo         -UseBasicParsing

echo }

echo.

echo Write-Host "Installing MSVC Runtime silently"

echo.

echo Start-Process `
echo     -FilePath $Installer `
echo     -ArgumentList "/install","/quiet","/norestart" `
echo     -Wait

echo.

echo Write-Host "Copying runtime DLLs to portable folder"

echo.

echo $RuntimeFiles = @(

echo     "VCRUNTIME140.dll"

echo     "VCRUNTIME140_1.dll"

echo     "MSVCP140.dll"

echo )

echo.

echo foreach ($File in $RuntimeFiles) {

echo.

echo     $Source = Join-Path $env:SystemRoot "System32\$File"

echo.

echo     if (Test-Path $Source) {

echo         Write-Host "Copying $File"

echo         Copy-Item `
echo             -Path $Source `
echo             -Destination $TargetDir `
echo             -Force

echo     }

echo     else {

echo         throw "Missing installed runtime file: $File"

echo     }

echo.

echo }

echo.

echo Write-Host "Verifying portable MSVC runtime"

echo.

echo foreach ($File in $RuntimeFiles) {

echo.

echo     if (-not (Test-Path (Join-Path $TargetDir $File))) {

echo         throw "Missing portable runtime file: $File"

echo     }

echo.

echo }

echo.

echo Write-Host "Portable MSVC runtime verified"

exit /b 0
