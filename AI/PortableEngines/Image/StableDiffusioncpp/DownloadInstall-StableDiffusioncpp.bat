::DownloadInstall-StableDiffusioncpp.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion
:: ====================================================
:: Portable Vanilla stable-diffusion.cpp Installer
:: ====================================================

::set "_ENGINE_BACKEND=cuda12"
::set "_ENGINE_BACKEND=cpu"
set "_ENGINE_BACKEND=vulkan"

echo ====================================================
echo       INSTALLING PORTABLE STABLE-DIFFUSION.CPP
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined _LOG_DIR (
    echo ERROR: IsolateEnv-Project.bat failed
    pause
    exit /b 1
)

set "_ENGINE_DIR=%SCRIPT_DIR%Engine\%_ENGINE_BACKEND%"
set "_PS_FILE=%~dp0portable_stablediffusioncpp_install.ps1"

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
    echo        STABLE-DIFFUSION.CPP INSTALL FAILED
    echo ====================================================
    del "%_PS_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo ====================================================
echo        STABLE-DIFFUSION.CPP INSTALL COMPLETE
echo ====================================================
del "%_PS_FILE%" >nul 2>&1

echo =========================================================
echo        EXPORT ENVIRONMENT VARS FOR DOWNLINE SCRIPTS...
echo =========================================================
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_ENGINE_BACKEND=vulkan"
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_ENGINE_DIR=%%%%SCRIPT_DIR%%%%Engine\%%%%_ENGINE_BACKEND%%%%"


pause
endlocal
exit /b 0

:WritePowerShell
echo $ErrorActionPreference = "Stop"
echo.
echo $Root = "%SCRIPT_DIR%"
echo $InstallDir = "%_ENGINE_DIR%"
echo $Backend = "%_ENGINE_BACKEND%"
echo $DownloadRoot = Join-Path $Root "Downloads"
echo $StableDiffusionDownloadRoot = Join-Path $DownloadRoot "stable-diffusion.cpp"
echo.
echo if (-not (Test-Path $DownloadRoot)) {
echo     New-Item -ItemType Directory -Path $DownloadRoot -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $StableDiffusionDownloadRoot)) {
echo     New-Item -ItemType Directory -Path $StableDiffusionDownloadRoot -Force ^| Out-Null
echo }
echo.
echo Write-Host "Finding latest official upstream stable-diffusion.cpp release"
echo.
echo $ReleaseApi = "https" + [char]58 + [char]47 + [char]47 + "api.github.com/repos/leejet/stable-diffusion.cpp/releases/latest"
echo.
echo $Headers = @{
echo     "User-Agent" = "Portable-stable-diffusion-installer"
echo }
echo.
echo $Release = Invoke-RestMethod -Uri $ReleaseApi -Headers $Headers
echo.
echo if (-not $Release.assets) {
echo     throw "No release assets found"
echo }
echo.
echo $Asset = $null
echo.
echo foreach ($ReleaseAsset in $Release.assets) {
echo     if (
echo         $ReleaseAsset.name -match $Backend -and
echo         $ReleaseAsset.name -match "win" -and
echo         $ReleaseAsset.name -match "x64" -and
echo         $ReleaseAsset.name -match "\.zip$"
echo     ) {
echo         $Asset = $ReleaseAsset
echo         break
echo     }
echo }
echo.
echo if (-not $Asset) {
echo     throw "No matching upstream stable-diffusion.cpp build found for backend: $Backend"
echo }
echo.
echo $Archive = Join-Path $StableDiffusionDownloadRoot $Asset.name
echo.
echo Write-Host "Selected release:"
echo Write-Host $Release.tag_name
echo Write-Host "Selected asset:"
echo Write-Host $Asset.name
echo.
echo if (-not (Test-Path $Archive)) {
echo     Write-Host "Downloading official upstream stable-diffusion.cpp"
echo     Invoke-WebRequest -Uri $Asset.browser_download_url -OutFile $Archive -UseBasicParsing
echo }
echo.
echo function Test-StableDiffusion {
echo     $Server = Join-Path $InstallDir "sd-server.exe"
echo     $Cli = Join-Path $InstallDir "sd-cli.exe"
echo     $Dll = Join-Path $InstallDir "stable-diffusion.dll"
echo.
echo     if ((Test-Path $Server) -and (Test-Path $Cli) -and (Test-Path $Dll)) {
echo         return $true
echo     }
echo.
echo     return $false
echo }
echo.
echo if (-not (Test-StableDiffusion)) {
echo.
echo     $ExtractDir = Join-Path $Root ".stable-diffusion-cpp-extract"
echo.
echo     if (Test-Path $ExtractDir) {
echo         Remove-Item $ExtractDir -Recurse -Force
echo     }
echo.
echo     New-Item -ItemType Directory -Path $ExtractDir -Force ^| Out-Null
echo.
echo     Write-Host "Extracting official upstream stable-diffusion.cpp"
echo     Expand-Archive -Path $Archive -DestinationPath $ExtractDir -Force
echo.
echo     $Found = Get-ChildItem -Path $ExtractDir -Filter "sd-server.exe" -Recurse ^| Select-Object -First 1
echo.
echo     if (-not $Found) {
echo         throw "sd-server.exe not found"
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
echo $Server = Join-Path $InstallDir "sd-server.exe"
echo $Cli = Join-Path $InstallDir "sd-cli.exe"
echo $Dll = Join-Path $InstallDir "stable-diffusion.dll"
echo.
echo if (-not (Test-Path $Server)) {
echo     throw "sd-server.exe missing"
echo }
echo.
echo if (-not (Test-Path $Cli)) {
echo     throw "sd-cli.exe missing"
echo }
echo.
echo if (-not (Test-Path $Dll)) {
echo     throw "stable-diffusion.dll missing"
echo }
echo.
echo Write-Host "Verifying stable-diffusion.cpp executable"
echo.
echo Write-Host "sd-server.exe found:"
echo Write-Host $Server
echo Write-Host
echo Write-Host "sd-cli.exe found:"
echo Write-Host $Cli
echo Write-Host
echo Write-Host "stable-diffusion.dll found:"
echo Write-Host $Dll
echo Write-Host
echo.
echo Write-Host "stable-diffusion.cpp executable installation verified"
echo Write-Host
echo.
echo Write-Warning "The executable was found successfully, but this check does not verify that all required DLLs or runtime dependencies are installed."
echo Write-Warning "If stable-diffusion.cpp fails to start later, a missing DLL or other runtime dependency may be the cause."
echo Write-Host
echo.
echo exit 0