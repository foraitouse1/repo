@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ============================================================================
:: DownloadInstall-OpenClaw-Onboard.bat
::
:: COMPLETE PORTABLE OPENCLAW ONBOARDING / CONFIGURATION
::
:: IMPORTANT:
::
::   This script CONFIGURES and VALIDATES OpenClaw.
::
::   It DOES NOT start the OpenClaw Gateway.
::
::   Gateway startup is handled by:
::
::   Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat
::
:: ============================================================================
::
:: This script:
::
::   - Initializes the isolated OpenClaw environment
::   - Verifies isolated paths
::   - Verifies portable Python
::   - Verifies portable Git
::   - Runs OpenClaw onboarding
::   - Configures portable tool access
::   - Enables host execution
::   - Disables sandboxing
::   - Configures the OpenClaw workspace
::   - Configures Ollama
::   - Selects the Ollama primary model
::   - Verifies the Ollama model
::   - Enables Google
::   - Enables Hugging Face
::   - Selects Memory LanceDB
::   - Enables Memory LanceDB
::   - Configures Ollama embeddings
::   - Configures embedding dimensions
::   - Enables automatic memory capture
::   - Enables automatic memory recall
::   - Allows conversation access for memory hooks
::   - Installs/verifies nomic-embed-text
::   - Tests Ollama's embedding API
::   - Configures DuckDuckGo web search
::   - Enables web fetch
::   - Validates configuration
::   - Inspects Memory LanceDB
::   - Confirms memory slot ownership
::   - Runs OpenClaw doctor
::   - Performs final validation
::
:: It DOES NOT:
::
::   - Start the OpenClaw Gateway
::   - Install a Windows Gateway service
::   - Run "ollama signin"
::   - Reset OpenClaw configuration
::
:: ============================================================================


:: ============================================================================
:: USER CONFIGURATION
:: ============================================================================

:: ----------------------------------------------------------------------------
:: OLLAMA CHAT / CODING MODEL
::
:: CHANGE ONLY THIS VARIABLE when you want to change the primary Ollama model.
::
:: The value must match a model shown by:
::
::   ollama list
::
:: Examples:
::
::   set "OLLAMA_MODEL=qwen3-coder-next:q8_0"
::   set "OLLAMA_MODEL=qwen3.5:0.8b-bf16"
::   set "OLLAMA_MODEL=gemma4"
::
:: ----------------------------------------------------------------------------

set "OLLAMA_MODEL=qwen3-coder-next:q8_0"


:: ----------------------------------------------------------------------------
:: OLLAMA EMBEDDING MODEL
::
:: This is separate from the primary chat/coding model.
:: ----------------------------------------------------------------------------

set "OLLAMA_EMBED_MODEL=nomic-embed-text"


:: ----------------------------------------------------------------------------
:: EMBEDDING DIMENSIONS
::
:: nomic-embed-text produces 768-dimensional vectors.
:: ----------------------------------------------------------------------------

set "OLLAMA_EMBED_DIMENSIONS=768"


:: ============================================================================
:: INITIALIZE ISOLATED ENVIRONMENT
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

set "_OPENCLAW_CMD=%OPENCLAW_HOME%\openclaw.cmd"
set "_OPENCLAW_WORKSPACE=%OPENCLAW_HOME%\workspace"


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

if not defined _PYTHON_DIR (
    echo ERROR: _PYTHON_DIR was not defined.
    echo.
    echo Run DownloadInstall-Python.bat first.
    echo.
    pause
    exit /b 1
)

