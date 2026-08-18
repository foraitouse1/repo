@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ============================================================================
:: DownloadInstall-OpenClaw-Onboard.bat
::
:: COMPLETE PORTABLE OPENCLAW CONFIGURATION
::
:: IMPORTANT
::
::   THIS SCRIPT DOES NOT START OPENCLAW.
::
::   THIS SCRIPT DOES NOT RUN:
::
::       openclaw onboard
::       openclaw configure
::       openclaw gateway
::       openclaw gateway start
::       openclaw gateway install
::
::   The interactive OpenClaw onboarding wizard is intentionally NOT used.
::
::   All requested Manual Setup choices are configured deterministically below.
::
::   Gateway startup is handled separately by:
::
::       Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat
::
:: ============================================================================


:: ============================================================================
:: USER CONFIGURATION
:: ============================================================================

:: ----------------------------------------------------------------------------
:: PRIMARY OLLAMA MODEL
::
:: This must exactly match a model available from:
::
::     http://127.0.0.1:11434/api/tags
::
:: or:
::
::     ollama list
::
:: ----------------------------------------------------------------------------

set "OLLAMA_MODEL=qwen3-coder-next:q8_0"


:: ----------------------------------------------------------------------------
:: OLLAMA EMBEDDING MODEL
:: ----------------------------------------------------------------------------

set "OLLAMA_EMBED_MODEL=nomic-embed-text"


:: ----------------------------------------------------------------------------
:: EMBEDDING DIMENSIONS
::
:: nomic-embed-text = 768 dimensions
:: ----------------------------------------------------------------------------

set "OLLAMA_EMBED_DIMENSIONS=768"


:: ----------------------------------------------------------------------------
:: OPENCLAW GATEWAY
:: ----------------------------------------------------------------------------

set "OPENCLAW_GATEWAY_PORT=18789"


:: ============================================================================
:: INITIALIZE PORTABLE / ISOLATED ENVIRONMENT
:: ============================================================================

echo.
echo ============================================================
echo       INITIALIZING ISOLATED OPENCLAW ENVIRONMENT
echo ============================================================
echo.

call "%~dp0IsolateEnv-Initialize.bat"

