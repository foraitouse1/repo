::DownloadInstall-VulkanDLLs.bat

:: Downloads the required Vulkan runtime DLL components.
:: Provides Vulkan runtime support for applications that use Vulkan without requiring a system-wide Vulkan SDK installation.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

echo ====================================================
echo       PORTABLE VULKAN RUNTIME INSTALLER
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined _ENGINE_DIR (
echo ERROR: IsolateEnv-Project.bat failed to define _ENGINE_DIR
pause
exit /b 1
)

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

set "_PS_FILE=%TEMP%\vulkan_runtime_install.ps1"

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
echo       VULKAN INSTALL FAILED
echo ====================================================
pause
exit /b 1
)

del "%_PS_FILE%" >nul 2>&1

echo ====================================================
echo       VULKAN INSTALL COMPLETE
echo ====================================================

pause

endlocal
exit /b 0

:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $Root = "%SCRIPT_DIR%"
echo $DownloadDir = "%_DOWNLOAD_DIR%"
echo $InstallDir = "%_ENGINE_DIR%"
echo.
echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
echo }
echo.
echo if (-not (Test-Path $InstallDir)) {
echo     New-Item -ItemType Directory -Path $InstallDir -Force ^| Out-Null
echo }
echo.
echo Write-Host "Searching cached Vulkan installer"
echo.
echo $Installer = Get-ChildItem `
echo     -Path $DownloadDir `
echo     -Filter "VulkanRT-X64-*-Installer.exe" `
echo     -File `
echo     -ErrorAction SilentlyContinue ^|
echo     Sort-Object Name -Descending ^|
echo     Select-Object -First 1
echo.
echo if (-not $Installer) {
echo.
echo     Write-Host "Finding latest Vulkan Runtime"
echo.
echo     $Page = Invoke-WebRequest `
echo         -Uri "https://vulkan.lunarg.com/sdk/home" `
echo         -UseBasicParsing
echo.
echo     $Match = [regex]::Matches(
echo         $Page.Content,
echo         'https://[^"]*VulkanRT-X64-[^"]*-Installer\.exe'
echo     )
echo.
echo     if ($Match.Count -eq 0) {
echo         throw "Unable to find Vulkan Runtime installer"
echo     }
echo.
echo     $Url = $Match[$Match.Count-1].Value
echo.
echo     $Name = Split-Path $Url -Leaf
echo.
echo     $InstallerPath = Join-Path $DownloadDir $Name
echo.
echo     Write-Host "Downloading:"
echo     Write-Host $Url
echo.
echo     Invoke-WebRequest `
echo         -Uri $Url `
echo         -OutFile $InstallerPath `
echo         -UseBasicParsing
echo.
echo     $Installer = Get-Item $InstallerPath
echo.
echo }
echo.
echo Write-Host "Using installer:"
echo Write-Host $Installer.FullName
echo.
echo Write-Host "Installing Vulkan silently"
echo.
echo Start-Process `
echo     -FilePath $Installer.FullName `
echo     -ArgumentList "/S" `
echo     -Wait
echo.
echo Write-Host "Moving Vulkan runtime files"
echo.
echo $SearchPaths = @(
echo     "$env:SystemRoot\System32",
echo     "$env:SystemRoot\SysWOW64"
echo )
echo.
echo $VulkanFiles = @()
echo.
echo foreach ($SearchPath in $SearchPaths) {
echo.
echo     if (Test-Path $SearchPath) {
echo.
echo         $VulkanFiles += Get-ChildItem `
echo             -Path $SearchPath `
echo             -File `
echo             -ErrorAction SilentlyContinue ^|
echo             Where-Object {
echo                 $_.Name -match "^vulkan.*\.dll$" -or
echo                 $_.Name -match "^vulkaninfo.*\.exe$"
echo             }
echo.
echo     }
echo.
echo }
echo.
echo $VulkanFiles = $VulkanFiles ^|
echo     Sort-Object FullName -Unique
echo.
echo if (-not $VulkanFiles) {
echo     throw "No Vulkan runtime files were found in the Windows system directories."
echo }
echo.
echo foreach ($File in $VulkanFiles) {
echo.
echo     Write-Host "Moving $($File.FullName)"
echo.
echo     Move-Item `
echo         -Path $File.FullName `
echo         -Destination $InstallDir `
echo         -Force
echo.
echo }
echo.
echo Write-Host "Vulkan runtime files moved to:"
echo Write-Host $InstallDir
echo.
echo Write-Host "Vulkan runtime installation complete"
echo.
echo exit 0