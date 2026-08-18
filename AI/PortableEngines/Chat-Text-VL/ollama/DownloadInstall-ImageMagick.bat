::DownloadInstall-ImageMagick.bat

:: Downloads and installs the portable ImageMagick distribution.
:: Provides image conversion, processing, and MagickWand functionality.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable ImageMagick Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE IMAGEMAGICK
echo        INSIDE ESTABLISHED _IMAGEMAGICK_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SSL_CERT_FILE (
echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
pause
exit /b 1
)

set "_IMAGEMAGICK_DIR=%SCRIPT_DIR%\ImageMagick"
set "_DOWNLOAD_DIR=%SCRIPT_DIR%\Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

if not exist "%_IMAGEMAGICK_DIR%" (
mkdir "%_IMAGEMAGICK_DIR%"
)

set "_PS_FILE=%TEMP%\imagemagick_install.ps1"

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
echo       IMAGEMAGICK INSTALL FAILED
echo ====================================================
pause
exit /b 1
)


call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_IMAGEMAGICK_DIR=%%%%SCRIPT_DIR%%%%\ImageMagick"
if errorlevel 1 (
echo ERROR: Failed adding _IMAGEMAGICK_DIR to IsolateEnv-Project.bat
pause
exit /b 1
)

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%PATH%%%%;%%%%SCRIPT_DIR%%%%\ImageMagick"
if errorlevel 1 (
echo ERROR: Failed adding ImageMagick to PATH in IsolateEnv-Project.bat
pause
exit /b 1
)

echo ====================================================
echo       IMAGEMAGICK INSTALL COMPLETE
echo ====================================================
echo.
echo ImageMagick directory: %_IMAGEMAGICK_DIR%
echo.

pause

endlocal
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $ImageMagickDir = "%_IMAGEMAGICK_DIR%"
echo $DownloadPage = "https://imagemagick.org/download/"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $ImageMagickDir)) {
echo     New-Item -ItemType Directory -Path $ImageMagickDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Determining latest stable ImageMagick release"
echo.
echo $Page = Invoke-WebRequest `
echo     -Uri $DownloadPage `
echo     -UseBasicParsing
echo.
echo $Matches = [regex]::Matches(
echo     $Page.Content,
echo     'ImageMagick-([0-9]+\.[0-9]+\.[0-9]+-[0-9]+)-portable-Q16-x64\.7z'
echo )
echo.
echo if ($Matches.Count -eq 0) {
echo     throw "No portable 64-bit ImageMagick release was found."
echo }
echo.
echo $Releases = foreach ($Match in $Matches) {
echo     [PSCustomObject]@{
echo         Version = $Match.Groups[1].Value
echo         FileName = $Match.Value
echo     }
echo }
echo.
echo $Latest = $Releases ^|
echo     Sort-Object {
echo         $Parts = $_.Version -split '-'
echo         [version]$Parts[0]
echo         [int]$Parts[1]
echo     } -Descending ^|
echo     Select-Object -First 1
echo.
echo if (-not $Latest) {
echo     throw "Unable to determine the latest stable ImageMagick release."
echo }
echo.
echo $FileName = $Latest.FileName
echo $Url = "https://imagemagick.org/archive/binaries/$FileName"
echo $Archive = Join-Path $DownloadDir $FileName
echo $MagickExe = Join-Path $ImageMagickDir "magick.exe"
echo.
echo Write-Host "Latest stable ImageMagick: $($Latest.Version)"
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
echo     throw "ImageMagick archive was not downloaded."
echo }
echo.
echo $InstallRequired = $true
echo.
echo if (Test-Path $MagickExe) {
echo     $InstalledVersion = ^& $MagickExe --version
echo     if ($InstalledVersion -match [regex]::Escape($Latest.Version)) {
echo         $InstallRequired = $false
echo         Write-Host "ImageMagick $($Latest.Version) is already installed."
echo     }
echo }
echo.
echo if ($InstallRequired) {
echo     Write-Host "Extracting ImageMagick $($Latest.Version)"
echo.
echo     $Tar = Get-Command tar.exe -ErrorAction SilentlyContinue
echo     if (-not $Tar) {
echo         throw "Windows tar.exe was not found. A 7-Zip extractor is required for the official ImageMagick portable archive."
echo     }
echo.
echo     $TempDir = Join-Path $DownloadDir "ImageMagickExtract"
echo.
echo     if (Test-Path $TempDir) {
echo         Remove-Item $TempDir -Recurse -Force
echo     }
echo.
echo     New-Item -ItemType Directory -Path $TempDir -Force ^| Out-Null
echo.
echo     $Process = Start-Process `
echo         -FilePath $Tar.Source `
echo         -ArgumentList @(
echo             "-xf"
echo             $Archive
echo             "-C"
echo             $TempDir
echo         ) `
echo         -Wait `
echo         -PassThru
echo.
echo     if ($Process.ExitCode -ne 0) {
echo         throw "ImageMagick archive extraction failed with exit code $($Process.ExitCode)."
echo     }
echo.
echo     $Root = Get-ChildItem $TempDir -Directory ^| Select-Object -First 1
echo.
echo     if ($Root) {
echo         Get-ChildItem $ImageMagickDir -Force ^| Remove-Item -Recurse -Force
echo         Get-ChildItem $Root.FullName -Force ^| Move-Item -Destination $ImageMagickDir -Force
echo     }
echo     else {
echo         Get-ChildItem $ImageMagickDir -Force ^| Remove-Item -Recurse -Force
echo         Get-ChildItem $TempDir -Force ^| Move-Item -Destination $ImageMagickDir -Force
echo     }
echo.
echo     Remove-Item $TempDir -Recurse -Force
echo }
echo.
echo if (-not (Test-Path $MagickExe)) {
echo     throw "magick.exe was not found after installation."
echo }
echo.
echo Write-Host "Verifying ImageMagick"
echo.
echo $VersionOutput = ^& $MagickExe --version
echo if ($LASTEXITCODE -ne 0) {
echo     throw "ImageMagick verification failed."
echo }
echo.
echo Write-Host $VersionOutput
echo Write-Host "Portable ImageMagick verified"
echo.
exit /b 0
