:: IsolateEnv-Project.bat

:: NEVER RUN THIS IN A COMMAND PROMPT...it is designed to be called from other .bat files
:: If you need to isolate your Command Prompt manually, then run IsolateEnv-Initialize.bat (which call this script correctly)

@echo off

::Designed to build that state of the project incrementally.
::Make sure to call your DownloadInstall-xxx.bat file in the correct order!

:: ============================================================
:: IsolateEnv-Project.bat
:: ============================================================

:: ============================================================
:: Fundamental Project Definitions
:: ============================================================

SET "_HOST=127.0.0.1"

SET "_LOG_DIR=%SCRIPT_DIR%logs"
if not exist "%_LOG_DIR%" mkdir "%_LOG_DIR%"

goto DATA


::Items are added by IsolateEnv-Project-Add.bat


:DATA
