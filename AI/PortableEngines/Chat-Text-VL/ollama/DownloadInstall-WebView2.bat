::DownloadInstall-WebView2.bat

:: Downloads and installs the Microsoft Edge WebView2 Evergreen Runtime.
:: WebView2 is a Windows runtime dependency used by applications such as
:: the Ollama Windows desktop application.
::
:: The Evergreen Bootstrapper is intentionally used here because Microsoft
:: provides it specifically for online installation of the current runtime.
::
:: The runtime itself is installed by Windows and is shared by WebView2
:: applications. It is NOT copied into SCRIPT_DIR.


@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Microsoft Edge WebView2 Runtime Installer
:: ====================================================

echo ====================================================
echo       INSTALLING MICROSOFT EDGE WEBVIEW2
echo ====================================================

call "%~dp0IsolateEnv-Initialize.bat"

if not defined SSL_CERT_FILE (
    echo ERROR: IsolateEnv-Project.bat failed to define SSL_CERT_FILE
    pause
    exit /b 1
)

:: ====================================================
:: Established project directories
:: ====================================================

set "_DOWNLOAD_DIR=%SCRIPT_DIR%\Downloads"

if not exist "%_DOWNLOAD_DIR%" (
    mkdir "%_DOWNLOAD_DIR%"
)

:: ====================================================
:: WebView2 Bootstrapper
:: ====================================================
::
:: Microsoft provides this as the Evergreen Bootstrapper.
:: It is a small installer which downloads and installs the
:: current WebView2 Runtime appropriate for this Windows system.
::
:: ====================================================

set "_WEBVIEW2_INSTALLER=%_DOWNLOAD_DIR%\MicrosoftEdgeWebView2Setup.exe"

:: Official Microsoft WebView2 Evergreen Bootstrapper.
set "_WEBVIEW2_URL=https://go.microsoft.com/fwlink/?linkid=2124703"

:: ====================================================
:: Check whether WebView2 is already installed
:: ====================================================
::
:: Microsoft documents the "pv" registry value as the
:: supported detection mechanism.
::
:: On 64-bit Windows:
::
:: HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{GUID}
:: HKCU\Software\Microsoft\EdgeUpdate\Clients\{GUID}
::
:: ====================================================

set "_WEBVIEW2_GUID={F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}"
set "_WEBVIEW2_VERSION="

echo.
echo Checking for installed Microsoft Edge WebView2 Runtime
echo.

:: Check per-machine installation.
for /f "tokens=2,*" %%A in ('
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\%_WEBVIEW2_GUID%" /v pv 2^>nul
') do (
    if /i "%%A"=="REG_SZ" set "_WEBVIEW2_VERSION=%%B"
)

:: If not found, check per-user installation.
if not defined _WEBVIEW2_VERSION (
    for /f "tokens=2,*" %%A in ('
        reg query "HKCU\Software\Microsoft\EdgeUpdate\Clients\%_WEBVIEW2_GUID%" /v pv 2^>nul
    ') do (
        if /i "%%A"=="REG_SZ" set "_WEBVIEW2_VERSION=%%B"
    )
)

:: ====================================================
:: Existing runtime
:: ====================================================

if defined _WEBVIEW2_VERSION (
    if not "%_WEBVIEW2_VERSION%"=="0.0.0.0" (
        echo WebView2 Runtime is already installed.
        echo Version: %_WEBVIEW2_VERSION%
        echo.
        echo No installation required.
        echo ====================================================
        echo       WEBVIEW2 INSTALL COMPLETE
        echo ====================================================
        echo.
        pause
        endlocal
        exit /b 0
    )
)

echo WebView2 Runtime was not detected.
echo.

:: ====================================================
:: Download Bootstrapper
:: ====================================================

if exist "%_WEBVIEW2_INSTALLER%" (
    echo WebView2 Bootstrapper already exists.
    echo File: %_WEBVIEW2_INSTALLER%
    echo Skipping download.
) else (
    echo Downloading Microsoft Edge WebView2 Bootstrapper
    echo.

    where curl.exe >nul 2>&1

    if errorlevel 1 (
        echo ERROR: Native Windows curl.exe was not found.
        echo.
        pause
        endlocal
        exit /b 1
    )

    echo Using native Windows curl.exe
    echo.

    curl.exe ^
        --fail ^
        --location ^
        --retry 3 ^
        --retry-delay 2 ^
        --output "%_WEBVIEW2_INSTALLER%" ^
        "%_WEBVIEW2_URL%"

    if errorlevel 1 (
        echo.
        echo ERROR: Failed downloading WebView2 Bootstrapper.
        pause
        endlocal
        exit /b 1
    )
)

:: ====================================================
:: Confirm download
:: ====================================================

if not exist "%_WEBVIEW2_INSTALLER%" (
    echo ERROR: WebView2 Bootstrapper was not downloaded.
    pause
    endlocal
    exit /b 1
)

:: ====================================================
:: Install WebView2
:: ====================================================
::
:: /silent = no interactive installer UI
:: /install = install the Evergreen WebView2 Runtime
::
:: If this script is run elevated, Microsoft installs it
:: per-machine. Otherwise the installer performs a per-user
:: installation when possible.
::
:: ====================================================

echo.
echo ====================================================
echo       INSTALLING WEBVIEW2 RUNTIME
echo ====================================================
echo.
echo Installer:
echo %_WEBVIEW2_INSTALLER%
echo.

"%_WEBVIEW2_INSTALLER%" /silent /install

set "_WEBVIEW2_EXIT=%ERRORLEVEL%"

if not "%_WEBVIEW2_EXIT%"=="0" (
    echo.
    echo ERROR: WebView2 installation failed.
    echo Exit code: %_WEBVIEW2_EXIT%
    pause
    endlocal
    exit /b %_WEBVIEW2_EXIT%
)

:: ====================================================
:: Finished
:: ====================================================

echo.
echo ====================================================
echo       WEBVIEW2 INSTALL COMPLETE
echo ====================================================
echo.
echo Microsoft Edge WebView2 Runtime installation command
echo completed successfully.
echo.
echo The runtime is installed as a Windows component and
echo is shared by applications that use WebView2.
echo.
echo Bootstrapper:
echo %_WEBVIEW2_INSTALLER%
echo.

pause

endlocal
exit /b 0
