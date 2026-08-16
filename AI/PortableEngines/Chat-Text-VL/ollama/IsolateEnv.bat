:: IsolateEnv.bat

:: @echo off
:: call "%~dp0IsolateEnv.bat"

:: Why call matters
:: Without call, control never returns to the parent .bat
:: With call, the environment variables set in the child persist in the parent

:: What not to do
:: isolate_env.bat   ← BAD (replaces current script)
:: start isolate_env.bat  ← BAD (new process, env lost)

:: DO NOT USE start TO RUN .EXE or PowerShell scripts (also make sure PowerShell script does NOT have "Start" in it

:: Only these directories must exist or things break immediately:

:: drive                         %HOMEDRIVE%
:: your-folder\                  %SCRIPT_DIR%
:: │  IsolateEnv.bat
:: │  IsolateEnv-Project.bat
:: │
:: └─ Cdrive\                    %BASE_DIR%
::    ├─ User\                   %USERNAME%      %USERPROFILE%      %HOME%      %HOMEPATH%
::    ├─     \.cache             %XDG_CACHE_HOME%
::    ├─     \.ssh               %SSH_HOME%
::    ├─     \AppData\Local      %LOCALAPPDATA%
::    ├─     \AppData\LocalLow   %LOCALLOWAPPDATA%
::    ├─     \AppData\Roaming    %APPDATA%
::    ├─     \Documents          %USERDOCS%
::    ├─     \Desktop            %DESKTOP%
::    ├─ ProgramData\            %PROGRAMDATA%
::    ├─ Public\                 %PUBLIC%
::    ├─ Common\                 %COMMONPROGRAMFILES%
::    ├─ CommonX86\              %COMMONPROGRAMFILES(x86)%
::    ├─ Temp\                   %TEMP%          %TMP%


:: Everything else is lazy-created by the owning runtime

:: If process creates "Sandbox", it was created by the Setup program. This is expected behavior under aggressive environment redirection

@echo off

:: --- create Cdrive in the same folder as this script ---
:: 1. Get the directory of the script
SET "SCRIPT_DIR=%~dp0"

:: 2. Create Cdrive inside the script's folder
SET "BASE_DIR=%SCRIPT_DIR%Cdrive\"
if not exist "%BASE_DIR%" mkdir "%BASE_DIR%"

:: --- Extract Drive letter from BASE_DIR for consistency ---
SET "HOMEDRIVE=%BASE_DIR:~0,2%"

:: --- Core Identity ---
SET "USERPROFILE=%BASE_DIR%User"
mkdir "%USERPROFILE%" 2>nul

SET "USERNAME=User"
SET "HOME=%USERPROFILE%"
SET "HOMEPATH=\User"

:: --- XDG (Cross-Desktop Group) standards designed to standardize file locations and desktop integration---
SET "XDG_CACHE_HOME=%USERPROFILE%\.cache"
:: auto-created by tools → no mkdir

SET "APPDATA=%USERPROFILE%\AppData\Roaming"
mkdir "%APPDATA%" 2>nul

SET "LOCALAPPDATA=%USERPROFILE%\AppData\Local"
mkdir "%LOCALAPPDATA%" 2>nul

SET "LOCALLOWAPPDATA=%USERPROFILE%\AppData\LocalLow"
mkdir "%LOCALLOWAPPDATA%" 2>nul

SET "PROGRAMDATA=%BASE_DIR%ProgramData"
mkdir "%PROGRAMDATA%" 2>nul
SET "ALLUSERSPROFILE=%PROGRAMDATA%"

SET "PUBLIC=%BASE_DIR%Public"
mkdir "%PUBLIC%" 2>nul

SET "USERDOCS=%USERPROFILE%\Documents"
mkdir "%USERDOCS%" 2>nul

SET "DESKTOP=%USERPROFILE%\Desktop"
mkdir "%DESKTOP%" 2>nul

SET "SSH_HOME=%USERPROFILE%\.ssh"
:: ssh creates this itself → no mkdir

SET "COMMONPROGRAMFILES=%BASE_DIR%Common"
mkdir "%COMMONPROGRAMFILES%" 2>nul

SET "COMMONPROGRAMFILES(x86)=%BASE_DIR%CommonX86"
mkdir "%COMMONPROGRAMFILES(x86)%" 2>nul

:: --- Temp (MUST exist) ---
SET "TEMP=%BASE_DIR%Temp"
mkdir "%TEMP%" 2>nul
SET "TMP=%BASE_DIR%Temp"



:: ------------------------------------------------
:: COMMENTED ISOLATION EXTENSIONS
GOTO :EndComment

:: --- Tooling ---
SET "GIT_CONFIG_GLOBAL=%USERPROFILE%\.gitconfig"
:: file → no mkdir

SET "AWS_SHARED_CREDENTIALS_FILE=%USERPROFILE%\.aws\credentials"
:: aws creates parents → no mkdir

SET "AWS_CONFIG_FILE=%USERPROFILE%\.aws\config"
:: aws creates parents → no mkdir

SET "NUGET_PACKAGES=%BASE_DIR%Common\.nuget"
:: nuget auto-creates → no mkdir

:: --- AI Models / Caches ---
SET "HF_HOME=%BASE_DIR%Models\.cache"
:: auto-created → no mkdir

SET "PIP_CACHE_DIR=%BASE_DIR%Models\.cache\pip"
:: auto-created

SET "PYTHONUSERBASE=%USERPROFILE%"
:: already exists

:: --- Python Bytecode ---
SET "PYTHONPYCACHEPREFIX=%USERPROFILE%\.pycache"
:: DO NOT CREATE __pycache__ directories
set PYTHONDONTWRITEBYTECODE=1
:: auto-created by CPython → no mkdir

:: --- Needed by ollama
:: include these three essential "passthrough" variables. This keeps your files isolated but gives the executable the "map" it needs to use the CPU/GPU and Network:
SET "SystemRoot=%SystemDrive%\Windows"
SET "SystemDrive=%SystemDrive%"
SET "Path=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%Path%"
:: --- Force Ollama to be more patient ---
SET "OLLAMA_LOAD_TIMEOUT=10m"
:: Add the location of the ollama.exe to the PATH so the 'Runner' and 'Client' can find each other
SET "PATH=%LOCALAPPDATA%\Programs\Ollama;%PATH%"
:: Explicitly tell Ollama where the server is
SET "OLLAMA_HOST=127.0.0.1:11434"
SET "NO_PROXY=localhost,127.0.0.1"

:EndComment




:: --- Verification ---
echo ====================================================
echo         PORTABLE ENVIRONMENT ACTIVE
echo ====================================================
echo [IDENTITY]
echo USERNAME:         %USERNAME%
echo USERPROFILE:      %USERPROFILE%
echo HOME:             %HOME%
echo HOMEDRIVE:        %HOMEDRIVE%
echo HOMEPATH:         %HOMEPATH%
echo.
echo [PATHS]
echo SCRIPT_DIR:       %SCRIPT_DIR%
echo BASE_DIR:         %BASE_DIR%
echo APPDATA:          %APPDATA%
echo LOCALAPPDATA:     %LOCALAPPDATA%
echo LOCALLOWAPPDATA:  %LOCALLOWAPPDATA%
echo PROGRAMDATA:      %PROGRAMDATA%
echo ALLUSERSPROFILE:  %ALLUSERSPROFILE%
echo PUBLIC:           %PUBLIC%
echo.
echo [FOLDERS]
echo DOCUMENTS:        %USERDOCS%
echo DESKTOP:          %DESKTOP%
echo TEMP/TMP:         %TEMP%
echo.
echo [SYSTEM/CERTS]
echo COMMONPROG:       %COMMONPROGRAMFILES%
echo COMMONX86:        %COMMONPROGRAMFILES(x86)%
echo SSL_CERT:         %SSL_CERT_FILE%
echo.
echo [EXTENSIONS]
echo XDG_CACHE:        %XDG_CACHE_HOME%
echo SSH_HOME:         %SSH_HOME%
echo ====================================================
