::DownloadInstall-Python-Numpy.bat

:: Downloads and installs NumPy, the Python numerical computing library.
:: Provides array and numerical operations required by several project packages.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable NumPy Installer
:: ====================================================

echo ====================================================
echo          INSTALLING PORTABLE NUMPY
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Numpy"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo          DOWNLOADING NUMPY WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download numpy -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading NumPy
pause
exit /b 1
)

echo ====================================================
echo          INSTALLING NUMPY
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" numpy
if errorlevel 1 (
echo ERROR: Failed installing NumPy
pause
exit /b 1
)

echo ====================================================
echo          VERIFYING NUMPY
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import numpy; print('NumPy version:', numpy.__version__)"
if errorlevel 1 (
echo ERROR: NumPy verification failed
pause
exit /b 1
)

echo ====================================================
echo          NUMPY INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
