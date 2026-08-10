::Run-Llamacpp.bat

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Llama.cpp Server Launcher
:: ====================================================

:: Context size
set "_CONTEXT_SIZE=32768"

:: GPU layers
set "_GPU_LAYERS=-1"

set "_PORT=11434"

::add new env var for downline scripts
call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_PORT=%_PORT%"

echo ====================================================
echo       STARTING PORTABLE LOCAL SERVER
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined _LLAMA_DIR (
echo ERROR: IsolateEnv-Project.bat failed to define _LLAMA_DIR
pause
exit /b 1
)

set "_PS_FILE=%TEMP%\Run-Llamacpp.ps1"

call :WritePowerShell > "%_PS_FILE%"

powershell.exe ^
-NoProfile ^
-ExecutionPolicy Bypass ^
-File "%_PS_FILE%"

if errorlevel 1 (
    echo ====================================================
    echo       SERVER FAILED
    echo ====================================================
    pause
    exit /b 1
)

echo ====================================================
echo       SERVER STOPPED
echo ====================================================

pause
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"

echo.

echo $Root = "%SCRIPT_DIR%"

echo $LlamaServer = Join-Path "%_LLAMA_DIR%" "llama-server.exe"

echo $ModelRoot = Join-Path $Root "Models"
echo.

echo if ^(-not ^(Test-Path $LlamaServer^)^) {

echo     throw "llama-server.exe missing: $LlamaServer"

echo }



echo.

echo Write-Host "Searching for primary GGUF model"


echo.

echo $ModelFile = Get-ChildItem -Path $ModelRoot -Filter "*.gguf" -Recurse -ErrorAction SilentlyContinue ^|

echo Where-Object {

echo     $_.Name -notmatch "mmproj" -and

echo     $_.Name -notmatch "proj" -and

echo     $_.Name -notmatch "clip" -and

echo     $_.Name -notmatch "encoder" -and

echo     $_.Name -notmatch "vae"

echo } ^|

echo Select-Object -First 1



echo.

echo if ^(-not $ModelFile^) {

echo     throw "No primary GGUF model found"

echo }



echo.

echo Write-Host "Primary model:"

echo Write-Host $ModelFile.FullName



echo.

echo $MmProjFile = Get-ChildItem -Path $ModelRoot -Filter "mmproj*.gguf" -Recurse -ErrorAction SilentlyContinue ^|

echo Select-Object -First 1



echo.

echo if ^($MmProjFile^) {

echo     Write-Host "Vision projector detected:"

echo     Write-Host $MmProjFile.FullName

echo }



echo.

echo Write-Host "Checking GGUF file"



echo.

echo $Stream = [System.IO.File]::OpenRead($ModelFile.FullName)

echo $Reader = New-Object System.IO.BinaryReader($Stream)

echo $Magic = [Text.Encoding]::ASCII.GetString($Reader.ReadBytes(4))

echo $Reader.Close()

echo $Stream.Close()



echo.

echo if ^($Magic -ne "GGUF"^) {

echo     throw "Invalid GGUF file"

echo }



echo.

echo Write-Host "GGUF model check passed"



echo.

echo Write-Host "===================================================="

echo Write-Host " Starting Local Server"

echo Write-Host "===================================================="



echo.

echo Write-Host "Backend: %_LLAMA_BACKEND%"

echo Write-Host "Model: $($ModelFile.FullName)"

echo Write-Host "Host: %_HOST%"

echo Write-Host "Port: %_PORT%"



echo.


echo $Args = @(

echo     "-m", $ModelFile.FullName,

echo     "--host", "%_HOST%",

echo     "--port", "%_PORT%",

echo     "-c", "%_CONTEXT_SIZE%",

echo     "--gpu-layers", "%_GPU_LAYERS%",

echo     "--no-kv-offload",

echo     "--ui",

echo     "-lv", "3",

echo     "--jinja",

echo     "--reasoning-preserve"

echo )


echo.

echo if ^($MmProjFile^) {

echo     Write-Host "Enabling vision projector"

echo.

echo     $Args += "--mmproj"

echo     $Args += $MmProjFile.FullName

echo.

echo     $Args += "--image-min-tokens"

echo     $Args += "1024"

echo }



echo.

echo Write-Host ""

echo Write-Host "Final llama-server arguments:"

echo $Args ^| ForEach-Object { Write-Host "  $_" }



echo.

echo Write-Host ""

echo Write-Host "Launching llama.cpp server..."



echo.

echo ^& $LlamaServer @Args



echo.

echo $ExitCode = $LASTEXITCODE



echo.

echo Write-Host ""

echo Write-Host "Exit code: $ExitCode"



echo.

echo if ^($ExitCode -ne 0^) {

echo     throw "llama.cpp server failed"

echo }



echo.

echo Write-Host "Server stopped"

exit /b 0