if errorlevel 1 (
    echo.
    echo ERROR: Failed initializing isolated environment.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY REQUIRED ISOLATED VARIABLES
:: ============================================================================

if not defined OPENCLAW_HOME (
    echo.
    echo ERROR: OPENCLAW_HOME was not defined.
    echo.
    pause
    exit /b 1
)

if not defined OPENCLAW_CONFIG_PATH (
    echo.
    echo ERROR: OPENCLAW_CONFIG_PATH was not defined.
    echo.
    pause
    exit /b 1
)

if not defined _PYTHON_DIR (
    echo.
    echo ERROR: _PYTHON_DIR was not defined.
    echo.
    pause
    exit /b 1
)

if not defined _GIT_DIR (
    echo.
    echo ERROR: _GIT_DIR was not defined.
    echo.
    pause
    exit /b 1
)

if not defined _ENGINE_DIR (
    echo.
    echo ERROR: _ENGINE_DIR was not defined.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: DERIVED PATHS
:: ============================================================================

set "_OPENCLAW_CMD=%OPENCLAW_HOME%\openclaw.cmd"
set "_OPENCLAW_WORKSPACE=%OPENCLAW_HOME%\workspace"
set "_OPENCLAW_CONFIG_DIR=%~dp0Cdrive\User\.openclaw"
set "_OPENCLAW_ENV_FILE=%_OPENCLAW_CONFIG_DIR%\.env"


:: ============================================================================
:: VERIFY OPENCLAW EXECUTABLE
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OPENCLAW EXECUTABLE
echo ============================================================
echo.

if not exist "%_OPENCLAW_CMD%" (
    echo.
    echo ERROR: OpenClaw executable was not found:
    echo.
    echo   %_OPENCLAW_CMD%
    echo.
    echo Run DownloadInstall-OpenClaw.bat first.
    echo.
    pause
    exit /b 1
)

echo OpenClaw:
echo   %_OPENCLAW_CMD%
echo.


:: ============================================================================
:: VERIFY PORTABLE PYTHON
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING PORTABLE PYTHON
echo ============================================================
echo.

if not exist "%_PYTHON_DIR%\python.exe" (
    echo.
    echo ERROR: Portable Python was not found:
    echo.
    echo   %_PYTHON_DIR%\python.exe
    echo.
    echo Run DownloadInstall-Python.bat first.
    echo.
    pause
    exit /b 1
)

"%_PYTHON_DIR%\python.exe" --version

if errorlevel 1 (
    echo.
    echo ERROR: Portable Python verification failed.
    echo.
    pause
    exit /b 1
)

"%_PYTHON_DIR%\python.exe" -m pip --version

if errorlevel 1 (
    echo.
    echo ERROR: Portable Python pip verification failed.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY PORTABLE GIT
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING PORTABLE GIT
echo ============================================================
echo.

if not exist "%_GIT_DIR%\cmd\git.exe" (
    echo.
    echo ERROR: Portable Git was not found:
    echo.
    echo   %_GIT_DIR%\cmd\git.exe
    echo.
    echo Run DownloadInstall-Git.bat first.
    echo.
    pause
    exit /b 1
)

"%_GIT_DIR%\cmd\git.exe" --version

if errorlevel 1 (
    echo.
    echo ERROR: Portable Git verification failed.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY PORTABLE NODE
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING PORTABLE NODE.JS
echo ============================================================
echo.

if not defined _NODEJS_DIR (
    echo.
    echo ERROR: _NODEJS_DIR was not defined.
    echo.
    echo Run DownloadInstall-Nodejs.bat first.
    echo.
    pause
    exit /b 1
)

if not exist "%_NODEJS_DIR%\node.exe" (
    echo.
    echo ERROR: Portable Node.js was not found:
    echo.
    echo   %_NODEJS_DIR%\node.exe
    echo.
    echo Run DownloadInstall-Nodejs.bat first.
    echo.
    pause
    exit /b 1
)

"%_NODEJS_DIR%\node.exe" --version

if errorlevel 1 (
    echo.
    echo ERROR: Portable Node.js verification failed.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: PREPARE WORKSPACE
:: ============================================================================

echo.
echo ============================================================
echo       PREPARING OPENCLAW WORKSPACE
echo ============================================================
echo.

if not exist "%_OPENCLAW_WORKSPACE%" (
    mkdir "%_OPENCLAW_WORKSPACE%"
)

if not exist "%_OPENCLAW_WORKSPACE%" (
    echo.
    echo ERROR: Unable to create OpenClaw workspace:
    echo.
    echo   %_OPENCLAW_WORKSPACE%
    echo.
    pause
    exit /b 1
)

echo Workspace:
echo   %_OPENCLAW_WORKSPACE%
echo.


:: ============================================================================
:: PREPARE ISOLATED OPENCLAW CONFIGURATION DIRECTORY
:: ============================================================================

echo.
echo ============================================================
echo       PREPARING ISOLATED OPENCLAW CONFIGURATION
echo ============================================================
echo.

if not exist "%_OPENCLAW_CONFIG_DIR%" (
    mkdir "%_OPENCLAW_CONFIG_DIR%"
)

if not exist "%_OPENCLAW_CONFIG_DIR%" (
    echo.
    echo ERROR: Unable to create OpenClaw configuration directory:
    echo.
    echo   %_OPENCLAW_CONFIG_DIR%
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: CREATE PERSISTENT LOCAL OLLAMA AUTH MARKER
::
:: IMPORTANT:
::
:: This is NOT an Internet API key.
::
:: For local Ollama, OpenClaw accepts the ollama-local marker.
::
:: Putting it in the isolated OpenClaw .env means the marker survives
:: after this BAT exits and is available when the separate Gateway launcher
:: initializes the same isolated environment.
::
:: This also preserves Ollama's implicit model discovery.
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING ISOLATED OLLAMA ENVIRONMENT
echo ============================================================
echo.

> "%_OPENCLAW_ENV_FILE%" echo OLLAMA_API_KEY=ollama-local

if errorlevel 1 (
    echo.
    echo ERROR: Unable to create:
    echo.
    echo   %_OPENCLAW_ENV_FILE%
    echo.
    pause
    exit /b 1
)

set "OLLAMA_API_KEY=ollama-local"

echo Ollama local authentication marker:
echo   ollama-local
echo.

echo Isolated OpenClaw environment file:
echo   %_OPENCLAW_ENV_FILE%
echo.


:: ============================================================================
:: CLEAN PORTABLE PATH
::
:: Keep the portable components required by OpenClaw first.
::
:: The Windows system paths remain available for system utilities such as
:: curl.exe, cmd.exe, PowerShell, etc.
::
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING PORTABLE PATH
echo ============================================================
echo.

set "PATH=%OPENCLAW_HOME%;%_ENGINE_DIR%;%_GIT_DIR%\cmd;%_NODEJS_DIR%;%_PYTHON_DIR%;%_PYTHON_DIR%\Scripts%;C:\Windows\system32;C:\Windows;C:\Windows\System32\Wbem;C:\Windows\System32\WindowsPowerShell\v1.0\;C:\Windows\System32\OpenSSH"

echo Portable PATH configured.
echo.


:: ============================================================================
:: CONFIRM ISOLATED OPENCLAW CONFIGURATION
:: ============================================================================

echo.
echo ============================================================
echo       OPENCLAW ISOLATED CONFIGURATION
echo ============================================================
echo.

echo OPENCLAW_HOME=%OPENCLAW_HOME%
echo OPENCLAW_CONFIG_PATH=%OPENCLAW_CONFIG_PATH%
echo.

echo Active OpenClaw configuration file:
echo.

call "%_OPENCLAW_CMD%" config file

echo.
echo Configuration-file inspection complete.
echo.

echo NOTE:
echo Existing OpenClaw configuration is preserved.
echo Configuration warnings are not automatically treated as fatal.
echo.


:: ============================================================================
:: ENSURE A BASE CONFIGURATION EXISTS
::
:: We intentionally do NOT run "openclaw onboard".
::
:: We also do NOT run "openclaw configure".
::
:: ============================================================================

echo.
echo ============================================================
echo       ENSURING OPENCLAW LOCAL MODE
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set gateway.mode local

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring OpenClaw Gateway local mode.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIGURE WORKSPACE
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OPENCLAW WORKSPACE
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set agents.defaults.workspace "%_OPENCLAW_WORKSPACE%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring OpenClaw workspace.
    echo.
    pause
    exit /b 1
)

echo Workspace:
echo   %_OPENCLAW_WORKSPACE%
echo.


:: ============================================================================
:: INITIAL CONFIGURATION VALIDATION
:: ============================================================================

echo.
echo ============================================================
echo       INITIAL CONFIGURATION VALIDATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config validate

if errorlevel 1 (
    echo.
    echo ERROR: Initial OpenClaw configuration validation failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Initial configuration is valid.
echo.


:: ============================================================================
:: CONFIGURE TOOL PROFILE
::
:: The requested setup is equivalent to the coding profile plus browser,
:: Lobster, and Ollama node inference.
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OPENCLAW TOOL ACCESS
echo ============================================================
echo.

echo Filesystem access:   ENABLED
echo Runtime/Exec:        ENABLED
echo Internet/Web:        ENABLED
echo Browser:             ENABLED
echo Python:              ENABLED
echo Git:                 ENABLED
echo Host execution:      ENABLED
echo Sandboxing:          DISABLED
echo.

call "%_OPENCLAW_CMD%" config set tools.profile coding

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring OpenClaw coding tool profile.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set tools.exec.host gateway

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Gateway host execution.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set tools.exec.mode full

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling full host execution.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set agents.defaults.sandbox.mode off

if errorlevel 1 (
    echo.
    echo ERROR: Failed disabling OpenClaw sandbox.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: ALLOW BROWSER / LOBSTER / NODE INFERENCE
:: ============================================================================

call "%_OPENCLAW_CMD%" config set tools.alsoAllow "[\"browser\",\"lobster\",\"node_inference\"]" --strict-json

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring additional OpenClaw tools.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: ENABLE BROWSER
:: ============================================================================

call "%_OPENCLAW_CMD%" config set plugins.entries.browser.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling OpenClaw browser plugin.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set browser.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling OpenClaw browser.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set browser.defaultProfile openclaw

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring OpenClaw browser profile.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: PORTABLE PYTHON + GIT PATH FOR OPENCLAW EXEC
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING PYTHON / GIT EXECUTION PATH
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set tools.exec.pathPrepend "[\"%_PYTHON_DIR%\",\"%_PYTHON_DIR%\\Scripts\",\"%_GIT_DIR%\\cmd\",\"%_NODEJS_DIR%\"]" --strict-json

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring portable execution PATH.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: OPTIONAL: ALIGN HOST APPROVAL POLICY WITH FULL EXEC MODE
::
:: This does NOT start the Gateway.
::
:: It makes the local host policy consistent with tools.exec.mode=full.
:: ============================================================================

echo.
echo ============================================================
echo       ALIGNING HOST EXECUTION POLICY
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" exec-policy preset yolo

if errorlevel 1 (
    echo.
    echo WARNING: OpenClaw exec-policy preset could not be applied.
    echo.
    echo The requested tools.exec.mode=full setting remains configured.
    echo.
)


:: ============================================================================
:: CONFIGURE GATEWAY
::
:: Manual setup equivalent:
::
::   Gateway: Local gateway
::   Port: 18789
::   Bind: Loopback
::   Auth: Token
::   Tailscale: Off
::
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OPENCLAW GATEWAY
echo ============================================================
echo.

echo Gateway mode:
echo   Local
echo.

echo Gateway port:
echo   %OPENCLAW_GATEWAY_PORT%
echo.

echo Gateway bind:
echo   Loopback / 127.0.0.1
echo.

echo Gateway authentication:
echo   Token
echo.

echo Tailscale:
echo   Off
echo.

call "%_OPENCLAW_CMD%" config set gateway.mode local

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Gateway local mode.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set gateway.port %OPENCLAW_GATEWAY_PORT%

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Gateway port.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set gateway.bind loopback

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Gateway loopback binding.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set gateway.auth.mode token

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Gateway token authentication.
    echo.
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set gateway.tailscale.mode off

if errorlevel 1 (
    echo.
    echo ERROR: Failed disabling Tailscale Gateway exposure.
    echo.
    pause
    exit /b 1
)

:: Make sure an existing password cannot conflict with token mode.

call "%_OPENCLAW_CMD%" config unset gateway.auth.password


:: ============================================================================
:: GENERATE / STORE GATEWAY TOKEN
::
:: Equivalent to:
::
::   Generate/store plaintext token
::   Gateway token field left blank
::
:: OpenClaw's supported deterministic mechanism is:
::
::   openclaw doctor --generate-gateway-token
::
:: This writes a persistent gateway.auth.token.
::
:: ============================================================================

echo.
echo ============================================================
echo       GENERATING / STORING GATEWAY TOKEN
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" doctor --generate-gateway-token

if errorlevel 1 (
    echo.
    echo ERROR: Failed generating/storing Gateway token.
    echo.
    pause
    exit /b 1
)

echo.
echo Gateway token generation completed.
echo.
echo The token is stored in the isolated OpenClaw configuration.
echo.


:: ============================================================================
:: CONFIGURE OLLAMA
::
:: Manual setup equivalent:
::
::   Provider: Ollama
::   Auth: Ollama
::   Mode: Cloud + Local
::   Base URL: http://127.0.0.1:11434
::
:: IMPORTANT:
::
:: We deliberately DO NOT create an explicit models.providers.ollama model
:: catalog here. That preserves OpenClaw's implicit /api/tags discovery.
::
:: The local ollama-local credential marker is supplied through the isolated
:: OpenClaw .env file.
::
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OLLAMA
echo ============================================================
echo.

echo Ollama mode:
echo   Cloud + Local
echo.

echo Ollama base URL:
echo   http://127.0.0.1:11434
echo.

echo Ollama authentication:
echo   ollama-local
echo.

echo Primary model:
echo   ollama/%OLLAMA_MODEL%
echo.

:: Primary model.

call "%_OPENCLAW_CMD%" config set agents.defaults.model.primary "ollama/%OLLAMA_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed selecting Ollama primary model.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY OLLAMA SERVER
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA SERVER
echo ============================================================
echo.

curl.exe --silent --show-error --fail ^
    "http://127.0.0.1:11434/api/tags" > "%TEMP%\openclaw-ollama-tags.json"

if errorlevel 1 (
    echo.
    echo ERROR: Ollama is not responding at:
    echo.
    echo   http://127.0.0.1:11434
    echo.
    echo Make sure Ollama is running.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo Ollama /api/tags responded successfully.
echo.


:: ============================================================================
:: DISPLAY OLLAMA MODEL CATALOG
:: ============================================================================

echo.
echo ============================================================
echo       OLLAMA MODEL DISCOVERY
echo ============================================================
echo.

type "%TEMP%\openclaw-ollama-tags.json"

echo.
echo.

echo Selected primary model:
echo   %OLLAMA_MODEL%
echo.


:: ============================================================================
:: VERIFY PRIMARY OLLAMA MODEL
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING PRIMARY OLLAMA MODEL
echo ============================================================
echo.

ollama show "%OLLAMA_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: The configured Ollama model was not found:
    echo.
    echo   %OLLAMA_MODEL%
    echo.
    echo Install it with:
    echo.
    echo   ollama pull %OLLAMA_MODEL%
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: ENABLE OLLAMA PLUGIN
:: ============================================================================

echo.
echo ============================================================
echo       ENABLING OLLAMA PLUGIN
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.ollama.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Ollama plugin.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: ENABLE OLLAMA MODEL DISCOVERY / NODE INFERENCE
::
:: Ollama's current provider performs implicit /api/tags discovery when the
:: local auth marker is present.
::
:: Node inference is explicitly enabled because this is a separate plugin
:: capability.
:: ============================================================================

call "%_OPENCLAW_CMD%" config set plugins.entries.ollama.config.nodeInference.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Ollama node inference.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: ENABLE GOOGLE
:: ============================================================================

echo.
echo ============================================================
echo       ENABLING GOOGLE PLUGIN
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.google.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Google plugin.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: GOOGLE / GEMINI SEARCH CONFIGURATION
::
:: Requested:
::
::   Gemini Search Model: gemini-2.5-flash
::   Gemini Search Base URL: blank
::
:: NOTE:
::
:: DuckDuckGo remains the actual active web_search provider below.
:: These values configure Google's plugin-owned Gemini search settings
:: without selecting Gemini as the active web-search provider.
:: ============================================================================

call "%_OPENCLAW_CMD%" config set plugins.entries.google.config.webSearch.model gemini-2.5-flash

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Gemini search model.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config unset plugins.entries.google.config.webSearch.baseUrl


:: ============================================================================
:: ENABLE HUGGING FACE
:: ============================================================================

echo.
echo ============================================================
echo       ENABLING HUGGING FACE PLUGIN
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.huggingface.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Hugging Face plugin.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: INSTALL OPTIONAL PLUGINS
::
:: Requested by the Manual Setup:
::
::   Diff Viewer Language Packs
::   Diffs
::   llama.cpp Provider
::   Lobster
::   Memory LanceDB
::   PixVerse
::
:: Plugin installation errors caused solely by an already-installed plugin
:: are tolerated. The later inspection/validation stages determine whether
:: the requested plugin is actually available.
:: ============================================================================

echo.
echo ============================================================
echo       INSTALLING OPTIONAL OPENCLAW PLUGINS
echo ============================================================
echo.

echo.
echo [1/6] Memory LanceDB
echo.
call "%_OPENCLAW_CMD%" plugins install @openclaw/memory-lancedb
if errorlevel 1 (
    echo NOTE: Memory LanceDB install returned a non-zero status.
    echo It may already be installed.
)

echo.
echo [2/6] Diffs
echo.
call "%_OPENCLAW_CMD%" plugins install diffs
if errorlevel 1 (
    echo NOTE: Diffs install returned a non-zero status.
    echo It may already be installed.
)

echo.
echo [3/6] Diff Viewer Language Pack
echo.
call "%_OPENCLAW_CMD%" plugins install clawhub:@openclaw/diffs-language-pack
if errorlevel 1 (
    echo NOTE: Diff Viewer Language Pack install returned a non-zero status.
    echo It may already be installed.
)

echo.
echo [4/6] llama.cpp Provider
echo.
call "%_OPENCLAW_CMD%" plugins install @openclaw/llama-cpp-provider
if errorlevel 1 (
    echo NOTE: llama.cpp Provider install returned a non-zero status.
    echo It may already be installed.
)

echo.
echo [5/6] Lobster
echo.
call "%_OPENCLAW_CMD%" plugins install @openclaw/lobster
if errorlevel 1 (
    echo NOTE: Lobster install returned a non-zero status.
    echo It may already be installed.
)

echo.
echo [6/6] PixVerse
echo.
call "%_OPENCLAW_CMD%" plugins install @openclaw/pixverse-provider
if errorlevel 1 (
    echo NOTE: PixVerse install returned a non-zero status.
    echo It may already be installed.
)


:: ============================================================================
:: DUCKDUCKGO PLUGIN
::
:: Current OpenClaw requires the DuckDuckGo plugin for this provider.
:: ============================================================================

echo.
echo ============================================================
echo       INSTALLING DUCKDUCKGO PLUGIN
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" plugins install @openclaw/duckduckgo-plugin

if errorlevel 1 (
    echo NOTE: DuckDuckGo install returned a non-zero status.
    echo It may already be installed.
)


:: ============================================================================
:: ENABLE REQUESTED PLUGINS
:: ============================================================================

echo.
echo ============================================================
echo       ENABLING REQUESTED PLUGINS
echo ============================================================
echo.

echo Google:
call "%_OPENCLAW_CMD%" plugins enable google
if errorlevel 1 echo WARNING: Could not explicitly enable google.

echo Hugging Face:
call "%_OPENCLAW_CMD%" plugins enable huggingface
if errorlevel 1 echo WARNING: Could not explicitly enable huggingface.

echo Ollama:
call "%_OPENCLAW_CMD%" plugins enable ollama
if errorlevel 1 echo WARNING: Could not explicitly enable ollama.

echo DuckDuckGo:
call "%_OPENCLAW_CMD%" plugins enable duckduckgo
if errorlevel 1 echo WARNING: Could not explicitly enable duckduckgo.

echo Diffs:
call "%_OPENCLAW_CMD%" plugins enable diffs
if errorlevel 1 echo WARNING: Could not explicitly enable diffs.

echo Diff Viewer Language Pack:
call "%_OPENCLAW_CMD%" plugins enable diffs-language-pack
if errorlevel 1 echo WARNING: Could not explicitly enable diffs-language-pack.

echo llama.cpp:
call "%_OPENCLAW_CMD%" plugins enable llama-cpp
if errorlevel 1 echo WARNING: Could not explicitly enable llama-cpp.

echo Lobster:
call "%_OPENCLAW_CMD%" plugins enable lobster
if errorlevel 1 echo WARNING: Could not explicitly enable lobster.

echo PixVerse:
call "%_OPENCLAW_CMD%" plugins enable pixverse
if errorlevel 1 echo WARNING: Could not explicitly enable pixverse.

echo Memory LanceDB:
call "%_OPENCLAW_CMD%" plugins enable memory-lancedb
if errorlevel 1 echo WARNING: Could not explicitly enable memory-lancedb.


:: ============================================================================
:: CONFIGURE LOBSTER
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING LOBSTER
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.lobster.enabled true

if errorlevel 1 (
    echo WARNING: Lobster configuration entry could not be explicitly set.
)


:: ============================================================================
:: CONFIGURE MEMORY LANCEDB
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING MEMORY LANCEDB
echo ============================================================
echo.

:: Active memory slot.

call "%_OPENCLAW_CMD%" config set plugins.slots.memory memory-lancedb

if errorlevel 1 (
    echo.
    echo ERROR: Failed selecting memory-lancedb.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Enable plugin.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling memory-lancedb.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Embedding provider.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.embedding.provider ollama

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Ollama as Memory LanceDB embedding provider.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Embedding model.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.embedding.model "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Memory LanceDB embedding model.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Embedding dimensions.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.embedding.dimensions %OLLAMA_EMBED_DIMENSIONS%

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Memory LanceDB embedding dimensions.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Automatic capture.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.autoCapture true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Memory LanceDB Auto-Capture.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Automatic recall.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.autoRecall true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Memory LanceDB Auto-Recall.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Conversation access for agent_end hook.

call "%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.hooks.allowConversationAccess true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Memory LanceDB conversation access.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: Dreaming intentionally left unset, exactly as requested.


:: ============================================================================
:: INSTALL / VERIFY NOMIC-EMBED-TEXT
:: ============================================================================

echo.
echo ============================================================
echo       INSTALLING / VERIFYING NOMIC-EMBED-TEXT
echo ============================================================
echo.

echo Embedding model:
echo   %OLLAMA_EMBED_MODEL%
echo.

ollama pull "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed installing:
    echo.
    echo   %OLLAMA_EMBED_MODEL%
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY EMBEDDING MODEL
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING EMBEDDING MODEL
echo ============================================================
echo.

ollama show "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Ollama embedding model verification failed.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY OLLAMA MODEL LIST
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA MODEL LIST
echo ============================================================
echo.

ollama list

if errorlevel 1 (
    echo.
    echo ERROR: Ollama model listing failed.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: TEST OLLAMA EMBEDDING API
:: ============================================================================

echo.
echo ============================================================
echo       TESTING OLLAMA EMBEDDING API
echo ============================================================
echo.

curl.exe --silent --show-error --fail ^
    "http://127.0.0.1:11434/api/embed" ^
    -H "Content-Type: application/json" ^
    -d "{\"model\":\"%OLLAMA_EMBED_MODEL%\",\"input\":\"hello\"}"

if errorlevel 1 (
    echo.
    echo ERROR: Ollama embedding API test failed.
    echo.
    echo Model:
    echo   %OLLAMA_EMBED_MODEL%
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo.
echo Ollama embedding API test PASSED.
echo.


:: ============================================================================
:: CONFIGURE DUCKDUCKGO WEB SEARCH
::
:: Requested:
::
::   Search provider: DuckDuckGo
::   Region: us-en
::   SafeSearch: off
::   Web fetch: enabled
::
:: No API key.
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING DUCKDUCKGO WEB SEARCH
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set tools.web.search.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling web search.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set tools.web.search.provider duckduckgo

if errorlevel 1 (
    echo.
    echo ERROR: Failed selecting DuckDuckGo.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set tools.web.fetch.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling web fetch.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: DuckDuckGo plugin settings.

call "%_OPENCLAW_CMD%" config set plugins.entries.duckduckgo.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling DuckDuckGo plugin.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set plugins.entries.duckduckgo.config.webSearch.region us-en

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring DuckDuckGo region.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set plugins.entries.duckduckgo.config.webSearch.safeSearch off

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring DuckDuckGo SafeSearch.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIGURE DIFFS
::
:: Requested:
::
::   Viewer Base URL: blank
::   Default Font: blank
::   Default Font Size: blank
::   Line Spacing: blank
::   Default Layout: split
::   Show line numbers: yes
::   Diff indicator style: bars
::   Default word wrap: no
::   Default background highlights: yes
::
:: Remaining settings: sensible values.
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING DIFFS
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.enabled true

if errorlevel 1 (
    echo.
    echo ERROR: Failed enabling Diffs.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

:: Viewer Base URL intentionally blank.

call "%_OPENCLAW_CMD%" config unset plugins.entries.diffs.config.viewerBaseUrl

:: Default font intentionally blank.

call "%_OPENCLAW_CMD%" config unset plugins.entries.diffs.config.defaults.fontFamily

:: Default font size intentionally blank.

call "%_OPENCLAW_CMD%" config unset plugins.entries.diffs.config.defaults.fontSize

:: Line spacing intentionally blank.

call "%_OPENCLAW_CMD%" config unset plugins.entries.diffs.config.defaults.lineSpacing

:: Requested settings.

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.layout split

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Diffs layout.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.showLineNumbers true

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Diffs line numbers.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.diffIndicators bars

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Diffs indicator style.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.wordWrap false

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Diffs word wrap.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.background true

if errorlevel 1 (
    echo.
    echo ERROR: Failed configuring Diffs background highlights.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

:: Sensible remaining Diffs defaults.

call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.theme dark
call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.fileFormat png
call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.fileQuality standard
call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.fileScale 2
call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.fileMaxWidth 960
call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.mode both
call "%_OPENCLAW_CMD%" config set plugins.entries.diffs.config.defaults.ttlSeconds 21600


:: ============================================================================
:: LLM TASK / LOBSTER TOOL SUPPORT
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OPTIONAL WORKFLOW TOOLS
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.llm-task.enabled true

if errorlevel 1 (
    echo WARNING: Could not enable llm-task.
)

:: Preserve requested Lobster access.

call "%_OPENCLAW_CMD%" config set plugins.entries.lobster.enabled true

if errorlevel 1 (
    echo WARNING: Could not explicitly enable Lobster.
)


:: ============================================================================
:: PIXVERSE
::
:: Enable because it was selected in Optional Plugins.
::
:: The existing PixVerse providerAuthEnvVars warning is intentionally NOT
:: treated as fatal.
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING PIXVERSE
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.pixverse.enabled true

if errorlevel 1 (
    echo WARNING: PixVerse could not be explicitly enabled.
    echo Existing PixVerse configuration will be preserved.
)


:: ============================================================================
:: HUGGING FACE MODEL DISCOVERY
::
:: The current Hugging Face provider performs provider-owned discovery.
:: No model ID is forced here, matching the requested blank discovery field.
::
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING HUGGING FACE DISCOVERY
echo ============================================================
echo.

echo Hugging Face model discovery:
echo   ENABLED / provider-owned
echo.
echo No discovery model override configured.
echo.


:: ============================================================================
:: OLLAMA MODEL DISCOVERY
::
:: Current OpenClaw's local Ollama provider discovers models through:
::
::   http://127.0.0.1:11434/api/tags
::
:: We deliberately leave the provider catalog implicit.
::
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OLLAMA MODEL DISCOVERY
echo ============================================================
echo.

echo Ollama model discovery:
echo   ENABLED / implicit provider discovery
echo.
echo Discovery source:
echo   http://127.0.0.1:11434/api/tags
echo.
echo No manual model catalog is being written.
echo.


:: ============================================================================
:: NODE INFERENCE
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING NODE INFERENCE
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config set plugins.entries.ollama.config.nodeInference.enabled true

if errorlevel 1 (
    echo WARNING: Node inference could not be explicitly enabled.
)


:: ============================================================================
:: VERIFY COMPLETE MEMORY LANCEDB CONFIGURATION
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING MEMORY LANCEDB CONFIGURATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config get plugins.entries.memory-lancedb --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to read Memory LanceDB configuration.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo.


:: ============================================================================
:: VERIFY ACTIVE MEMORY SLOT
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING ACTIVE MEMORY SLOT
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config get plugins.slots --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to read OpenClaw memory slots.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY WEB CONFIGURATION
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING WEB CONFIGURATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config get tools.web --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to read OpenClaw web configuration.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY OLLAMA MODEL CONFIGURATION
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA MODEL CONFIGURATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config get agents.defaults.model --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to read OpenClaw model configuration.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY GATEWAY CONFIGURATION
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING GATEWAY CONFIGURATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config get gateway --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to read Gateway configuration.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY PLUGIN INVENTORY
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OPENCLAW PLUGIN INVENTORY
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" plugins list --enabled --verbose

if errorlevel 1 (
    echo.
    echo WARNING: Plugin inventory returned a non-zero status.
    echo.
)


:: ============================================================================
:: CONFIGURATION VALIDATION
:: ============================================================================

echo.
echo ============================================================
echo       VALIDATING OPENCLAW CONFIGURATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config validate

if errorlevel 1 (
    echo.
    echo ========================================================
    echo       OPENCLAW CONFIGURATION VALIDATION FAILED
    echo ========================================================
    echo.
    echo Review the validation output above.
    echo.
    echo NOTE:
    echo A PixVerse deprecation warning by itself is NOT fatal.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo OpenClaw configuration validation PASSED.
echo.


:: ============================================================================
:: INSPECT MEMORY LANCEDB
:: ============================================================================

echo.
echo ============================================================
echo       INSPECTING MEMORY LANCEDB
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" plugins inspect memory-lancedb

if errorlevel 1 (
    echo.
    echo ERROR: Memory LanceDB inspection failed.
    echo.
    echo This normally means the plugin is missing, damaged, or its
    echo dependencies could not be resolved.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo Detailed Memory LanceDB information:
echo.

call "%_OPENCLAW_CMD%" plugins inspect memory-lancedb --json

if errorlevel 1 (
    echo.
    echo ERROR: Detailed Memory LanceDB inspection failed.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIRM MEMORY SLOT OWNERSHIP
:: ============================================================================

echo.
echo ============================================================
echo       CONFIRMING MEMORY SLOT OWNERSHIP
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config get plugins.slots --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to confirm memory slot ownership.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY EMBEDDING CONFIGURATION
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING EMBEDDING CONFIGURATION
echo ============================================================
echo.

echo Provider:
echo   %OLLAMA_EMBED_MODEL%
echo.

echo Dimensions:
echo   %OLLAMA_EMBED_DIMENSIONS%
echo.

call "%_OPENCLAW_CMD%" config get plugins.entries.memory-lancedb.config.embedding --json

if errorlevel 1 (
    echo.
    echo ERROR: Unable to verify embedding configuration.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: OPENCLAW DOCTOR
::
:: IMPORTANT:
::
:: "doctor" does NOT start the Gateway.
::
:: It performs diagnostic/configuration checks.
::
:: ============================================================================

echo.
echo ============================================================
echo       RUNNING OPENCLAW DOCTOR
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" doctor

if errorlevel 1 (
    echo.
    echo ========================================================
    echo       OPENCLAW DOCTOR REPORTED A FAILURE
    echo ========================================================
    echo.
    echo Review the diagnostic output above.
    echo.
    echo The Gateway was NOT started by this script.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: FINAL CONFIGURATION VALIDATION
:: ============================================================================

echo.
echo ============================================================
echo       FINAL CONFIGURATION VALIDATION
echo ============================================================
echo.

call "%_OPENCLAW_CMD%" config validate

if errorlevel 1 (
    echo.
    echo ========================================================
    echo       FINAL OPENCLAW VALIDATION FAILED
    echo ========================================================
    echo.
    echo Review the validation output above.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo Final OpenClaw configuration validation PASSED.
echo.


:: ============================================================================
:: FINAL OLLAMA VERIFICATION
:: ============================================================================

echo.
echo ============================================================
echo       FINAL OLLAMA VERIFICATION
echo ============================================================
echo.

echo Primary model:
echo   %OLLAMA_MODEL%
echo.

ollama show "%OLLAMA_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Final primary model verification failed.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)

echo.
echo Embedding model:
echo   %OLLAMA_EMBED_MODEL%
echo.

ollama show "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Final embedding model verification failed.
    echo.
    del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1
    pause
    exit /b 1
)


:: ============================================================================
:: CLEAN TEMP FILE
:: ============================================================================

del /q "%TEMP%\openclaw-ollama-tags.json" >nul 2>&1


:: ============================================================================
:: FINAL SUMMARY
:: ============================================================================

echo.
echo.
echo ============================================================
echo       OPENCLAW PORTABLE CONFIGURATION COMPLETE
echo ============================================================
echo.

echo OpenClaw:
echo   %_OPENCLAW_CMD%
echo.

echo Isolated HOME:
echo   %OPENCLAW_HOME%
echo.

echo Isolated CONFIG:
echo   %OPENCLAW_CONFIG_PATH%
echo.

echo Workspace:
echo   %_OPENCLAW_WORKSPACE%
echo.

echo ------------------------------------------------------------
echo OLLAMA
echo ------------------------------------------------------------
echo.

echo Mode:
echo   Cloud + Local
echo.

echo Base URL:
echo   http://127.0.0.1:11434
echo.

echo Primary model:
echo   ollama/%OLLAMA_MODEL%
echo.

echo Embedding model:
echo   %OLLAMA_EMBED_MODEL%
echo.

echo Embedding dimensions:
echo   %OLLAMA_EMBED_DIMENSIONS%
echo.

echo Ollama model discovery:
echo   ENABLED
echo.

echo Ollama node inference:
echo   ENABLED
echo.

echo ------------------------------------------------------------
echo MEMORY
echo ------------------------------------------------------------
echo.

echo Provider:
echo   Memory LanceDB
echo.

echo Active memory slot:
echo   memory-lancedb
echo.

echo Auto-Capture:
echo   ENABLED
echo.

echo Auto-Recall:
echo   ENABLED
echo.

echo Conversation access:
echo   ENABLED
echo.

echo ------------------------------------------------------------
echo WEB
echo ------------------------------------------------------------
echo.

echo Web search:
echo   ENABLED
echo.

echo Search provider:
echo   DuckDuckGo
echo.

echo Region:
echo   us-en
echo.

echo SafeSearch:
echo   OFF
echo.

echo Web fetch:
echo   ENABLED
echo.

echo ------------------------------------------------------------
echo PLUGINS
echo ------------------------------------------------------------
echo.

echo Google:
echo   ENABLED
echo.

echo Hugging Face:
echo   ENABLED
echo.

echo Ollama:
echo   ENABLED
echo.

echo DuckDuckGo:
echo   ENABLED
echo.

echo Memory LanceDB:
echo   ENABLED
echo.

echo Diffs:
echo   ENABLED
echo.

echo Diff Viewer Language Pack:
echo   ENABLED
echo.

echo llama.cpp Provider:
echo   ENABLED
echo.

echo Lobster:
echo   ENABLED
echo.

echo PixVerse:
echo   ENABLED
echo.

echo ------------------------------------------------------------
echo DIFFS
echo ------------------------------------------------------------
echo.

echo Layout:
echo   split
echo.

echo Line numbers:
echo   ENABLED
echo.

echo Indicators:
echo   bars
echo.

echo Word wrap:
echo   DISABLED
echo.

echo Background highlights:
echo   ENABLED
echo.

echo ------------------------------------------------------------
echo GATEWAY
echo ------------------------------------------------------------
echo.

echo Mode:
echo   LOCAL
echo.

echo Port:
echo   %OPENCLAW_GATEWAY_PORT%
echo.

echo Bind:
echo   LOOPBACK / 127.0.0.1
echo.

echo Authentication:
echo   TOKEN
echo.

echo Token:
echo   GENERATED / STORED
echo.

echo Tailscale exposure:
echo   OFF
echo.

echo Gateway service:
echo   NOT INSTALLED
echo.

echo ------------------------------------------------------------
echo TOOLS
echo ------------------------------------------------------------
echo.

echo Filesystem:
echo   ENABLED
echo.

echo Internet:
echo   ENABLED
echo.

echo Browser:
echo   ENABLED
echo.

echo Python:
echo   ENABLED
echo.

echo Git:
echo   ENABLED
echo.

echo Node.js:
echo   ENABLED
echo.

echo Host execution:
echo   ENABLED
echo.

echo Sandbox:
echo   DISABLED
echo.

echo ------------------------------------------------------------
echo ONBOARDING
echo ------------------------------------------------------------
echo.

echo Interactive "openclaw onboard":
echo   NOT RUN
echo.

echo Interactive "openclaw configure":
echo   NOT RUN
echo.

echo Chat channel:
echo   NOT CONFIGURED
echo.

echo zsh:
echo   NOT ENABLED
echo.

echo ------------------------------------------------------------
echo GATEWAY STARTUP
echo ------------------------------------------------------------
echo.

echo GATEWAY WAS NOT STARTED.
echo.

echo This script only installs/configures/validates OpenClaw.
echo.

echo Start OpenClaw separately with:
echo.
echo   Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat
echo.

echo ============================================================
echo       OPENCLAW ONBOARDING FINISHED SUCCESSFULLY
echo ============================================================
echo.

pause

endlocal
exit /b 0