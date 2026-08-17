::DownloadInstall-Python-HFXet.bat

:: Downloads and installs the Hugging Face Xet package.
:: Provides Xet-based storage and transfer support for Hugging Face assets.

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable HF-Xet Installer
:: ====================================================

echo ====================================================
echo         INSTALLING PORTABLE HF-XET
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\HFXet"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo         DOWNLOADING HF-XET WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download hf_xet -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading HF-Xet
pause
exit /b 1
)

echo ====================================================
echo         INSTALLING HF-XET
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" hf_xet
if errorlevel 1 (
echo ERROR: Failed installing HF-Xet
pause
exit /b 1
)

echo ====================================================
echo         VERIFYING HF-XET
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import hf_xet; print('HF-Xet installed successfully')"
if errorlevel 1 (
echo ERROR: HF-Xet verification failed
pause
exit /b 1
)

echo ====================================================
echo         HF-XET INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
