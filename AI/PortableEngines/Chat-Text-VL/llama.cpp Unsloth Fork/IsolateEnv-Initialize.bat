::IsolateEnv-Initialize.bat
:: This should be called by all scripts...centralized here so it is not repeated everywhere

@echo off

if not exist "%~dp0IsolateEnv.bat" (
echo ERROR: IsolateEnv.bat missing
pause
exit /b 1
)

if not exist "%~dp0IsolateEnv-Project.bat" (
echo ERROR: IsolateEnv-Project.bat missing
pause
exit /b 1
)

call "%~dp0IsolateEnv.bat"

if not defined SCRIPT_DIR (
echo ERROR: IsolateEnv.bat failed to define SCRIPT_DIR
pause
exit /b 1
)

call "%~dp0IsolateEnv-Project.bat"

if not defined _LOG_DIR (
echo ERROR: IsolateEnv-Project.bat failed to define _LOG_DIR
pause
exit /b 1
)


exit /b 0

