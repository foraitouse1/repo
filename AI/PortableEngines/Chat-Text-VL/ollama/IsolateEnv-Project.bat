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

::SET "_LOG_DIR=%SCRIPT_DIR%logs"
::if not exist "%_LOG_DIR%" mkdir "%_LOG_DIR%"

goto DATA


::Items are added by IsolateEnv-Project-Add.bat


:DATA

::added by 'DownloadInstall-CACert.bat'
set "SSL_CERT_FILE=%COMMONPROGRAMFILES%\cacert.pem"
ECHO SSL_CERT_FILE=%SSL_CERT_FILE%

::added by 'DownloadInstall-Python.bat'
set "_PYTHON_DIR=%SCRIPT_DIR%Python"
ECHO _PYTHON_DIR=%_PYTHON_DIR%

::added by 'DownloadInstall-Python.bat'
set "PATH=%SCRIPT_DIR%Python;%SCRIPT_DIR%Python\Scripts;%PATH%"
ECHO PATH=%PATH%

::added by 'DownloadInstall-VCRuntime.bat'
set "PATH=%COMMONPROGRAMFILES%VCRuntime;%PATH%"
ECHO PATH=%PATH%

::added by 'DownloadInstall-Nodejs.bat'
set "_NODEJS_DIR=%SCRIPT_DIR%\Nodejs"
ECHO _NODEJS_DIR=%_NODEJS_DIR%

::added by 'DownloadInstall-Nodejs.bat'
set "PATH=%SCRIPT_DIR%Nodejs;%PATH%"
ECHO PATH=%PATH%

::added by 'DownloadInstall-Git.bat'
set "_GIT_DIR=%SCRIPT_DIR%Git"
ECHO _GIT_DIR=%_GIT_DIR%

::added by 'DownloadInstall-Git.bat'
set "PATH=%SCRIPT_DIR%Git\cmd;%PATH%"
ECHO PATH=%PATH%

::added by 'DownloadInstall-Ollama-full.bat'
set "_ENGINE_DIR=%SCRIPT_DIR%Ollama"
ECHO _ENGINE_DIR=%_ENGINE_DIR%

::added by 'DownloadInstall-Ollama-full.bat'
set "OLLAMA_MODELS=%SCRIPT_DIR%Models"
ECHO OLLAMA_MODELS=%OLLAMA_MODELS%

::added by 'DownloadInstall-Ollama-full.bat'
set "PATH=%SCRIPT_DIR%Ollama;%PATH%"
ECHO PATH=%PATH%

::added by 'DownloadInstall-OpenClaw.bat'
set "OPENCLAW_HOME=%SCRIPT_DIR%OpenClaw"
ECHO OPENCLAW_HOME=%OPENCLAW_HOME%

::added by 'DownloadInstall-OpenClaw.bat'
set "PATH=%OPENCLAW_HOME%;%PATH%"
ECHO PATH=%PATH%

::added by 'Run-Engine-Ollama.bat'
set "_OLLAMA_PORT=11434"
ECHO _OLLAMA_PORT=%_OLLAMA_PORT%

set "OPENCLAW_CONFIG_PATH=%USERPROFILE%\.openclaw\openclaw.json"
