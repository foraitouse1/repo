@echo off
setlocal

set "OWNER=foraitouse1"
set "REPO=repo"
set "FOLDER=AI/PortableEngines/Chat-Text-VL/llama.cpp"
set "OUTPUT=%~dp0RAW_URLS.txt"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$url = 'https://api.github.com/repos/%OWNER%/%REPO%/contents/' + [uri]::EscapeDataString('%FOLDER%'); $items = Invoke-RestMethod -Uri $url -Method Get; foreach ($item in $items) { if ($item.type -eq 'file') { $item.download_url } }" > "%OUTPUT%"

if errorlevel 1 (
echo ERROR: GitHub request failed.
) else (
echo RAW URLs saved to:
echo "%OUTPUT%"
)

pause
endlocal
