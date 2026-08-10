::DownloadInstall-VulkanDLLs.bat
@echo off
setlocal EnableExtensions DisableDelayedExpansion

echo ====================================================
echo       PORTABLE VULKAN RUNTIME INSTALLER
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

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
echo $InstallDir = "%_LLAMA_DIR%"
echo.

echo if (-not (Test-Path $DownloadDir)) {
echo     New-Item -ItemType Directory -Path $DownloadDir -Force ^| Out-Null
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

echo $Files = @(

echo "$env:SystemRoot\System32\vulkan-1.dll"

echo "$env:SystemRoot\System32\vulkan-1-999-0-0-0.dll"

echo "$env:SystemRoot\System32\vulkaninfo.exe"

echo "$env:SystemRoot\System32\vulkaninfo-1-999-0-0-0.exe"

echo "$env:SystemRoot\SysWOW64\vulkan-1.dll"

echo "$env:SystemRoot\SysWOW64\vulkan-1-999-0-0-0.dll"

echo "$env:SystemRoot\SysWOW64\vulkaninfo.exe"

echo "$env:SystemRoot\SysWOW64\vulkaninfo-1-999-0-0-0.exe"

echo )

echo.

echo foreach ($File in $Files) {

echo.

echo     if (Test-Path $File) {

echo.

echo         Write-Host "Moving $File"

echo         Move-Item `
echo             -Path $File `
echo             -Destination $InstallDir `
echo             -Force

echo.

echo     }

echo.

echo }

echo.

echo Write-Host "Verifying portable Vulkan files"

echo.

echo $Required = @(

echo "vulkan-1.dll"

echo "vulkan-1-999-0-0-0.dll"

echo "vulkaninfo.exe"

echo "vulkaninfo-1-999-0-0-0.exe"

echo )

echo.

echo foreach ($File in $Required) {

echo.

echo     if (-not (Test-Path (Join-Path $InstallDir $File))) {

echo         throw "Missing Vulkan file: $File"

echo     }

echo.

echo }

echo.

echo Write-Host "Portable Vulkan Runtime verified"

exit /b 0
