:: Configure-OpenClaw-Web.bat
::
:: Enables OpenClaw web tools in the isolated portable environment.
:: Does not modify Windows system configuration.
::

@echo off
setlocal EnableExtensions DisableDelayedExpansion

echo ============================================================
echo        CONFIGURING OPENCLAW INTERNET ACCESS
echo ============================================================
echo.

:: ============================================================
:: Initialize isolated environment
:: ============================================================

call "%~dp0IsolateEnv-Initialize.bat"

if errorlevel 1 (
    echo.
    echo ERROR: IsolateEnv initialization failed.
    pause
    exit /b 1
)

:: ============================================================
:: Locate portable OpenClaw
:: ============================================================

if not defined _NODEJS_DIR (
    echo.
    echo ERROR: _NODEJS_DIR is not defined.
    pause
    exit /b 1
)

set "_OPENCLAW_CMD=%_NODEJS_DIR%\openclaw.cmd"
set "_OPENCLAW_DIR=%_NODEJS_DIR%\node_modules\openclaw"

if not exist "%_OPENCLAW_DIR%" (
    echo.
    echo ERROR: OpenClaw installation was not found:
    echo %_OPENCLAW_DIR%
    pause
    exit /b 1
)

if not exist "%_OPENCLAW_CMD%" (
    echo.
    echo ERROR: OpenClaw command was not found:
    echo %_OPENCLAW_CMD%
    pause
    exit /b 1
)

echo OpenClaw:
echo %_OPENCLAW_CMD%
echo.

:: ============================================================
:: Enable web tools
:: ============================================================

echo ============================================================
echo        ENABLING OPENCLAW WEB TOOLS
echo ============================================================
echo.

echo Setting OpenClaw tool profile to coding...
echo.

call "%_OPENCLAW_CMD%" config set tools.profile coding

if errorlevel 1 (
    echo.
    echo ERROR: Failed to configure OpenClaw tool profile.
    pause
    exit /b 1
)

:: ============================================================
:: Configure web access
:: ============================================================

echo.
echo ============================================================
echo        CONFIGURING WEB ACCESS
echo ============================================================
echo.

echo Running OpenClaw web configuration...
echo.

call "%_OPENCLAW_CMD%" configure --section web

if errorlevel 1 (
    echo.
    echo ERROR: OpenClaw web configuration failed.
    pause
    exit /b 1
)

:: ============================================================
:: Display resulting configuration
:: ============================================================

echo.
echo ============================================================
echo        OPENCLAW WEB CONFIGURATION COMPLETE
echo ============================================================
echo.

echo Tool profile:
call "%_OPENCLAW_CMD%" config get tools.profile

echo.
echo Allowed tools:
call "%_OPENCLAW_CMD%" config get tools.allow

echo.
echo Denied tools:
call "%_OPENCLAW_CMD%" config get tools.deny

echo.
echo Web configuration:
call "%_OPENCLAW_CMD%" config get web

echo.
echo ============================================================
echo        OPENCLAW CAN NOW USE WEB TOOLS
echo ============================================================
echo.
echo Restart the OpenClaw session/gateway before testing.
echo.
echo Example:
echo.
echo     Ask OpenClaw: "Search the web for today's news about..."
echo.
echo ============================================================
echo.

pause

endlocal
exit /b 0
