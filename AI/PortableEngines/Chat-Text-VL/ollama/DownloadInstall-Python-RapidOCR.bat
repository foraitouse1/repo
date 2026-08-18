::DownloadInstall-Python-RapidOCR.bat

:: Downloads and installs the RapidOCR Python package.
:: Provides OCR functionality for extracting text from images and documents.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable RapidOCR Python Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE RAPIDOCR PYTHON
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\RapidOCR-Python"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo       DOWNLOADING RAPIDOCR PYTHON WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download rapidocr-python -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading RapidOCR Python
pause
exit /b 1
)

echo ====================================================
echo       INSTALLING RAPIDOCR PYTHON
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" rapidocr-python
if errorlevel 1 (
echo ERROR: Failed installing RapidOCR Python
pause
exit /b 1
)

echo ====================================================
echo       VERIFYING RAPIDOCR PYTHON
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "from rapidocr_python import RapidOCR; print('RapidOCR Python imported successfully')"
if errorlevel 1 (
echo ERROR: RapidOCR Python verification failed
pause
exit /b 1
)

echo ====================================================
echo       RAPIDOCR PYTHON INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
