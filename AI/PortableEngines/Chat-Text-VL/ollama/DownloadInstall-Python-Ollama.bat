::DownloadInstall-Python-Ollama.bat

:: Downloads and installs the Ollama Python client library.
:: Provides Python applications with access to the Ollama API.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Ollama Python Package Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE OLLAMA PYTHON PACKAGE
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Ollama-Python"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo       DOWNLOADING OLLAMA PYTHON PACKAGE
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download ollama -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading Ollama Python package
pause
exit /b 1
)

echo ====================================================
echo       INSTALLING OLLAMA PYTHON PACKAGE
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" ollama
if errorlevel 1 (
echo ERROR: Failed installing Ollama Python package
pause
exit /b 1
)

echo ====================================================
echo       VERIFYING OLLAMA PYTHON PACKAGE
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "from importlib.metadata import version; print('Ollama Python package version:', version('ollama'))"

if errorlevel 1 (
echo ERROR: Ollama Python package verification failed
pause
exit /b 1
)

echo ====================================================
echo       OLLAMA PYTHON PACKAGE INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
