@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Vanilla llama.cpp GGUF Model Downloader
:: ====================================================

:: Model identifier from Download-Llamacpp-Model List.txt
set "_MODEL_NAME=gemma-3-4b-it"

:: Exact Hugging Face repository from Download-Llamacpp-Model List.txt
set "_HF_REPO=ggml-org/gemma-3-4b-it-GGUF"

:: Quantization
set "_QUANT=Q4_K_M"

echo ====================================================
echo        DOWNLOADING PORTABLE GGUF MODEL
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined SCRIPT_DIR (
    echo ERROR: IsolateEnv-Initialize.bat failed
    pause
    exit /b 1
)

set "_MODEL_DIR=%SCRIPT_DIR%Models"

if not exist "%_MODEL_DIR%" (
    mkdir "%_MODEL_DIR%"
)

set "_PS_FILE=%TEMP%\portable_model_download.ps1"

call :WritePowerShell > "%_PS_FILE%"

if not exist "%_PS_FILE%" (
    echo ERROR: Failed creating PowerShell downloader
    pause
    exit /b 1
)

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-File "%_PS_FILE%"

if errorlevel 1 (
    echo ====================================================
    echo        MODEL DOWNLOAD FAILED
    echo ====================================================
    del "%_PS_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo ====================================================
echo        MODEL DOWNLOAD COMPLETE
echo ====================================================

del "%_PS_FILE%" >nul 2>&1

echo =========================================================
echo       EXPORT ENVIRONMENT VARS FOR DOWNLINE SCRIPTS...
echo =========================================================

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_MODEL_DIR=%%%%SCRIPT_DIR%%%%\Models"

pause
endlocal
exit /b 0


:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $ModelName = "%_MODEL_NAME%"
echo $Repo = "%_HF_REPO%"
echo $Quant = "%_QUANT%"
echo $ModelDir = "%_MODEL_DIR%"
echo.
echo Write-Host "===================================================="
echo Write-Host " MODEL: $ModelName"
echo Write-Host " REPO:  $Repo"
echo Write-Host " QUANT: $Quant"
echo Write-Host "===================================================="
echo.
echo if (-not (Test-Path $ModelDir)) {
echo     New-Item -ItemType Directory -Path $ModelDir -Force ^| Out-Null
echo }
echo.
echo $Api = "https://huggingface.co/api/models/" + $Repo
echo.
echo Write-Host "Reading Hugging Face repository..."
echo.
echo $Repository = Invoke-RestMethod -Uri $Api -UseBasicParsing
echo.
echo if (-not $Repository.siblings) {
echo     throw "No repository files found: $Repo"
echo }
echo.
echo $GGUFList = $Repository.siblings ^|
echo     ForEach-Object { $_.rfilename } ^|
echo     Where-Object { $_ -match "\.gguf$" }
echo.
echo if (-not $GGUFList) {
echo     throw "No GGUF files found in repository: $Repo"
echo }
echo.
echo Write-Host
echo Write-Host "Available GGUF files:"
echo Write-Host "----------------------------------------------------"
echo.
echo foreach ($File in $GGUFList) {
echo     Write-Host $File
echo }
echo.
echo Write-Host "----------------------------------------------------"
echo.
echo Write-Host "Searching for quantization: $Quant"
echo.
echo $PrimaryMatches = $GGUFList ^|
echo     Where-Object {
echo         $_ -match [regex]::Escape($Quant) -and
echo         $_ -notmatch "(?i)(^|/)mmproj"
echo     }
echo.
echo if (-not $PrimaryMatches) {
echo     throw "No primary GGUF file matching quantization '$Quant' was found."
echo }
echo.
echo $GGUF = $PrimaryMatches ^| Select-Object -First 1
echo $FileName = Split-Path $GGUF -Leaf
echo $Destination = Join-Path $ModelDir $FileName
echo.
echo Write-Host
echo Write-Host "Selected GGUF:"
echo Write-Host $GGUF
echo.
echo Write-Host "Destination:"
echo Write-Host $Destination
echo.
echo if (Test-Path $Destination) {
echo     Write-Host
echo     Write-Host "Model already exists. Skipping download."
echo     Write-Host $Destination
echo }
echo else {
echo     $EncodedPath = ($GGUF -split "/" ^|
echo         ForEach-Object { [uri]::EscapeDataString($_) }) -join "/"
echo.
echo     $Url = "https://huggingface.co/" + $Repo + "/resolve/main/" + $EncodedPath
echo.
echo     Write-Host
echo     Write-Host "Downloading:"
echo     Write-Host $Url
echo     Write-Host
echo.
echo     Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
echo.
echo     if (-not (Test-Path $Destination)) {
echo         throw "Model download failed: $Destination"
echo     }
echo.
echo     $SizeGB = [math]::Round((Get-Item $Destination).Length / 1GB, 2)
echo.
echo     Write-Host
echo     Write-Host "Downloaded successfully."
echo     Write-Host "File: $FileName"
echo     Write-Host "Size: $SizeGB GB"
echo }
echo.
echo Write-Host
echo Write-Host "===================================================="
echo Write-Host " MULTIMODAL PROJECTOR CHECK"
echo Write-Host "===================================================="
echo.
echo $MMProjList = $GGUFList ^|
echo     Where-Object {
echo         $_ -match "(?i)(^|/)mmproj.*\.gguf$"
echo     }
echo.
echo if ($MMProjList) {
echo     Write-Host "Multimodal projector(s) found:"
echo.
echo     foreach ($MMProj in $MMProjList) {
echo         Write-Host "  $MMProj"
echo     }
echo.
echo     $MMProj = $MMProjList ^|
echo         Where-Object { $_ -match "(?i)mmproj.*f16.*\.gguf$" } ^|
echo         Select-Object -First 1
echo.
echo     if (-not $MMProj) {
echo         $MMProj = $MMProjList ^| Select-Object -First 1
echo     }
echo.
echo     $MMProjFileName = Split-Path $MMProj -Leaf
echo     $MMProjDestination = Join-Path $ModelDir $MMProjFileName
echo.
echo     Write-Host
echo     Write-Host "Selected multimodal projector:"
echo     Write-Host $MMProj
echo     Write-Host
echo     Write-Host "Projector destination:"
echo     Write-Host $MMProjDestination
echo.
echo     if (Test-Path $MMProjDestination) {
echo         Write-Host
echo         Write-Host "Multimodal projector already exists. Skipping download."
echo         Write-Host $MMProjDestination
echo     }
echo     else {
echo         $MMProjEncodedPath = ($MMProj -split "/" ^|
echo             ForEach-Object { [uri]::EscapeDataString($_) }) -join "/"
echo.
echo         $MMProjUrl = "https://huggingface.co/" + $Repo + "/resolve/main/" + $MMProjEncodedPath
echo.
echo         Write-Host
echo         Write-Host "Downloading multimodal projector:"
echo         Write-Host $MMProjUrl
echo         Write-Host
echo.
echo         Invoke-WebRequest -Uri $MMProjUrl -OutFile $MMProjDestination -UseBasicParsing
echo.
echo         if (-not (Test-Path $MMProjDestination)) {
echo             throw "Multimodal projector download failed: $MMProjDestination"
echo         }
echo.
echo         $MMProjSizeGB = [math]::Round((Get-Item $MMProjDestination).Length / 1GB, 2)
echo.
echo         Write-Host
echo         Write-Host "Multimodal projector downloaded successfully."
echo         Write-Host "File: $MMProjFileName"
echo         Write-Host "Size: $MMProjSizeGB GB"
echo     }
echo }
echo else {
echo     Write-Host "No multimodal projector found in repository."
echo     Write-Host "This model does not require an mmproj file."
echo }
echo.
echo Write-Host
echo Write-Host "===================================================="
echo Write-Host " MODEL FILE CHECK COMPLETE"
echo Write-Host "===================================================="

exit /b 0
