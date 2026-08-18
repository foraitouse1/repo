::DownloadInstall-Python-Torch.bat

:: Downloads and installs the standard PyTorch build into the project's portable Python.
:: Provides the PyTorch machine-learning framework using its default package build.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable PyTorch Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE PYTORCH
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\Torch"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo       DOWNLOADING PYTORCH WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download torch -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading PyTorch
pause
exit /b 1
)

echo ====================================================
echo       INSTALLING PYTORCH
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" torch
if errorlevel 1 (
echo ERROR: Failed installing PyTorch
pause
exit /b 1
)

echo ====================================================
echo       VERIFYING PYTORCH
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import torch; print('PyTorch version:', torch.__version__); print('CUDA available:', torch.cuda.is_available())"
if errorlevel 1 (
echo ERROR: PyTorch verification failed
pause
exit /b 1
)

echo ====================================================
echo       PYTORCH INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
