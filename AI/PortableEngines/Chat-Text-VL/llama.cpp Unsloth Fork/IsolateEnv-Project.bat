@echo off

:: ============================================================
:: IsolateEnv-Project.bat
:: ============================================================

call "%~dp0IsolateEnv.bat"

if not defined SCRIPT_DIR (
    echo ERROR: IsolateEnv.bat failed
    exit /b 1
)

:: ============================================================
:: Fundamental Project Definitions
:: ============================================================

SET "_HOST=127.0.0.1"

SET "_LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%_LOG_DIR%" mkdir "%_LOG_DIR%"

goto DATA


::Items are added in alpha sort order by IsolateEnv-Project-Add.bat


:DATA

