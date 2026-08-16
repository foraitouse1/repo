@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Vanilla stable-diffusion.cpp Engine Launcher
:: ====================================================

set "_SD_PORT=7860"

echo ====================================================
echo       STARTING PORTABLE STABLE-DIFFUSION.CPP
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined _ENGINE_DIR (
    echo ERROR: _ENGINE_DIR is not defined by IsolateEnv-Project.bat
    pause
    exit /b 1
)

if not defined _MODEL_DIR (
    echo ERROR: _MODEL_DIR is not defined by IsolateEnv-Project.bat
    pause
    exit /b 1
)

set "_PS_FILE=%TEMP%\portable_run_engine.ps1"

call :WritePowerShell > "%_PS_FILE%"

if not exist "%_PS_FILE%" (
    echo ERROR: Failed creating PowerShell launcher
    pause
    exit /b 1
)

::Add port for downline apps
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_SD_PORT=7860"

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-File "%_PS_FILE%"

if errorlevel 1 (
    echo ====================================================
    echo       STABLE-DIFFUSION.CPP SERVER FAILED
    echo ====================================================
    del "%_PS_FILE%" >nul 2>&1
    pause
    exit /b 1
)

del "%_PS_FILE%" >nul 2>&1

echo ====================================================
echo       STABLE-DIFFUSION.CPP SERVER STOPPED
echo ====================================================

pause
endlocal
exit /b 0


:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $Root = [Environment]::GetEnvironmentVariable("SCRIPT_DIR")
echo $EngineDir = [Environment]::GetEnvironmentVariable("_ENGINE_DIR")
echo $ModelRoot = [Environment]::GetEnvironmentVariable("_MODEL_DIR")
echo $Port = [Environment]::GetEnvironmentVariable("_SD_PORT")
echo.
echo $Server = Join-Path $EngineDir "sd-server.exe"
echo.
echo if (-not (Test-Path $Server)) {
echo     throw "sd-server.exe was not found: $Server"
echo }
echo.
echo Write-Host "Searching for installed stable-diffusion.cpp model manifests"
echo.
echo $Manifests = @(
echo     Get-ChildItem -Path $ModelRoot -Filter "model.manifest" -Recurse -File -ErrorAction SilentlyContinue
echo )
echo.
echo if (-not $Manifests) {
echo     throw "No installed stable-diffusion.cpp model manifests were found."
echo }
echo.
echo $Entries = @()
echo.
echo foreach ($Manifest in $Manifests) {
echo     $Data = @{}
echo     foreach ($Line in Get-Content $Manifest.FullName) {
echo         if ($Line -match "^([^=]+)=(.*)$") {
echo             $Data[$Matches[1]] = $Matches[2]
echo         }
echo     }
echo.
echo     if ($Data.ContainsKey("MODEL_NAME") -and $Data.ContainsKey("DIFFUSION_MODEL")) {
echo         $Entries += [PSCustomObject]@{
echo             Name = $Data["MODEL_NAME"]
echo             Manifest = $Manifest.FullName
echo             Data = $Data
echo         }
echo     }
echo }
echo.
echo if (-not $Entries) {
echo     throw "No valid model manifests were found."
echo }
echo.
echo Write-Host "Installed models:"
echo Write-Host "----------------------------------------------------"
echo.
echo for ($i = 0; $i -lt $Entries.Count; $i++) {
echo     Write-Host ("[{0}] {1}" -f ($i + 1), $Entries[$i].Name)
echo }
echo.
echo Write-Host "----------------------------------------------------"
echo.
echo $Selection = Read-Host "Select model number"
echo.
echo $Index = 0
echo if (-not [int]::TryParse($Selection, [ref]$Index)) {
echo     throw "Invalid model selection."
echo }
echo.
echo $Index--
echo if ($Index -lt 0 -or $Index -ge $Entries.Count) {
echo     throw "Model selection is outside the available range."
echo }
echo.
echo $Selected = $Entries[$Index]
echo $Data = $Selected.Data
echo.
echo Write-Host
echo Write-Host "Selected model:"
echo Write-Host $Selected.Name
echo.
echo $DiffusionRelative = $Data["DIFFUSION_MODEL"]
echo $DiffusionModel = Join-Path $Root ($DiffusionRelative -replace "^\.\\" ,"")
echo.
echo if (-not (Test-Path $DiffusionModel)) {
echo     throw "Diffusion model file is missing: $DiffusionModel"
echo }
echo.
echo $Args = @()
echo.
echo $PrimaryFlag = $Data["PRIMARY_FLAG"]
echo if ([string]::IsNullOrWhiteSpace($PrimaryFlag)) {
echo     $PrimaryFlag = "--diffusion-model"
echo }
echo.
echo $Args += $PrimaryFlag
echo $Args += $DiffusionModel
echo.
echo $VaeRelative = $Data["VAE"]
echo if (-not [string]::IsNullOrWhiteSpace($VaeRelative)) {
echo     $Vae = Join-Path $Root ($VaeRelative -replace "^\.\\" ,"")
echo     if (Test-Path $Vae) {
echo         $Args += "--vae"
echo         $Args += $Vae
echo     }
echo }
echo.
echo $LlmRelative = $Data["LLM"]
echo if (-not [string]::IsNullOrWhiteSpace($LlmRelative)) {
echo     $Llm = Join-Path $Root ($LlmRelative -replace "^\.\\" ,"")
echo     if (Test-Path $Llm) {
echo         $Args += "--llm"
echo         $Args += $Llm
echo     }
echo }
echo.
echo $ClipLRelative = $Data["CLIP_L"]
echo if (-not [string]::IsNullOrWhiteSpace($ClipLRelative)) {
echo     $ClipL = Join-Path $Root ($ClipLRelative -replace "^\.\\" ,"")
echo     if (Test-Path $ClipL) {
echo         $Args += "--clip_l"
echo         $Args += $ClipL
echo     }
echo }
echo.
echo $ClipGRelative = $Data["CLIP_G"]
echo if (-not [string]::IsNullOrWhiteSpace($ClipGRelative)) {
echo     $ClipG = Join-Path $Root ($ClipGRelative -replace "^\.\\" ,"")
echo     if (Test-Path $ClipG) {
echo         $Args += "--clip_g"
echo         $Args += $ClipG
echo     }
echo }
echo.
echo $T5Relative = $Data["T5XXL"]
echo if (-not [string]::IsNullOrWhiteSpace($T5Relative)) {
echo     $T5 = Join-Path $Root ($T5Relative -replace "^\.\\" ,"")
echo     if (Test-Path $T5) {
echo         $Args += "--t5xxl"
echo         $Args += $T5
echo     }
echo }
echo.
::after disabling Vulkan by renaming ggml-vulkan.dll to ggml-vulkan.dll.bak, the commented out arguments are not needed
::echo $Args += "--diffusion-fa"
echo $Args += "--vae-tiling"
::echo $Args += "--vae-on-cpu"
::echo $Args += "--vae-conv-direct"
::echo $Args += "--clip-on-cpu"
echo $Args += "--offload-to-cpu"
echo.
echo $Args += "--listen-ip"
echo $Args += "127.0.0.1"
echo $Args += "--listen-port"
echo $Args += $Port
echo.
echo Write-Host "===================================================="
echo Write-Host " STABLE-DIFFUSION.CPP SERVER"
echo Write-Host "===================================================="
echo Write-Host
echo Write-Host "Model: $($Selected.Name)"
echo Write-Host "Backend directory: $EngineDir"
echo Write-Host "Port: $Port"
echo Write-Host
echo Write-Host "Final server arguments:"
echo $Args ^| ForEach-Object {
echo     Write-Host "  $_"
echo }
echo.
echo Write-Host "===================================================="
echo Write-Host " LAUNCHING LOCAL WEB UI"
echo Write-Host "===================================================="
echo Write-Host
echo Write-Host "http://127.0.0.1:$Port/"
echo.
echo Write-Host "Press Ctrl+C in this window to stop the server."
echo.
echo ^& $Server @Args
echo.
echo $ExitCode = $LASTEXITCODE
echo.
echo Write-Host "Server exit code: $ExitCode"
echo.
echo if ($ExitCode -ne 0) {
echo     throw "stable-diffusion.cpp server failed."
echo }
echo.
echo exit /b 0