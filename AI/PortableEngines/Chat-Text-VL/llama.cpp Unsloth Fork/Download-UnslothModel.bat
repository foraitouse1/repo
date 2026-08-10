::Download-UnslothModel.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Unsloth GGUF Model Downloader
:: ====================================================

:: Model selection
set "_MODEL_NAME=gemma-3-270m-it"
set "_QUANT=Q8_0"

echo ====================================================
echo        DOWNLOADING PORTABLE GGUF MODEL
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

set "_MODEL_DIR=%SCRIPT_DIR%Models"
if not exist "%_MODEL_DIR%" mkdir "%_MODEL_DIR%"

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

::add new env var for downline scripts
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_MODEL_DIR=%%%%SCRIPT_DIR%%%%\Models"

pause
endlocal
exit /b 0


:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $ModelName = "%_MODEL_NAME%"
echo $Quant = "%_QUANT%"
echo $ModelDir = "%_MODEL_DIR%"
echo.
echo $Repo = "unsloth/" + $ModelName + "-GGUF"
echo.
echo Write-Host "Searching Unsloth repository:"
echo Write-Host $Repo
echo.
echo $Api = "https://huggingface.co/api/models/" + $Repo
echo.
echo $Files = Invoke-RestMethod -Uri $Api
echo.
echo $GGUFList = $Files.siblings ^| ForEach-Object {
echo     $_.rfilename
echo } ^| Where-Object {
echo     $_ -match "\.gguf$"
echo }
echo.
echo Write-Host "Available GGUF files:"
echo.
echo foreach ($File in $GGUFList) {
echo     Write-Host $File
echo }
echo.
echo $GGUF = $GGUFList ^| Where-Object {
echo     $_ -match [regex]::Escape($Quant)
echo } ^| Select-Object -First 1
echo.
echo if (-not $GGUF) {
echo     throw "No matching GGUF file found for quantization: $Quant"
echo }
echo.
echo.
echo Write-Host "Selected model file:"
echo Write-Host $GGUF
echo.
echo $Destination = Join-Path $ModelDir $GGUF
echo.
echo if (Test-Path $Destination) {
echo     Write-Host "Model already exists:"
echo     Write-Host $Destination
echo     exit 0
echo }
echo.
echo $Url = "https://huggingface.co/" + $Repo + "/resolve/main/" + $GGUF
echo.
echo Write-Host "Downloading:"
echo Write-Host $Url
echo.
echo Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
echo.
echo if (-not (Test-Path $Destination)) {
echo     throw "Model download failed"
echo }
echo.
echo Write-Host "Downloaded:"
echo Write-Host $Destination

exit /b 0