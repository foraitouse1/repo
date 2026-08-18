::DownloadInstall-Python-Torch-CU130.bat

:: Downloads and installs the PyTorch build with CUDA 13.0 support.
:: Provides GPU acceleration through the official PyTorch CUDA 13.0 package.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable PyTorch CUDA 13.0 Installer
:: ====================================================

echo ====================================================
echo     INSTALLING PORTABLE PYTORCH CUDA 13.0
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Torch-CU130"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo       DOWNLOADING PYTORCH CUDA 13.0 WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download torch -d "%_DOWNLOAD_DIR%" --index-url https://download.pytorch.org/whl/cu130 --extra-index-url https://pypi.org/simple
if errorlevel 1 (
echo ERROR: Failed downloading PyTorch CUDA 13.0
pause
exit /b 1
)

echo ====================================================
echo       INSTALLING PYTORCH CUDA 13.0
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" torch
if errorlevel 1 (
echo ERROR: Failed installing PyTorch CUDA 13.0
pause
exit /b 1
)

echo ====================================================
echo       VERIFYING PYTORCH CUDA 13.0
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available()); print('CUDA version:', torch.version.cuda)"
if errorlevel 1 (
echo ERROR: PyTorch CUDA 13.0 verification failed
pause
exit /b 1
)

echo ====================================================
echo     PYTORCH CUDA 13.0 INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
