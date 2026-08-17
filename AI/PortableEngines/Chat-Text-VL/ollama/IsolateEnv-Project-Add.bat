:: ============================================================================
:: IsolateEnv-Project-Add.bat - QUICK USAGE
:: ============================================================================
::
:: Adds a SET definition to IsolateEnv-Project.bat under :DATA.
::
:: Basic call:
::
::   call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "NAME=value"
::
:: The generated entry is:
::
::   ::added by 'CallingScript.bat'
::   set "NAME=value"
::   ECHO NAME=%NAME%
::
:: ---------------------------------------------------------------------------
:: EXAMPLES
:: ---------------------------------------------------------------------------
::
:: Literal text:
::
::   call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "MY_NAME=John Smith"
::
:: Environment variable:
::
::   call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "MY_PATH=%%%%USERPROFILE%%%%"
::
:: Text + environment variable:
::
::   call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "SSL_CERT_FILE=%%%%COMMONPROGRAMFILES%%%%\cacert.pem"
::
:: Multiple environment variables:
::
::   call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "PATH=%%%%USERPROFILE%%%%%%%%APPDATA%%%%\MyApp"
::
:: ---------------------------------------------------------------------------
:: IMPORTANT
:: ---------------------------------------------------------------------------
::
:: Because this is called with CALL, environment variables need FOUR % signs.
::
::   Desired result:    %COMMONPROGRAMFILES%\cacert.pem
::   In the CALL:       %%%%COMMONPROGRAMFILES%%%%\cacert.pem
::
:: Literal text needs no special escaping:
::
::   SET "NAME=hello world"
::
:: The output is ALWAYS normalized to:
::
::   set "NAME=value"
::
:: ---------------------------------------------------------------------------
:: EXISTING VARIABLE BEHAVIOR
:: ---------------------------------------------------------------------------
::
:: If the variable already exists:
::
::   SAME NAME + SAME VALUE
::       -> No changes needed.
::
::   SAME NAME + DIFFERENT VALUE
::       -> Error.
::
::   PATH + DIFFERENT VALUE
::       -> Add a new PATH block.
::
:: The "added by" comment is NEVER used when comparing values.
::
:: ============================================================================

@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: =========================================================================
:: Configuration
:: =========================================================================

set "DEBUG=0"
::set "DEBUG=1"

if "%DEBUG%"=="1" echo [DEBUG] Starting IsolateEnv-Project-Add.bat...

:: =========================================================================
:: Create temporary PowerShell script directly under %TEMP%
:: =========================================================================

set "PS_SCRIPT=%TEMP%\IsolateEnvWorker_%RANDOM%.ps1"

