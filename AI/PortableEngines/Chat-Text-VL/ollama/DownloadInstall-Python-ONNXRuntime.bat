::DownloadInstall-Python-ONNXRuntime.bat

:: Downloads and installs ONNX Runtime for executing ONNX machine-learning models.
:: Its dependencies are downloaded locally for offline installation.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable ONNX Runtime Installer
:: ====================================================

echo ====================================================
echo       INSTALLING PORTABLE ONNX RUNTIME
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\ONNXRuntime"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo       DOWNLOADING ONNX RUNTIME WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download onnxruntime -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading ONNX Runtime
pause
exit /b 1
)

echo ====================================================
echo       INSTALLING ONNX RUNTIME
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" onnxruntime
if errorlevel 1 (
echo ERROR: Failed installing ONNX Runtime
pause
exit /b 1
)

echo ====================================================
echo       VERIFYING ONNX RUNTIME
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import onnxruntime; print('ONNX Runtime version:', onnxruntime.__version__)"
if errorlevel 1 (
echo ERROR: ONNX Runtime verification failed
pause
exit /b 1
)

echo ====================================================
echo       ONNX RUNTIME INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
