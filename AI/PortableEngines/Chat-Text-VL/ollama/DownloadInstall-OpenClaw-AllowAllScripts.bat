::DownloadInstall-OpenClaw-AllowAllScripts.bat

:: Enables or disables npm's permanent
:: dangerously-allow-all-scripts setting.
:: This setting controls whether npm allows
:: dependency install scripts to run.

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: OpenClaw npm Allow-All Scripts Configuration
:: ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if errorlevel 1 (
echo ERROR: Failed initializing isolated environment
pause
exit /b 1
)

echo ====================================================
echo    OPENCLAW NPM ALLOW-ALL SCRIPTS
echo ====================================================
echo.
echo 1. Enable permanently
echo 2. Disable permanently
echo 3. Cancel
echo.

choice /C 123 /N /M "Select an option: "

if errorlevel 3 (
echo.
echo Operation cancelled.
endlocal
exit /b 0
)

if errorlevel 2 goto DisableAllowAll
if errorlevel 1 goto EnableAllowAll

:EnableAllowAll

echo.
echo Enabling permanent npm allow-all scripts.
echo.

npm config set dangerously-allow-all-scripts true

if errorlevel 1 (
echo.
echo ERROR: Failed enabling allow-all scripts.
pause
endlocal
exit /b 1
)

echo.
echo ====================================================
echo    PERMANENT ALLOW-ALL SCRIPTS ENABLED
echo ====================================================
echo.
echo npm will now allow all dependency
echo install scripts.
echo.

pause
endlocal
exit /b 0


:DisableAllowAll

echo.
echo Disabling permanent npm allow-all scripts.
echo.

npm config delete dangerously-allow-all-scripts

if errorlevel 1 (
echo.
echo ERROR: Failed disabling allow-all scripts.
pause
endlocal
exit /b 1
)

echo.
echo ====================================================
echo    PERMANENT ALLOW-ALL SCRIPTS DISABLED
echo ====================================================
echo.
echo npm has returned to its normal setting.
echo.

pause
endlocal
exit /b 0