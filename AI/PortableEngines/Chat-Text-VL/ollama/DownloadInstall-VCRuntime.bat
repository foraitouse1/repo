::DownloadInstall-VC++Runtime.bat

:: Downloads the latest Microsoft Visual C++ v14 x64 Redistributable.
:: Extracts the redistributable runtime DLLs into the isolated
:: COMMONPROGRAMFILES\VCRuntime directory so they can be shared
:: by applications running inside the isolated environment.
::
:: No system-wide VC++ installation is performed.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Visual C++ Runtime Installer
:: ====================================================

echo ====================================================
echo    INSTALLING PORTABLE VISUAL C++ RUNTIME
echo      INSIDE ISOLATED COMMONPROGRAMFILES
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined COMMONPROGRAMFILES (
echo ERROR: COMMONPROGRAMFILES was not defined by IsolateEnv.bat
pause
exit /b 1
)

set "_VC_RUNTIME_DIR=%COMMONPROGRAMFILES%\VCRuntime"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%\Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_VC_RUNTIME_DIR%" (
mkdir "%_VC_RUNTIME_DIR%"
)

set "_PS_FILE=%TEMP%\vc_runtime_install.ps1"

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
echo    VISUAL C++ RUNTIME INSTALL FAILED
echo ====================================================
pause
exit /b 1
)


:: ====================================================
:: Add centralized VC++ runtime directory to PATH
:: ====================================================

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%COMMONPROGRAMFILES%%%%VCRuntime;%%%%PATH%%%%"

if errorlevel 1 (
echo ERROR: Failed adding VC++ Runtime to PATH
pause
exit /b 1
)

echo ====================================================
echo    VISUAL C++ RUNTIME INSTALL COMPLETE
echo ====================================================
echo.
echo Runtime directory:
echo %_VC_RUNTIME_DIR%
echo.
echo The runtime directory has been added to the
echo isolated project PATH.
echo.

pause

endlocal
exit /b 0


:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $RuntimeDir = "%_VC_RUNTIME_DIR%"
echo.
echo $Url = "https://aka.ms/vc14/vc_redist.x64.exe"
echo $Installer = Join-Path $DownloadDir "vc_redist.x64.exe"
echo $LayoutDir = Join-Path $env:TEMP "VCRedistLayout_$([guid]::NewGuid().ToString('N'))"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $RuntimeDir)) {
echo     New-Item -ItemType Directory -Path $RuntimeDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $Installer)) {
echo     Write-Host "Downloading latest Microsoft Visual C++ Redistributable"
echo     Write-Host "Using native Windows curl.exe"
echo     Write-Host
echo.
echo     $Curl = Get-Command curl.exe -ErrorAction Stop
echo.
echo     ^& $Curl.Source `
echo         "--fail" `
echo         "--location" `
echo         "--retry" "3" `
echo         "--retry-delay" "2" `
echo         "-o" $Installer `
echo         $Url
echo.
echo     if ($LASTEXITCODE -ne 0) {
echo         throw "VC++ Redistributable download failed with curl exit code $LASTEXITCODE."
echo     }
echo }
echo else {
echo     Write-Host "VC++ Redistributable download already exists."
echo }
echo.
echo if (-not (Test-Path $Installer)) {
echo     throw "VC++ Redistributable installer was not downloaded."
echo }
echo.
echo Write-Host "Preparing temporary VC++ Redistributable layout"
echo.
echo New-Item -ItemType Directory -Path $LayoutDir -Force ^| Out-Null
echo.
echo $Process = Start-Process `
echo     -FilePath $Installer `
echo     -ArgumentList @("/layout", $LayoutDir) `
echo     -Wait `
echo     -PassThru `
echo     -NoNewWindow
echo.
echo if ($Process.ExitCode -ne 0) {
echo     throw "VC++ Redistributable layout extraction failed with exit code $($Process.ExitCode)."
echo }
echo.
echo if (-not (Test-Path $LayoutDir)) {
echo     throw "VC++ Redistributable layout directory was not created."
echo }
echo.
echo Write-Host "Preparing WiX bundle extractor"
echo.
echo $WixZip = Join-Path $DownloadDir "wix314-binaries.zip"
echo $WixDir = Join-Path $env:TEMP "Wix314"
echo $DarkExe = Join-Path $WixDir "dark.exe"
echo $BurnDir = Join-Path $env:TEMP "VCRedistBurn_$([guid]::NewGuid().ToString('N'))"
echo $WixUrl = "https://github.com/wixtoolset/wix3/releases/download/wix3141rtm/wix314-binaries.zip"
echo.
echo if (-not (Test-Path $DarkExe)) {
echo     Write-Host "Downloading WiX bundle extractor"
echo     Write-Host "Using native Windows curl.exe"
echo     Write-Host
echo.
echo     $Curl = Get-Command curl.exe -ErrorAction Stop
echo.
echo     ^& $Curl.Source `
echo         "--fail" `
echo         "--location" `
echo         "--retry" "3" `
echo         "--retry-delay" "2" `
echo         "-o" $WixZip `
echo         $WixUrl
echo.
echo     if ($LASTEXITCODE -ne 0) {
echo         throw "WiX download failed with curl exit code $LASTEXITCODE."
echo     }
echo.
echo     if (-not (Test-Path $WixZip)) {
echo         throw "WiX bundle extractor was not downloaded."
echo     }
echo.
echo     if (Test-Path $WixDir) {
echo         Remove-Item -Path $WixDir -Recurse -Force
echo     }
echo.
echo     New-Item -ItemType Directory -Path $WixDir -Force ^| Out-Null
echo.
echo     Write-Host "Extracting WiX bundle extractor"
echo.
echo     $Process = Start-Process `
echo         -FilePath "tar.exe" `
echo         -ArgumentList @("-xf", $WixZip, "-C", $WixDir) `
echo         -Wait `
echo         -PassThru `
echo         -NoNewWindow
echo.
echo     if ($Process.ExitCode -ne 0) {
echo         throw "WiX bundle extractor extraction failed with exit code $($Process.ExitCode)."
echo     }
echo }
echo.
echo if (-not $DarkExe) {
echo     $DarkExe = Get-ChildItem `
echo         -Path $WixDir `
echo         -Recurse `
echo         -File `
echo         -Filter "dark.exe" `
echo         -ErrorAction SilentlyContinue ^|
echo         Select-Object -First 1 -ExpandProperty FullName
echo }
echo.
echo if (-not $DarkExe -or -not (Test-Path $DarkExe)) {
echo     throw "WiX dark.exe was not found."
echo }
echo.
echo Write-Host "Extracting Visual C++ runtime bundle"
echo.
echo New-Item -ItemType Directory -Path $BurnDir -Force ^| Out-Null
echo.
echo $Process = Start-Process `
echo     -FilePath $DarkExe `
echo     -ArgumentList @("-nologo", "-x", $BurnDir, $Installer) `
echo     -Wait `
echo     -PassThru `
echo     -NoNewWindow
echo.
echo if ($Process.ExitCode -ne 0) {
echo     throw "Visual C++ runtime bundle extraction failed with exit code $($Process.ExitCode)."
echo }
echo.
echo $CabFiles = Get-ChildItem `
echo     -Path $BurnDir `
echo     -Recurse `
echo     -File `
echo     -Filter "cab1.cab" `
echo     -ErrorAction SilentlyContinue ^|
echo     Where-Object {
echo         $_.FullName -match 'vcRuntime(Minimum^|Additional)_amd64'
echo     }
echo.
echo if (-not $CabFiles) {
echo     throw "No x64 Visual C++ runtime CAB files were found."
echo }
echo.
echo Write-Host "Extracting x64 Visual C++ runtime files"
echo.
echo $ExtractDir = Join-Path $env:TEMP "VCRedistExtract_$([guid]::NewGuid().ToString('N'))"
echo New-Item -ItemType Directory -Path $ExtractDir -Force ^| Out-Null
echo.
echo foreach ($Cab in $CabFiles) {
echo     Write-Host "Extracting $($Cab.Name)"
echo     $Process = Start-Process `
echo         -FilePath "expand.exe" `
echo         -ArgumentList @("-F:*", $Cab.FullName, $ExtractDir) `
echo         -Wait `
echo         -PassThru `
echo         -NoNewWindow
echo.
echo     if ($Process.ExitCode -ne 0) {
echo         throw "Visual C++ runtime CAB extraction failed with exit code $($Process.ExitCode)."
echo     }
echo }
echo.
echo Write-Host "Locating x64 Visual C++ runtime files"
echo.
echo $RuntimeNames = @(
echo     "concrt140.dll",
echo     "msvcp140.dll",
echo     "msvcp140_1.dll",
echo     "msvcp140_2.dll",
echo     "msvcp140_atomic_wait.dll",
echo     "msvcp140_codecvt_ids.dll",
echo     "vccorlib140.dll",
echo     "vcruntime140.dll",
echo     "vcruntime140_1.dll",
echo     "vcruntime140_threads.dll",
echo     "vcomp140.dll",
echo     "vcamp140.dll"
echo )
echo.
echo $Copied = 0
echo.
echo foreach ($Name in $RuntimeNames) {
echo     $Candidates = Get-ChildItem `
echo         -Path $ExtractDir `
echo         -Recurse `
echo         -File `
echo         -Filter "$Name`_amd64" `
echo         -ErrorAction SilentlyContinue
echo.
echo     $Candidate = $Candidates ^|
echo         Where-Object {
echo             $_.FullName -notmatch '\\(x86^|arm64^|arm)\\' -and
echo             $_.FullName -notmatch 'debug'
echo         } ^|
echo         Select-Object -First 1
echo.
echo     if ($Candidate) {
echo         Write-Host "Installing $Name"
echo         Copy-Item `
echo             -Path $Candidate.FullName `
echo             -Destination (Join-Path $RuntimeDir $Name) `
echo             -Force
echo         $Copied++
echo     }
echo }
echo.
echo if ($Copied -eq 0) {
echo     throw "No x64 Visual C++ runtime DLLs were found in the redistributable layout."
echo }
echo.
echo Write-Host "Verifying shared Visual C++ runtime"
echo.
echo $Required = @(
echo     "msvcp140.dll",
echo     "vcruntime140.dll",
echo     "vcruntime140_1.dll"
echo )
echo.
echo foreach ($Name in $Required) {
echo     $Path = Join-Path $RuntimeDir $Name
echo     if (-not (Test-Path $Path)) {
echo         throw "Required VC++ runtime DLL is missing: $Name"
echo     }
echo }
echo.
echo Write-Host "VC++ runtime DLLs installed:"
echo Get-ChildItem -Path $RuntimeDir -Filter "*.dll" ^|
echo     Select-Object -ExpandProperty Name
echo.
echo Write-Host "Portable Visual C++ Runtime verified"
echo.
echo Remove-Item -Path $LayoutDir -Recurse -Force -ErrorAction SilentlyContinue
echo Remove-Item -Path $ExtractDir -Recurse -Force -ErrorAction SilentlyContinue
echo Remove-Item -Path $BurnDir -Recurse -Force -ErrorAction SilentlyContinue
echo.
exit /b 0