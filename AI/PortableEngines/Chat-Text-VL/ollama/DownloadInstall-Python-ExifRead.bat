::DownloadInstall-Python-ExifRead.bat

:: Downloads and installs ExifRead for reading EXIF and related metadata from image files.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable ExifRead Installer
:: ====================================================

echo ====================================================
echo        INSTALLING PORTABLE EXIFREAD
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

set "_DOWNLOAD_DIR=%SCRIPT_DIR%Downloads\ExifRead"

if not exist "%_DOWNLOAD_DIR%" (
mkdir "%_DOWNLOAD_DIR%"
)

echo ====================================================
echo        DOWNLOADING EXIFREAD WHEELS
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip download exifread -d "%_DOWNLOAD_DIR%"
if errorlevel 1 (
echo ERROR: Failed downloading ExifRead
pause
exit /b 1
)

echo ====================================================
echo        INSTALLING EXIFREAD
echo ====================================================

"%_PYTHON_DIR%\python.exe" -m pip install --no-index --find-links "%_DOWNLOAD_DIR%" exifread
if errorlevel 1 (
echo ERROR: Failed installing ExifRead
pause
exit /b 1
)

echo ====================================================
echo        VERIFYING EXIFREAD
echo ====================================================

"%_PYTHON_DIR%\python.exe" -c "import exifread; print('ExifRead version:', exifread.__version__)"
if errorlevel 1 (
echo ERROR: ExifRead verification failed
pause
exit /b 1
)

echo ====================================================
echo        EXIFREAD INSTALL COMPLETE
echo ====================================================
echo.

pause

endlocal
exit /b 0
