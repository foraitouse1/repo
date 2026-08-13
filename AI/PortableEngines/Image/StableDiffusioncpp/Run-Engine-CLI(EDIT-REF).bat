```bat
@echo off
setlocal

call "%~dp0IsolateEnv-Initialize.bat"
if not defined SCRIPT_DIR (
    echo ERROR: SCRIPT_DIR not defined...IsolateEnv.bat failed
    exit /b 1
)

REM ============================================================
REM FLUX.2 KLEIN 4B - IMAGE EDIT + REFERENCE
REM ============================================================

set "INPUT=%SCRIPT_DIR%\test.jpg"
set "REFERENCE=%SCRIPT_DIR%\reference.jpg"
set "OUTPUT=%SCRIPT_DIR%\test-edit2.jpg"
set "PROMPT=Make the plane in the reference image appear in the sky above the plane in the input image (test.jpg). Keep background, lighting, and composition unchanged. make sure not to crop the image."

set "WIDTH=512"
set "HEIGHT=512"

set "STEPS=20"

if not defined _HOST (
    echo ERROR: _HOST not defined...IsolateEnv_Project.bat failed
    exit /b 1
)
if not defined _SD_PORT (
    echo ERROR: _SD_PORT not defined...IsolateEnv_Project.bat failed
    exit /b 1
)

set "SERVER=http://%_HOST%:%_SD_PORT%"
set "API=%SERVER%/sdcpp/v1/img_gen"
set "JOB_API=%SERVER%/sdcpp/v1/jobs"


REM ============================================================
REM DO NOT EDIT BELOW THIS LINE
REM ============================================================
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$image=[Convert]::ToBase64String([IO.File]::ReadAllBytes('%INPUT%')); $reference=[Convert]::ToBase64String([IO.File]::ReadAllBytes('%REFERENCE%')); $body=@{prompt='%PROMPT%'; width=[int]%WIDTH%; height=[int]%HEIGHT%; init_image=$image; ref_images=@($reference); sample_params=@{sample_steps=[int]%STEPS%}} | ConvertTo-Json -Depth 10; Write-Host ''; Write-Host 'Submitting FLUX.2 Klein edit + reference...'; Write-Host ('Input     : %INPUT%'); Write-Host ('Reference : %REFERENCE%'); Write-Host ('Output    : %OUTPUT%'); Write-Host ('Size      : %WIDTH%x%HEIGHT%'); Write-Host ('Steps     : %STEPS%'); Write-Host ('Prompt    : %PROMPT%'); Write-Host ''; $job=Invoke-RestMethod -Uri '%API%' -Method Post -ContentType 'application/json' -Body $body; Write-Host ('Job ID: '+$job.id); do { Start-Sleep -Milliseconds 500; $result=Invoke-RestMethod -Uri ('%JOB_API%/'+$job.id); Write-Host ('Status: '+$result.status) } while ($result.status -ne 'completed'); [IO.File]::WriteAllBytes('%OUTPUT%',[Convert]::FromBase64String($result.result.images[0].b64_json)); Write-Host ''; Write-Host '========================================'; Write-Host 'DONE'; Write-Host ('Output: '+$env:OUTPUT); Write-Host '========================================'"

echo.
pause
```