> "%PS_SCRIPT%" echo param($DebugMode)
>> "%PS_SCRIPT%" echo $debug = $DebugMode -eq '1'
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host '[DEBUG-PS] Entered PowerShell execution block.' -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $allArgs = $args
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host "[DEBUG-PS] Total arguments received: $($allArgs.Count)" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($allArgs.Count -lt 2) {
>> "%PS_SCRIPT%" echo     Write-Host 'ERROR: Missing arguments. Expected calling script and SET command.' -ForegroundColor Red
>> "%PS_SCRIPT%" echo     exit 1
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $callingScript = $allArgs[0]
>> "%PS_SCRIPT%" echo $envLine = ($allArgs[1..($allArgs.Count - 1)] -join ' ')
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host "[DEBUG-PS] Calling Script: '$callingScript'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host "[DEBUG-PS] Raw Env Line: '$envLine'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $setText = $envLine.Trim()
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($setText.Length -ge 3 -and $setText.Substring(0,3).ToUpper() -eq 'SET') {
>> "%PS_SCRIPT%" echo     $setText = $setText.Substring(3).Trim()
>> "%PS_SCRIPT%" echo } else {
>> "%PS_SCRIPT%" echo     Write-Host "ERROR: Command must begin with SET: '$envLine'" -ForegroundColor Red
>> "%PS_SCRIPT%" echo     exit 1
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($setText.Length -ge 2 -and $setText[0] -eq '"' -and $setText[$setText.Length - 1] -eq '"') {
>> "%PS_SCRIPT%" echo     $setText = $setText.Substring(1, $setText.Length - 2)
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $equalsIndex = $setText.IndexOf('=')
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($equalsIndex -le 0) {
>> "%PS_SCRIPT%" echo     Write-Host "ERROR: Invalid environment variable syntax: '$envLine'" -ForegroundColor Red
>> "%PS_SCRIPT%" echo     exit 1
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $varName = $setText.Substring(0, $equalsIndex).Trim()
>> "%PS_SCRIPT%" echo $value = $setText.Substring($equalsIndex + 1)
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ([string]::IsNullOrWhiteSpace($varName)) {
>> "%PS_SCRIPT%" echo     Write-Host "ERROR: Environment variable name is empty." -ForegroundColor Red
>> "%PS_SCRIPT%" echo     exit 1
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host "[DEBUG-PS] Variable name: '$varName'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host "[DEBUG-PS] New value: '$value'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $setLine = "set `"$varName=$value`""
>> "%PS_SCRIPT%" echo $percent = [char]37
>> "%PS_SCRIPT%" echo $echoLine = "ECHO $varName=$percent$varName$percent"
>> "%PS_SCRIPT%" echo $newBlock = "::added by '$callingScript'`r`n$setLine`r`n$echoLine"
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host "[DEBUG-PS] Canonical SET line: '$setLine'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $targetFile = 'IsolateEnv-Project.bat'
>> "%PS_SCRIPT%" echo $headerText = ''
>> "%PS_SCRIPT%" echo $blocks = @()
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if (Test-Path $targetFile) {
>> "%PS_SCRIPT%" echo     if ($debug) { Write-Host "[DEBUG-PS] Target file found at '$targetFile'. Reading..." -ForegroundColor Green }
>> "%PS_SCRIPT%" echo     $content = Get-Content $targetFile -Raw
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo     if ($content -match '(?is)^([\s\S]*?)(?:^|\r?\n)\s*:DATA\s*\r?\n([\s\S]*)$') {
>> "%PS_SCRIPT%" echo         $headerText = $Matches[1].TrimEnd()
>> "%PS_SCRIPT%" echo         $dataSection = $Matches[2].Trim()
>> "%PS_SCRIPT%" echo         if ($debug) { Write-Host '[DEBUG-PS] Successfully matched :DATA section.' -ForegroundColor Green }
>> "%PS_SCRIPT%" echo     } else {
>> "%PS_SCRIPT%" echo         Write-Host "ERROR: Target file '$targetFile' does not contain a ':DATA' section!" -ForegroundColor Red
>> "%PS_SCRIPT%" echo         exit 1
>> "%PS_SCRIPT%" echo     }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo     if ($dataSection) {
>> "%PS_SCRIPT%" echo         $rawBlocks = $dataSection -split '\r?\n\r?\n'
>> "%PS_SCRIPT%" echo         if ($debug) { Write-Host "[DEBUG-PS] Found $($rawBlocks.Count) existing data block(s)." -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo         foreach ($b in $rawBlocks) {
>> "%PS_SCRIPT%" echo             if ($b.Trim()) {
>> "%PS_SCRIPT%" echo                 $lines = $b.Trim() -split '\r?\n'
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo                 foreach ($line in $lines) {
>> "%PS_SCRIPT%" echo                     $existingSet = $line.Trim()
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo                     if ($existingSet -match '^(?i)set\s+"([^"=]+)=(.*)"$') {
>> "%PS_SCRIPT%" echo                         $existingVar = $Matches[1].Trim()
>> "%PS_SCRIPT%" echo                         $existingValue = $Matches[2]
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo                         $blocks += [PSCustomObject]@{
>> "%PS_SCRIPT%" echo                             Name = $existingVar
>> "%PS_SCRIPT%" echo                             Value = $existingValue
>> "%PS_SCRIPT%" echo                             Content = ($lines -join "`r`n")
>> "%PS_SCRIPT%" echo                         }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo                         break
>> "%PS_SCRIPT%" echo                     }
>> "%PS_SCRIPT%" echo                 }
>> "%PS_SCRIPT%" echo             }
>> "%PS_SCRIPT%" echo         }
>> "%PS_SCRIPT%" echo     }
>> "%PS_SCRIPT%" echo } else {
>> "%PS_SCRIPT%" echo     Write-Host "ERROR: Target file '$targetFile' not found!" -ForegroundColor Red
>> "%PS_SCRIPT%" echo     exit 1
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $existing = $null
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo foreach ($block in $blocks) {
>> "%PS_SCRIPT%" echo     if ($block.Name -eq $varName) {
>> "%PS_SCRIPT%" echo         $existing = $block
>> "%PS_SCRIPT%" echo         break
>> "%PS_SCRIPT%" echo     }
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($existing) {
>> "%PS_SCRIPT%" echo     if ($debug) { Write-Host "[DEBUG-PS] Variable '$varName' already exists." -ForegroundColor Green }
>> "%PS_SCRIPT%" echo     if ($debug) { Write-Host "[DEBUG-PS] Existing value: '$($existing.Value)'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo     if ($debug) { Write-Host "[DEBUG-PS] Requested value: '$value'" -ForegroundColor Green }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo     if ($existing.Value -eq $value) {
>> "%PS_SCRIPT%" echo         if ($debug) { Write-Host '[DEBUG-PS] Existing value is identical. No changes needed.' -ForegroundColor Green }
>> "%PS_SCRIPT%" echo         exit 0
>> "%PS_SCRIPT%" echo     }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo     if ($varName -eq 'PATH') {
>> "%PS_SCRIPT%" echo         if ($debug) { Write-Host '[DEBUG-PS] Existing PATH differs. Adding new PATH block.' -ForegroundColor Green }
>> "%PS_SCRIPT%" echo     } else {
>> "%PS_SCRIPT%" echo         Write-Host "ERROR: Variable '$varName' already exists with a different value!" -ForegroundColor Red
>> "%PS_SCRIPT%" echo         Write-Host "Existing value: '$($existing.Value)'" -ForegroundColor Red
>> "%PS_SCRIPT%" echo         Write-Host "Requested value: '$value'" -ForegroundColor Red
>> "%PS_SCRIPT%" echo         exit 1
>> "%PS_SCRIPT%" echo     }
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $blocks += [PSCustomObject]@{
>> "%PS_SCRIPT%" echo     Name = $varName
>> "%PS_SCRIPT%" echo     Value = $value
>> "%PS_SCRIPT%" echo     Content = $newBlock
>> "%PS_SCRIPT%" echo }
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $dataOutput = ($blocks ^| ForEach-Object { $_.Content }) -join "`r`n`r`n"
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo $finalOutput = $headerText + "`r`n`r`n`r`n:DATA`r`n`r`n" + $dataOutput + "`r`n"
>> "%PS_SCRIPT%" echo.
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host '[DEBUG-PS] Writing updated content to IsolateEnv-Project.bat...' -ForegroundColor Green }
>> "%PS_SCRIPT%" echo Set-Content -Path $targetFile -Value $finalOutput -Encoding ASCII
>> "%PS_SCRIPT%" echo if ($debug) { Write-Host '[DEBUG-PS] File successfully updated!' -ForegroundColor Green }

:: =========================================================================
:: Debug: show generated PowerShell script
:: =========================================================================

if "%DEBUG%"=="1" (
    echo [DEBUG] Temporary PowerShell script:
    echo ---------------------------------------------------------
    type "%PS_SCRIPT%"
    echo ---------------------------------------------------------
)

:: =========================================================================
:: Execute PowerShell worker
:: =========================================================================

if "%DEBUG%"=="1" echo [DEBUG] Executing temporary PowerShell script file...

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" "%DEBUG%" %*
set "ERR=%ERRORLEVEL%"

:: =========================================================================
:: Cleanup
:: =========================================================================

if exist "%PS_SCRIPT%" del /q "%PS_SCRIPT%"

if not "%ERR%"=="0" (
    if "%DEBUG%"=="1" echo [DEBUG] ERROR: Script execution failed with exit code %ERR%.
    endlocal
    exit /b %ERR%
)

if "%DEBUG%"=="1" echo [DEBUG] Done.

endlocal
exit /b 0
