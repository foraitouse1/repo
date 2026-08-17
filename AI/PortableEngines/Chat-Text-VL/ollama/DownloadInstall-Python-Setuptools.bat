::DownloadInstall-Python-Setuptools.bat

:: Downloads and installs the latest setuptools into the project's portable Python.
:: Provides Python package building and installation support.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Setuptools Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE SETUPTOOLS
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Setuptools"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo       DOWNLOADING SETUPTOOLS WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download setuptools -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading Setuptools
pause
exit /b 1
)

echo ====================================================
echo       INSTALLING SETUPTOOLS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" --upgrade setuptools
if errorlevel 1 (
echo ERROR: Failed installing Setuptools
pause
exit /b 1
)

echo ====================================================
echo       VERIFYING SETUPTOOLS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import setuptools; print('Setuptools version:', setuptools.__version__)"
if errorlevel 1 (
echo ERROR: Setuptools verification failed
pause
exit /b 1
)

echo ====================================================
echo       SETUPTOOLS INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
