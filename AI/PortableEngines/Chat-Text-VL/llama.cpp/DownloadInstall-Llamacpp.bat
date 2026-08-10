::DownloadInstall-Llamacpp.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion
:: ====================================================
:: Portable Vanilla llama.cpp Installer
:: ====================================================

::set "_LLAMA_BACKEND=cuda12"
::set "_LLAMA_BACKEND=cuda13"
set "_LLAMA_BACKEND=vulkan"
::set "_LLAMA_BACKEND=cpu"

echo ====================================================
echo       INSTALLING PORTABLE VANILLA LLAMA.CPP
echo ====================================================

if not exist "%~dp0IsolateEnv.bat" (
echo ERROR: IsolateEnv.bat missing
pause
exit /b 1
)

if not exist "%~dp0IsolateEnv-Project.bat" (
echo ERROR: IsolateEnv-Project.bat missing
pause
exit /b 1
)

call "%~dp0IsolateEnv.bat"

if not defined SCRIPT_DIR (
echo ERROR: IsolateEnv.bat failed
pause
exit /b 1
)

call "%~dp0IsolateEnv-Project.bat"

if not defined _LOG_DIR (
echo ERROR: IsolateEnv-Project.bat failed
pause
exit /b 1
)

set "_LLAMA_DIR=%SCRIPT_DIR%llama.cpp\%_LLAMA_BACKEND%"

set "_PS_FILE=%TEMP%\portable_llamacpp_install.ps1"

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
echo       LLAMA.CPP INSTALL FAILED
echo ====================================================
del "%_PS_FILE%" >nul 2>&1
pause
exit /b 1
)


echo ====================================================
echo       LLAMA.CPP INSTALL COMPLETE
echo ====================================================
del "%_PS_FILE%" >nul 2>&1

echo =========================================================
echo       EXPORT ENVIRONMENT VARS FOR DOWNLINE SCRIPTS...
echo =========================================================
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_LLAMA_BACKEND=vulkan"

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_LLAMA_DIR=%%%%SCRIPT_DIR%%%%llama.cpp\%%%%_LLAMA_BACKEND%%%%"

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "LLAMA_CACHE=%%%%SCRIPT_DIR%%%%Models\llamacache"

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "HF_HOME=%%%%SCRIPT_DIR%%%%Models\hfcache"


pause
endlocal
exit /b 0

:WritePowerShell
echo $ErrorActionPreference = "Stop"
echo.
echo $Root = "%SCRIPT_DIR%"
echo $InstallDir = "%_LLAMA_DIR%"
echo $Backend = "%_LLAMA_BACKEND%"
echo $DownloadRoot = Join-Path $Root "Downloads"
echo $LlamaDownloadRoot = Join-Path $DownloadRoot "llama.cpp"
echo.
echo if (-not (Test-Path $DownloadRoot)) {
echo     New-Item -ItemType Directory -Path $DownloadRoot -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $LlamaDownloadRoot)) {
echo     New-Item -ItemType Directory -Path $LlamaDownloadRoot -Force ^| Out-Null
echo }
echo.
echo Write-Host "Finding latest official upstream llama.cpp release"
echo.
echo $ReleaseApi = "https://api.github.com/repos/ggml-org/llama.cpp/releases/latest"
echo.
echo $Headers = @{
echo     "User-Agent" = "Portable-llama-installer"
echo }
echo.
echo $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers
echo.
echo if (-not $Release.assets) {
echo     throw "No release assets found"
echo }
echo.
echo $Asset = $Release.assets ^| Where-Object {
echo     $_.name -match $Backend -and
echo     $_.name -match "win" -and
echo     $_.name -match "x64" -and
echo     $_.name -match "\.zip$"
echo } ^| Select-Object -First 1
echo.
echo if (-not $Asset) {
echo     throw "No matching upstream llama.cpp build found for backend: $Backend"
echo }
echo.
echo $Archive = Join-Path $LlamaDownloadRoot $Asset.name
echo.
echo Write-Host "Selected release:"
echo Write-Host $Release.tag_name
echo Write-Host "Selected asset:"
echo Write-Host $Asset.name
echo.
echo if (-not (Test-Path $Archive)) {
echo     Write-Host "Downloading official upstream llama.cpp"
echo     Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Archive -UseBasicParsing
echo }
echo.
echo function Test-Llama {
echo     $Exe = Join-Path $InstallDir "llama-server.exe"
echo     $Dlls = Get-ChildItem -Path $InstallDir -Filter "ggml*.dll" -File -ErrorAction SilentlyContinue
echo.
echo     if ((Test-Path $Exe) -and $Dlls) {
echo         return $true
echo     }
echo.
echo     return $false
echo }
echo.
echo if (-not (Test-Llama)) {
echo.
echo     $ExtractDir = Join-Path $Root ".llamacpp-extract"
echo.
echo     if (Test-Path $ExtractDir) {
echo         Remove-Item $ExtractDir -Recurse -Force
echo     }
echo.
echo     New-Item -ItemType Directory -Path $ExtractDir -Force ^| Out-Null
echo.
echo     Write-Host "Extracting official upstream llama.cpp"
echo     Expand-Archive -Path $Archive -DestinationPath $ExtractDir -Force
echo.
echo     $Found = Get-ChildItem -Path $ExtractDir -Filter "llama-server.exe" -Recurse ^| Select-Object -First 1
echo.
echo     if (-not $Found) {
echo         throw "llama-server.exe not found"
echo     }
echo.
echo     if (-not (Test-Path $InstallDir)) {
echo         New-Item -ItemType Directory -Path $InstallDir -Force ^| Out-Null
echo     }
echo.
echo     Copy-Item -Path (Join-Path $Found.Directory.FullName "*") -Destination $InstallDir -Recurse -Force
echo.
echo     Remove-Item $ExtractDir -Recurse -Force
echo }
echo.
echo $Exe = Join-Path $InstallDir "llama-server.exe"
echo.
echo.
echo if (-not (Test-Path $Exe)) {
echo     throw "llama-server.exe missing"
echo }
echo.
echo Write-Host "Verifying llama.cpp executable"
echo.
echo $Exe = Join-Path $InstallDir "llama-server.exe"
echo.
echo Write-Host "Verifying llama.cpp installation"
echo Write-Host
echo.
echo if (-not (Test-Path $Exe)) {
echo     throw "llama-server.exe was not found at: $Exe"
echo }
echo.
echo Write-Host "llama-server.exe found:"
echo Write-Host $Exe
echo Write-Host
echo.
echo Write-Host "llama.cpp executable installation verified"
echo Write-Host
echo.
echo Write-Warning "The executable was found successfully, but this check does not verify that all required DLLs or runtime dependencies are installed."
echo Write-Warning "If llama-server.exe fails to start later, a missing DLL or other runtime dependency may be the cause."
echo Write-Host
echo.
exit /b 0
