::DownloadInstall-Python-Docling.bat

:: Downloads and installs Docling for document parsing and conversion.
:: Its dependencies are also downloaded for offline portability.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Docling Installer
:: ====================================================

echo ====================================================
echo         INSTALLING PORTABLE DOCLING
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Docling"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo         DOWNLOADING DOCLING WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download docling -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading Docling
pause
exit /b 1
)

echo ====================================================
echo         INSTALLING DOCLING
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" docling
if errorlevel 1 (
echo ERROR: Failed installing Docling
pause
exit /b 1
)

echo ====================================================
echo         VERIFYING DOCLING
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import docling; print('Docling version:', docling.__version__)"
if errorlevel 1 (
echo ERROR: Docling verification failed
pause
exit /b 1
)

echo ====================================================
echo         DOCLING INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