if not exist "%_PYTHON_DIR%\python.exe" (
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

if not defined _GIT_DIR (
    echo ERROR: _GIT_DIR was not defined.
    echo.
    echo Run DownloadInstall-Git.bat first.
    echo.
    pause
    exit /b 1
)

if not exist "%_GIT_DIR%\cmd\git.exe" (
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
:: CREATE WORKSPACE
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
:: CONFIRM ISOLATED OPENCLAW CONFIGURATION
:: ============================================================================
::
:: IMPORTANT:
::
:: "openclaw config file" is INFORMATIONAL.
::
:: OpenClaw may emit configuration WARNINGS while still successfully
:: displaying the active configuration file.
::
:: Therefore we intentionally DO NOT treat its ERRORLEVEL as fatal here.
::
:: This fixes the exact problem shown in your latest run.
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

"%_OPENCLAW_CMD%" config file

echo.
echo Configuration-file inspection complete.
echo.
echo NOTE:
echo Configuration warnings are not automatically treated as fatal.
echo.


:: ============================================================================
:: OPENCLAW ONBOARDING
:: ============================================================================

echo.
echo ============================================================
echo       OPENCLAW ONBOARDING
echo ============================================================
echo.
echo Existing configuration will be preserved.
echo No reset will be performed.
echo No Gateway will be started by this script.
echo No Windows Gateway service will be installed.
echo.
echo Primary Ollama model:
echo   %OLLAMA_MODEL%
echo.

"%_OPENCLAW_CMD%" onboard --classic

if errorlevel 1 (
    echo.
    echo ========================================================
    echo       OPENCLAW ONBOARDING FAILED
    echo ========================================================
    echo.
    echo Review the onboarding output above.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: INITIAL CONFIGURATION VALIDATION
:: ============================================================================

echo.
echo ============================================================
echo       INITIAL CONFIGURATION VALIDATION
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config validate

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
:: SHOW CURRENT PLUGIN CONFIGURATION
:: ============================================================================
::
:: INFORMATIONAL ONLY.
::
:: A warning here must not abort the installation.
:: ============================================================================

echo.
echo ============================================================
echo       CURRENT PLUGIN CONFIGURATION
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config get plugins

echo.
echo Plugin configuration inspection complete.
echo.


:: ============================================================================
:: CONFIGURE PORTABLE TOOL ACCESS
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OPENCLAW TOOL ACCESS
echo ============================================================
echo.
echo Filesystem access:   ENABLED
echo Internet access:     ENABLED
echo Browser access:      ENABLED
echo Python access:       ENABLED
echo Git access:          ENABLED
echo Python packages:     ENABLED
echo Host execution:      ENABLED
echo Sandboxing:          DISABLED
echo.

"%_OPENCLAW_CMD%" config set tools.profile coding

if errorlevel 1 (
    echo ERROR: Failed configuring OpenClaw tool profile.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set tools.alsoAllow "browser"

if errorlevel 1 (
    echo ERROR: Failed enabling browser tool.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set browser.enabled true

if errorlevel 1 (
    echo ERROR: Failed enabling OpenClaw browser.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set browser.defaultProfile openclaw

if errorlevel 1 (
    echo ERROR: Failed configuring OpenClaw browser profile.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set tools.exec.host gateway

if errorlevel 1 (
    echo ERROR: Failed configuring OpenClaw exec host.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set tools.exec.mode full

if errorlevel 1 (
    echo ERROR: Failed enabling full OpenClaw host execution.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set tools.exec.pathPrepend "[\"%_PYTHON_DIR%\",\"%_PYTHON_DIR%\\Scripts\",\"%_GIT_DIR%\\cmd\"]"

if errorlevel 1 (
    echo ERROR: Failed configuring Python and Git PATH.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set agents.defaults.sandbox.mode off

if errorlevel 1 (
    echo ERROR: Failed disabling OpenClaw sandbox.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set agents.defaults.workspace "%_OPENCLAW_WORKSPACE%"

if errorlevel 1 (
    echo ERROR: Failed configuring OpenClaw workspace.
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIGURE OLLAMA
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING OLLAMA
echo ============================================================
echo.

echo Ollama provider: ENABLED
echo Primary model:
echo   ollama/%OLLAMA_MODEL%
echo.

:: Local Ollama authentication marker.
::
:: For a local Ollama server this is simply a non-empty credential marker.
:: It is NOT an Internet API key.

set "OLLAMA_API_KEY=ollama-local"

"%_OPENCLAW_CMD%" config set models.providers.ollama.apiKey "ollama-local"

if errorlevel 1 (
    echo ERROR: Failed configuring Ollama provider.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set agents.defaults.model.primary "ollama/%OLLAMA_MODEL%"

if errorlevel 1 (
    echo ERROR: Failed selecting Ollama primary model.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY OLLAMA SERVER
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA
echo ============================================================
echo.

ollama list

if errorlevel 1 (
    echo.
    echo ERROR: Ollama is not responding.
    echo.
    echo Make sure Ollama is running before continuing.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY PRIMARY OLLAMA MODEL
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA PRIMARY MODEL
echo ============================================================
echo.

echo Selected model:
echo   %OLLAMA_MODEL%
echo.

ollama show "%OLLAMA_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: The configured Ollama model was not found:
    echo.
    echo   %OLLAMA_MODEL%
    echo.
    echo Models currently installed:
    echo.
    ollama list
    echo.
    echo If necessary, install the model with:
    echo.
    echo   ollama pull %OLLAMA_MODEL%
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIGURE GOOGLE
:: ============================================================================

echo.
echo ============================================================
echo       ENABLING GOOGLE PLUGIN
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config set plugins.entries.google.enabled true

if errorlevel 1 (
    echo ERROR: Failed enabling Google plugin.
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIGURE HUGGING FACE
:: ============================================================================

echo.
echo ============================================================
echo       ENABLING HUGGING FACE PLUGIN
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config set plugins.entries.huggingface.enabled true

if errorlevel 1 (
    echo ERROR: Failed enabling Hugging Face plugin.
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIGURE MEMORY LANCEDB
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING MEMORY LANCEDB
echo ============================================================
echo.

:: Select Memory LanceDB as active memory provider.

"%_OPENCLAW_CMD%" config set plugins.slots.memory memory-lancedb

if errorlevel 1 (
    echo ERROR: Failed selecting memory-lancedb.
    pause
    exit /b 1
)

:: Enable Memory LanceDB.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.enabled true

if errorlevel 1 (
    echo ERROR: Failed enabling memory-lancedb.
    pause
    exit /b 1
)

:: Use Ollama for embeddings.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.embedding.provider ollama

if errorlevel 1 (
    echo ERROR: Failed configuring Ollama as memory embedding provider.
    pause
    exit /b 1
)

:: Select embedding model.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.embedding.model "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo ERROR: Failed configuring memory embedding model.
    pause
    exit /b 1
)

:: Explicit vector dimensions.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.embedding.dimensions %OLLAMA_EMBED_DIMENSIONS%

if errorlevel 1 (
    echo ERROR: Failed configuring embedding dimensions.
    pause
    exit /b 1
)

:: Automatic capture.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.autoCapture true

if errorlevel 1 (
    echo ERROR: Failed enabling automatic memory capture.
    pause
    exit /b 1
)

:: Automatic recall.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.config.autoRecall true

if errorlevel 1 (
    echo ERROR: Failed enabling automatic memory recall.
    pause
    exit /b 1
)

:: Allow agent_end hook to access conversation data.

"%_OPENCLAW_CMD%" config set plugins.entries.memory-lancedb.hooks.allowConversationAccess true

if errorlevel 1 (
    echo ERROR: Failed enabling memory conversation access.
    pause
    exit /b 1
)


:: ============================================================================
:: INSTALL / VERIFY OLLAMA EMBEDDING MODEL
:: ============================================================================

echo.
echo ============================================================
echo       INSTALLING / VERIFYING OLLAMA EMBEDDING MODEL
echo ============================================================
echo.

echo Embedding model:
echo   %OLLAMA_EMBED_MODEL%
echo.
echo Dimensions:
echo   %OLLAMA_EMBED_DIMENSIONS%
echo.

ollama pull "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Failed installing Ollama embedding model.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY OLLAMA MODELS
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA MODELS
echo ============================================================
echo.

ollama list

if errorlevel 1 (
    echo ERROR: Ollama model listing failed.
    pause
    exit /b 1
)

echo.
echo Verifying embedding model:
echo.

ollama show "%OLLAMA_EMBED_MODEL%"

if errorlevel 1 (
    echo.
    echo ERROR: Ollama embedding model verification failed.
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
    echo Make sure Ollama is running and the embedding model
    echo is installed correctly.
    echo.
    pause
    exit /b 1
)

echo.
echo.
echo Ollama embedding API test completed successfully.
echo.


:: ============================================================================
:: VERIFY COMPLETE MEMORY LANCEDB CONFIGURATION
:: ============================================================================
::
:: INFORMATIONAL ONLY.
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING MEMORY LANCEDB CONFIGURATION
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config get plugins.entries.memory-lancedb --json

echo.
echo Memory LanceDB configuration inspection complete.
echo.


:: ============================================================================
:: VERIFY MEMORY SLOT
:: ============================================================================
::
:: INFORMATIONAL ONLY.
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING ACTIVE MEMORY SLOT
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config get plugins.slots --json

echo.
echo Memory slot inspection complete.
echo.


:: ============================================================================
:: CONFIGURE DUCKDUCKGO WEB SEARCH
:: ============================================================================

echo.
echo ============================================================
echo       CONFIGURING DUCKDUCKGO WEB SEARCH
echo ============================================================
echo.

echo Web search: DuckDuckGo
echo Web fetch:  ENABLED
echo.

"%_OPENCLAW_CMD%" config set tools.web.search.enabled true

if errorlevel 1 (
    echo ERROR: Failed enabling web search.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set tools.web.search.provider duckduckgo

if errorlevel 1 (
    echo ERROR: Failed selecting DuckDuckGo.
    pause
    exit /b 1
)

"%_OPENCLAW_CMD%" config set tools.web.fetch.enabled true

if errorlevel 1 (
    echo ERROR: Failed enabling web fetch.
    pause
    exit /b 1
)


:: ============================================================================
:: VERIFY WEB CONFIGURATION
:: ============================================================================
::
:: INFORMATIONAL ONLY.
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING WEB CONFIGURATION
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config get tools.web --json

echo.
echo Web configuration inspection complete.
echo.


:: ============================================================================
:: VERIFY OLLAMA MODEL CONFIGURATION
:: ============================================================================
::
:: INFORMATIONAL ONLY.
:: ============================================================================

echo.
echo ============================================================
echo       VERIFYING OLLAMA MODEL CONFIGURATION
echo ============================================================
echo.

echo Configured primary model:
echo   ollama/%OLLAMA_MODEL%
echo.

"%_OPENCLAW_CMD%" config get agents.defaults.model --json

echo.
echo Ollama model configuration inspection complete.
echo.


:: ============================================================================
:: FINAL CONFIGURATION VALIDATION
:: ============================================================================

echo.
echo ============================================================
echo       VALIDATING FINAL OPENCLAW CONFIGURATION
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config validate

if errorlevel 1 (
    echo.
    echo ========================================================
    echo       OPENCLAW CONFIGURATION VALIDATION FAILED
    echo ========================================================
    echo.
    echo Review the validation output above.
    echo.
    pause
    exit /b 1
)

echo.
echo OpenClaw configuration validation PASSED.
echo.


:: ============================================================================
:: INSPECT MEMORY LANCEDB
:: ============================================================================
::
:: This is a health/installation check.
:: ============================================================================

echo.
echo ============================================================
echo       INSPECTING MEMORY LANCEDB
echo ============================================================
echo.

"%_OPENCLAW_CMD%" plugins inspect memory-lancedb

if errorlevel 1 (
    echo.
    echo ERROR: Memory LanceDB inspection failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Detailed Memory LanceDB information:
echo.

"%_OPENCLAW_CMD%" plugins inspect memory-lancedb --json

if errorlevel 1 (
    echo.
    echo ERROR: Detailed Memory LanceDB inspection failed.
    echo.
    pause
    exit /b 1
)


:: ============================================================================
:: CONFIRM MEMORY SLOT OWNERSHIP
:: ============================================================================
::
:: INFORMATIONAL ONLY.
:: ============================================================================

echo.
echo ============================================================
echo       CONFIRMING MEMORY SLOT OWNERSHIP
echo ============================================================
echo.

"%_OPENCLAW_CMD%" config get plugins.slots --json

echo.
echo Memory slot ownership inspection complete.
echo.


:: ============================================================================
:: OPENCLAW DOCTOR
:: ============================================================================

echo.
echo ============================================================
echo       RUNNING OPENCLAW DOCTOR
echo ============================================================
echo.

"%_OPENCLAW_CMD%" doctor

if errorlevel 1 (
    echo.
    echo ========================================================
    echo       OPENCLAW DOCTOR REPORTED A FAILURE
    echo ========================================================
    echo.
    echo Review the diagnostic output above.
    echo.
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

"%_OPENCLAW_CMD%" config validate

if errorlevel 1 (
    echo.
    echo ERROR: Final OpenClaw configuration validation failed.
    echo.
    pause
    exit /b 1
)

echo.
echo Final OpenClaw configuration validation PASSED.
echo.


:: ============================================================================
:: FINAL SUMMARY
:: ============================================================================

echo.
echo ============================================================
echo       OPENCLAW ONBOARDING COMPLETE
echo ============================================================
echo.

echo Isolated OpenClaw:
echo   HOME:
echo     %OPENCLAW_HOME%
echo.
echo   CONFIG:
echo     %OPENCLAW_CONFIG_PATH%
echo.

echo Primary Ollama model:
echo   ollama/%OLLAMA_MODEL%
echo.

echo Embedding model:
echo   %OLLAMA_EMBED_MODEL%
echo.

echo Embedding dimensions:
echo   %OLLAMA_EMBED_DIMENSIONS%
echo.

echo Memory:
echo   LanceDB:     ENABLED
echo   AutoCapture: ENABLED
echo   AutoRecall:  ENABLED
echo.

echo Plugins:
echo   Google:       ENABLED
echo   Hugging Face: ENABLED
echo.

echo Web:
echo   DuckDuckGo:   ENABLED
echo   Web Fetch:    ENABLED
echo.

echo Tools:
echo   Filesystem:   ENABLED
echo   Internet:     ENABLED
echo   Browser:      ENABLED
echo   Python:       ENABLED
echo   Git:          ENABLED
echo   Host Exec:    ENABLED
echo   Sandboxing:   DISABLED
echo.

echo ============================================================
echo       GATEWAY WAS NOT STARTED
echo ============================================================
echo.
echo This onboarding script only configures OpenClaw.
echo.
echo Start the runtime with:
echo.
echo   Run-Engine-Ollama - OpenClaw - Get tokenized dashboard URL.bat
echo.
echo ============================================================
echo       ONBOARDING FINISHED SUCCESSFULLY
echo ============================================================
echo.

pause

endlocal
exit /b 0