::DownloadInstall-Python-Wand.bat

:: Downloads and installs Wand, the Python binding used to access ImageMagick.
:: Downloads the package and its dependencies for offline installation.

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Wand Installer
:: ====================================================

echo ====================================================
echo          INSTALLING PORTABLE WAND
echo        INSIDE ESTABLISHED _PYTHON_DIR
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"
if not defined _PYTHON_DIR (
echo ERROR: IsolateEnv-Project.bat failed to define _PYTHON_DIR
pause
exit /b 1
)

if not exist "%_PYTHON_DIR%\python.exe" (
echo ERROR: Python installation was not found
pause
exit /b 1
)

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Wand"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo          DOWNLOADING WAND WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download wand -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading Wand
pause
exit /b 1
)

echo ====================================================
echo          INSTALLING WAND
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" wand
if errorlevel 1 (
echo ERROR: Failed installing Wand
pause
exit /b 1
)

echo ====================================================
echo          VERIFYING WAND
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import wand; print('Wand version:', wand.version.VERSION)"
if errorlevel 1 (
echo ERROR: Wand verification failed
pause
exit /b 1
)

echo ====================================================
echo          WAND INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
