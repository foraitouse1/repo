@echo off
setlocal

set "OWNER=foraitouse1"
set "REPO=repo"
set "FOLDER=AI/PortableEngines/Chat-Text-VL/llama.cpp Unsloth Fork"
set "TOKENFILE=%~dp0GetGithubRAWUrls-PAToken.txt"
set "OUTPUT=%~dp0RAW_URLS.txt"

if not exist "%TOKENFILE%" (
echo ERROR: PAToken.txt not found.
pause
exit /b 1
)

set /p TOKEN=<"%TOKENFILE%"

if not defined TOKEN (
echo ERROR: PAToken.txt is empty.
pause
exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$headers = @{ Authorization = 'Bearer %TOKEN%'; Accept = 'application/vnd.github+json' }; $url = 'https://api.github.com/repos/%OWNER%/%REPO%/contents/' + [uri]::EscapeDataString('%FOLDER%'); $items = Invoke-RestMethod -Uri $url -Headers $headers -Method Get; foreach ($item in $items) { if ($item.type -eq 'file') { $item.download_url } }" > "%OUTPUT%"

if errorlevel 1 (
echo ERROR: GitHub request failed.
) else (
echo RAW URLs saved to:
echo "%OUTPUT%"
)

pause
endlocal
