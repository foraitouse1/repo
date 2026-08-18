::DownloadInstall-Python-Wheel.bat

:: Downloads and installs the latest wheel package into the project's portable Python.
:: Provides support for building and installing Python wheel packages.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Wheel Installer
:: ====================================================

echo ====================================================
echo          INSTALLING PORTABLE WHEEL
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Wheel"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo          DOWNLOADING WHEEL WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download wheel -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading Wheel
pause
exit /b 1
)

echo ====================================================
echo          INSTALLING WHEEL
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" --upgrade wheel
if errorlevel 1 (
echo ERROR: Failed installing Wheel
pause
exit /b 1
)

echo ====================================================
echo          VERIFYING WHEEL
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import wheel; print('Wheel version:', wheel.__version__)"
if errorlevel 1 (
echo ERROR: Wheel verification failed
pause
exit /b 1
)

echo ====================================================
echo          WHEEL INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
