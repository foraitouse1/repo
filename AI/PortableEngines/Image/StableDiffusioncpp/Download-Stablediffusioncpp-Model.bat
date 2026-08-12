@echo off
setlocal EnableExtensions DisableDelayedExpansion

:: ====================================================
:: Portable Vanilla stable-diffusion.cpp Model Downloader
:: ====================================================

set "_MODEL_NAME=FLUX.2-KLEIN-4B"

:: ----------------------------------------------------
:: Quantization settings
::
:: FLUX.2-klein-4B GGUF currently provides:
::     Q4_0
::     Q8_0
::
:: Qwen3-4B GGUF provides:
::     Q4_K_M
::     and other quantizations
::
:: Keep these independent because the two repositories
:: do not use the same quantization set.
:: ----------------------------------------------------

set "_DIFFUSION_QUANT=Q4_0"
set "_LLM_QUANT=Q4_K_M"

echo ====================================================
echo        PORTABLE STABLE-DIFFUSION.CPP MODEL
echo                     DOWNLOADER
echo ====================================================
echo Model: %_MODEL_NAME%
echo Diffusion Quant: %_DIFFUSION_QUANT%
echo LLM Quant: %_LLM_QUANT%
echo.

call "%~dp0IsolateEnv-Initialize.bat"

set "_MODEL_DIR=%SCRIPT_DIR%Models"

if not exist "%_MODEL_DIR%" mkdir "%_MODEL_DIR%"

set "_PS_FILE=%TEMP%\model_download.ps1"

call :WritePowerShell > "%_PS_FILE%"

if not exist "%_PS_FILE%" (
    echo ERROR: Failed creating PowerShell downloader
    pause
    exit /b 1
)

powershell.exe ^
    -NoProfile ^
    -ExecutionPolicy Bypass ^
    -File "%_PS_FILE%"

if errorlevel 1 (
    echo ====================================================
    echo        MODEL DOWNLOAD FAILED
    echo ====================================================
    del "%_PS_FILE%" >nul 2>&1
    pause
    exit /b 1
)

echo ====================================================
echo        MODEL DOWNLOAD COMPLETE
echo ====================================================

del "%_PS_FILE%" >nul 2>&1

call IsolateEnv-Project-Add.bat "%~n0%~x0" SET "_MODEL_DIR=%%%%SCRIPT_DIR%%%%Models"

pause

endlocal
exit /b 0


:WritePowerShell

echo $ErrorActionPreference = "Stop"
echo.
echo $ModelName = [Environment]::GetEnvironmentVariable("_MODEL_NAME")
echo $DiffusionQuant = [Environment]::GetEnvironmentVariable("_DIFFUSION_QUANT")
echo $LlmQuant = [Environment]::GetEnvironmentVariable("_LLM_QUANT")
echo $Root = [Environment]::GetEnvironmentVariable("SCRIPT_DIR")
echo $ModelRoot = [Environment]::GetEnvironmentVariable("_MODEL_DIR")
echo.
echo $GitHubApi = "https://api.github.com"
echo $HFBase = "https://huggingface.co"
echo.
echo function Normalize-Text {
echo     param([string]$Text)
echo.
echo     if ($null -eq $Text) {
echo         return ""
echo     }
echo.
echo     return (($Text.ToLowerInvariant()) -replace "[^a-z0-9]+","")
echo }
echo.
echo function Get-RepoParts {
echo     param([string]$Url)
echo.
echo     $u = $Url
echo     $u = $u -replace "^https://huggingface\.co/",""
echo     $u = $u -replace "/tree/main/.*$",""
echo     $u = $u -replace "/blob/main/.*$",""
echo.
echo     $parts = $u.Trim("/") -split "/"
echo.
echo     if ($parts.Count -lt 2) {
echo         return $null
echo     }
echo.
echo     $repo = "$($parts[0])/$($parts[1])"
echo     $path = ""
echo.
echo     if ($Url -match "/tree/main/(.+)$") {
echo         $path = $Matches[1]
echo     }
echo     elseif ($Url -match "/blob/main/(.+)$") {
echo         $path = Split-Path $Matches[1] -Parent
echo     }
echo.
echo     return [PSCustomObject]@{
echo         Repo = $repo
echo         Path = $path
echo     }
echo }
echo.
echo function Get-HfFiles {
echo     param(
echo         [string]$Repo,
echo         [string]$Path
echo     )
echo.
echo     if ([string]::IsNullOrWhiteSpace($Path)) {
echo         $Url = "$HFBase/api/models/$Repo/tree/main?recursive=true"
echo     }
echo     else {
echo         $EncodedPath = (
echo             $Path -split "/" ^|
echo             ForEach-Object {
echo                 [uri]::EscapeDataString($_)
echo             }
echo         ) -join "/"
echo.
echo         $Url = "$HFBase/api/models/$Repo/tree/main/$EncodedPath?recursive=true"
echo     }
echo.
echo     try {
echo         return Invoke-RestMethod -Uri $Url -UseBasicParsing
echo     }
echo     catch {
echo         throw "Unable to inspect Hugging Face repository: $Repo"
echo     }
echo }
echo.
echo function Select-File {
echo     param(
echo         [array]$Files,
echo         [string]$Role,
echo         [string]$ModelName,
echo         [string]$Quant
echo     )
echo.
echo     $Usable = @(
echo         $Files ^|
echo         Where-Object {
echo             $_.type -eq "file" -and
echo             $_.path -match "(?i)\.(gguf|safetensors|ckpt|pth|pt)$"
echo         }
echo     )
echo.
echo     if (-not $Usable) {
echo         return $null
echo     }
echo.
echo     $ModelNorm = Normalize-Text $ModelName
echo.
echo     if ($Role -eq "diffusion") {
echo.
echo         $Preferred = @(
echo             $Usable ^|
echo             Where-Object {
echo                 $_.path -match "(?i)\.gguf$" -and
echo                 $_.path -match "(?i)$([regex]::Escape($Quant))"
echo             }
echo         )
echo.
echo         if (-not $Preferred) {
echo             $Preferred = @(
echo                 $Usable ^|
echo                 Where-Object {
echo                     $_.path -match "(?i)\.gguf$"
echo                 }
echo             )
echo         }
echo.
echo         if (-not $Preferred) {
echo             $Preferred = @(
echo                 $Usable ^|
echo                 Where-Object {
echo                     $_.path -match "(?i)\.safetensors$"
echo                 }
echo             )
echo         }
echo.
echo         if ($Preferred.Count -gt 1) {
echo             $Exact = @(
echo                 $Preferred ^|
echo                 Where-Object {
echo                     $FileNorm = Normalize-Text $_.path
echo                     $FileNorm -match [regex]::Escape($ModelNorm)
echo                 }
echo             )
echo.
echo             if ($Exact) {
echo                 $Preferred = $Exact
echo             }
echo         }
echo.
echo         return ($Preferred ^| Select-Object -First 1)
echo     }
echo.
echo     if ($Role -eq "vae") {
echo.
echo         $Preferred = @(
echo             $Usable ^|
echo             Where-Object {
echo                 $_.path -match "(?i)(vae|autoencoder|(^|/)ae\.)"
echo             }
echo         )
echo.
echo         if (-not $Preferred) {
echo             $Preferred = @(
echo                 $Usable ^|
echo                 Where-Object {
echo                     $_.path -match "(?i)\.safetensors$"
echo                 }
echo             )
echo         }
echo.
echo         return ($Preferred ^| Select-Object -First 1)
echo     }
echo.
echo     if ($Role -eq "llm") {
echo.
echo         $Preferred = @(
echo             $Usable ^|
echo             Where-Object {
echo                 $_.path -match "(?i)\.gguf$" -and
echo                 $_.path -match "(?i)$([regex]::Escape($Quant))"
echo             }
echo         )
echo.
echo         if (-not $Preferred) {
echo             $Preferred = @(
echo                 $Usable ^|
echo                 Where-Object {
echo                     $_.path -match "(?i)\.gguf$"
echo                 }
echo             )
echo         }
echo.
echo         return ($Preferred ^| Select-Object -First 1)
echo     }
echo.
echo     if ($Role -eq "clip_l") {
echo         return (
echo             $Usable ^|
echo             Where-Object {
echo                 $_.path -match "(?i)clip.?l"
echo             } ^|
echo             Select-Object -First 1
echo         )
echo     }
echo.
echo     if ($Role -eq "clip_g") {
echo         return (
echo             $Usable ^|
echo             Where-Object {
echo                 $_.path -match "(?i)clip.?g"
echo             } ^|
echo             Select-Object -First 1
echo         )
echo     }
echo.
echo     if ($Role -eq "t5xxl") {
echo         $Preferred = @(
echo             $Usable ^|
echo             Where-Object {
echo                 $_.path -match "(?i)t5" -and
echo                 (
echo                     $_.path -match "(?i)\.gguf$" -or
echo                     $_.path -match "(?i)\.safetensors$"
echo                 )
echo             }
echo         )
echo.
echo         return ($Preferred ^| Select-Object -First 1)
echo     }
echo.
echo     return ($Usable ^| Select-Object -First 1)
echo }
echo.
echo function Download-File {
echo     param(
echo         [string]$Repo,
echo         [string]$File,
echo         [string]$Destination
echo     )
echo.
echo     if (Test-Path $Destination) {
echo         Write-Host "Already exists: $Destination"
echo         return
echo     }
echo.
echo     $Encoded = (
echo         $File -split "/" ^|
echo         ForEach-Object {
echo             [uri]::EscapeDataString($_)
echo         }
echo     ) -join "/"
echo.
echo     $Url = "$HFBase/$Repo/resolve/main/$Encoded"
echo.
echo     Write-Host
echo     Write-Host "Downloading:"
echo     Write-Host $Url
echo.
echo     $Parent = Split-Path $Destination -Parent
echo.
echo     if (-not (Test-Path $Parent)) {
echo         New-Item -ItemType Directory -Path $Parent -Force ^| Out-Null
echo     }
echo.
echo     Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
echo.
echo     if (-not (Test-Path $Destination)) {
echo         throw "Download failed: $Destination"
echo     }
echo.
echo     $SizeGB = [math]::Round(
echo         (Get-Item $Destination).Length / 1GB,
echo         2
echo     )
echo.
echo     Write-Host "Downloaded: $Destination"
echo     Write-Host "Size: $SizeGB GB"
echo }
echo.
echo Write-Host "===================================================="
echo Write-Host " ONLINE MODEL DISCOVERY"
echo Write-Host "===================================================="
echo.
echo Write-Host "Searching stable-diffusion.cpp documentation for:"
echo Write-Host $ModelName
echo.
echo $Headers = @{
echo     "User-Agent" = "Portable-stable-diffusion.cpp-Model-Downloader"
echo }
echo.
echo $DocsApi = "$GitHubApi/repos/leejet/stable-diffusion.cpp/contents/docs"
echo $Docs = Invoke-RestMethod -Uri $DocsApi -Headers $Headers -UseBasicParsing
echo.
echo $MarkdownDocs = @(
echo     $Docs ^|
echo     Where-Object {
echo         $_.type -eq "file" -and
echo         $_.name -match "(?i)\.md$"
echo     }
echo )
echo.
echo $Matches = @()
echo.
echo foreach ($Doc in $MarkdownDocs) {
echo     try {
echo         $Raw = Invoke-RestMethod -Uri $Doc.download_url -Headers $Headers -UseBasicParsing
echo         $NormDoc = Normalize-Text $Raw
echo         $NormName = Normalize-Text $ModelName
echo.
echo         if ($NormDoc.Contains($NormName)) {
echo             $Matches += [PSCustomObject]@{
echo                 Name = $Doc.name
echo                 Url = $Doc.download_url
echo                 Text = $Raw
echo             }
echo         }
echo     }
echo     catch {
echo     }
echo }
echo.
echo if (-not $Matches) {
echo     throw "The model was not found in the current stable-diffusion.cpp documentation."
echo }
echo.
echo Write-Host "Matching documentation:"
echo foreach ($Match in $Matches) {
echo     Write-Host "  $($Match.Name)"
echo }
echo.
echo $SelectedDoc = $Matches ^|
echo     Sort-Object {
echo         $n = Normalize-Text $_.Text
echo         $n.IndexOf((Normalize-Text $ModelName))
echo     } ^|
echo     Select-Object -First 1
echo.
echo $Lines = $SelectedDoc.Text -split "`r?`n"
echo $NormName = Normalize-Text $ModelName
echo $HitIndex = -1
echo.
echo for ($i = 0; $i -lt $Lines.Count; $i++) {
echo     if ((Normalize-Text $Lines[$i]).Contains($NormName)) {
echo         $HitIndex = $i
echo         break
echo     }
echo }
echo.
echo if ($HitIndex -lt 0) {
echo     throw "Unable to locate the model section."
echo }
echo.
echo $SectionStart = 0
echo.
echo for ($i = $HitIndex; $i -ge 0; $i--) {
echo     if ($Lines[$i] -match "^#{1,3}\s+") {
echo         $SectionStart = $i
echo         break
echo     }
echo }
echo.
echo $SectionEnd = $Lines.Count
echo $StartLevel = 0
echo.
echo if ($Lines[$SectionStart] -match "^(#+)") {
echo     $StartLevel = $Matches[1].Length
echo }
echo.
echo for ($i = $SectionStart + 1; $i -lt $Lines.Count; $i++) {
echo     if ($Lines[$i] -match "^(#+)\s+") {
echo         if ($Matches[1].Length -le $StartLevel) {
echo             $SectionEnd = $i
echo             break
echo         }
echo     }
echo }
echo.
echo $Section = $Lines[$SectionStart..($SectionEnd - 1)] -join "`r`n"
echo.
echo Write-Host "Selected section:"
echo Write-Host $Lines[$SectionStart]
echo.
echo $UrlMatches = [regex]::Matches(
echo     $Section,
echo     "https://huggingface\.co/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+(?:/tree/main/[^\s\)]+|/blob/main/[^\s\)]+)?"
echo )
echo.
echo $Candidates = @()
echo.
echo foreach ($UrlMatch in $UrlMatches) {
echo     $Url = $UrlMatch.Value.TrimEnd(".",",")
echo     $Pos = $UrlMatch.Index
echo     $ContextStart = [math]::Max(0, $Pos - 220)
echo     $ContextLength = [math]::Min(
echo         220,
echo         $Section.Length - $ContextStart
echo     )
echo     $Context = $Section.Substring($ContextStart, $ContextLength)
echo     $Parts = Get-RepoParts $Url
echo.
echo     if ($Parts) {
echo         $Candidates += [PSCustomObject]@{
echo             Url = $Url
echo             Repo = $Parts.Repo
echo             Path = $Parts.Path
echo             Context = $Context
echo         }
echo     }
echo }
echo.
echo if (-not $Candidates) {
echo     throw "No Hugging Face model repositories were found in the model documentation section."
echo }
echo.
echo $UniqueCandidates = $Candidates ^|
echo     Group-Object Repo,Path ^|
echo     ForEach-Object {
echo         $_.Group[0]
echo     }
echo.
echo Write-Host
echo Write-Host "Discovered Hugging Face sources:"
echo.
echo foreach ($Candidate in $UniqueCandidates) {
echo     Write-Host "  $($Candidate.Repo)  $($Candidate.Path)"
echo }
echo.
echo # ------------------------------------------------
echo # Select the FLUX.2-klein-4B GGUF repository.
echo #
echo # The upstream documentation provides both:
echo #     black-forest-labs/FLUX.2-klein-4B
echo #     leejet/FLUX.2-klein-4B-GGUF
echo #
echo # For this portable stable-diffusion.cpp project
echo # we explicitly select the GGUF source.
echo # ------------------------------------------------
echo.
echo $DiffusionCandidate = $UniqueCandidates ^|
echo     Where-Object {
echo         $_.Repo -eq "leejet/FLUX.2-klein-4B-GGUF"
echo     } ^|
echo     Select-Object -First 1
echo.
echo if (-not $DiffusionCandidate) {
echo     throw "The required GGUF repository for FLUX.2-klein-4B was not found in the upstream documentation."
echo }
echo.
echo $DiffusionFiles = Get-HfFiles $DiffusionCandidate.Repo $DiffusionCandidate.Path
echo $DiffusionFile = Select-File $DiffusionFiles "diffusion" $ModelName $DiffusionQuant
echo.
echo if (-not $DiffusionFile) {
echo     throw "Unable to identify a usable $DiffusionQuant diffusion model in $($DiffusionCandidate.Repo)."
echo }
echo.
echo # ------------------------------------------------
echo # Prepare the model folder BEFORE VAE discovery.
echo #
echo # This allows an already-downloaded VAE to be used
echo # without querying the gated Hugging Face repository.
echo # ------------------------------------------------
echo.
echo $ModelFolderName = $ModelName
echo $InvalidChars = [IO.Path]::GetInvalidFileNameChars()
echo.
echo foreach ($Char in $InvalidChars) {
echo     $ModelFolderName = $ModelFolderName.Replace([string]$Char, "_")
echo }
echo.
echo $ModelFolderName = $ModelFolderName.Trim()
echo.
echo $ModelFolder = Join-Path $ModelRoot $ModelFolderName
echo.
echo New-Item -ItemType Directory -Path $ModelFolder -Force ^| Out-Null
echo.
echo # ------------------------------------------------
echo # Select the documented FLUX.2 VAE repository.
echo #
echo # If the VAE already exists locally, use it and
echo # do NOT query black-forest-labs/FLUX.2-dev.
echo # ------------------------------------------------
echo.
echo $VaeFile = $null
echo $VaeRepo = ""
echo.
echo $LocalVae = Get-ChildItem -Path $ModelFolder -File -ErrorAction SilentlyContinue ^|
echo     Where-Object {
echo         $_.Name -match "(?i)(vae|autoencoder|^ae[\._-]).*\.(safetensors|gguf|ckpt|pth|pt)$"
echo     } ^|
echo     Select-Object -First 1
echo.
echo if ($LocalVae) {
echo     Write-Host
echo     Write-Host "Already exists: $($LocalVae.FullName)"
echo     Write-Host "Skipping Hugging Face VAE discovery/download."
echo.
echo     $VaeFile = [PSCustomObject]@{
echo         path = $LocalVae.Name
echo     }
echo }
echo else {
echo     $VaeCandidate = $UniqueCandidates ^|
echo         Where-Object {
echo             $_.Repo -eq "black-forest-labs/FLUX.2-dev"
echo         } ^|
echo         Select-Object -First 1
echo.
echo     if ($VaeCandidate) {
echo         $VaeFiles = Get-HfFiles $VaeCandidate.Repo $VaeCandidate.Path
echo         $VaeFile = Select-File $VaeFiles "vae" $ModelName ""
echo.
echo         if ($VaeFile) {
echo             $VaeRepo = $VaeCandidate.Repo
echo         }
echo     }
echo.
echo     if (-not $VaeFile) {
echo         throw "Unable to identify the required FLUX.2 VAE."
echo     }
echo }
echo.
echo # ------------------------------------------------
echo # Select the Qwen3 4B GGUF repository.
echo #
echo # Do not select the Comfy-Org safetensors path.
echo # The project is using the GGUF Qwen3 encoder.
echo # ------------------------------------------------
echo.
echo $LlmCandidate = $UniqueCandidates ^|
echo     Where-Object {
echo         $_.Repo -eq "unsloth/Qwen3-4B-GGUF"
echo     } ^|
echo     Select-Object -First 1
echo.
echo if (-not $LlmCandidate) {
echo     throw "The required Qwen3-4B-GGUF repository was not found in the upstream documentation."
echo }
echo.
echo $LlmFile = $null
echo $LlmRepo = ""
echo.
echo $LlmFiles = Get-HfFiles $LlmCandidate.Repo $LlmCandidate.Path
echo $LlmFile = Select-File $LlmFiles "llm" $ModelName $LlmQuant
echo.
echo if (-not $LlmFile) {
echo     throw "Unable to identify a usable $LlmQuant Qwen3 4B GGUF."
echo }
echo.
echo $LlmRepo = $LlmCandidate.Repo
echo.
echo # ------------------------------------------------
echo # FLUX.2-klein does not use CLIP-L, CLIP-G,
echo # or T5-XXL.
echo # ------------------------------------------------
echo.
echo $ClipLFile = $null
echo $ClipLRepo = ""
echo $ClipGFile = $null
echo $ClipGRepo = ""
echo $T5File = $null
echo $T5Repo = ""
echo.
echo $ModelDirRelative = ".\Models\$ModelFolderName"
echo $DiffusionRelative = "$ModelDirRelative\$($DiffusionFile.path.Split("/")[-1])"
echo $VaeRelative = "$ModelDirRelative\$($VaeFile.path.Split("/")[-1])"
echo $LlmRelative = "$ModelDirRelative\$($LlmFile.path.Split("/")[-1])"
echo $ClipLRelative = ""
echo $ClipGRelative = ""
echo $T5Relative = ""
echo.
echo Download-File $DiffusionCandidate.Repo $DiffusionFile.path (
echo     Join-Path $ModelFolder $DiffusionFile.path.Split("/")[-1]
echo )
echo.
echo Download-File $VaeRepo $VaeFile.path (
echo     Join-Path $ModelFolder $VaeFile.path.Split("/")[-1]
echo )
echo.
echo Download-File $LlmRepo $LlmFile.path (
echo     Join-Path $ModelFolder $LlmFile.path.Split("/")[-1]
echo )
echo.
echo $PrimaryFlag = "--diffusion-model"
echo.
echo if (
echo     $Section -match "(?m)(^|[\s`r`n])(-m|--model)\s+" -and
echo     $Section -notmatch "--diffusion-model"
echo ) {
echo     $PrimaryFlag = "-m"
echo }
echo.
echo $Manifest = Join-Path $ModelFolder "model.manifest"
echo $ManifestLines = New-Object System.Collections.Generic.List[string]
echo.
echo $ManifestLines.Add("MODEL_NAME=$ModelName")
echo $ManifestLines.Add("MODEL_DOC=$($SelectedDoc.Name)")
echo $ManifestLines.Add("PRIMARY_FLAG=$PrimaryFlag")
echo $ManifestLines.Add("DIFFUSION_MODEL=$DiffusionRelative")
echo $ManifestLines.Add("DIFFUSION_QUANT=$DiffusionQuant")
echo $ManifestLines.Add("VAE=$VaeRelative")
echo $ManifestLines.Add("LLM=$LlmRelative")
echo $ManifestLines.Add("LLM_QUANT=$LlmQuant")
echo $ManifestLines.Add("CLIP_L=$ClipLRelative")
echo $ManifestLines.Add("CLIP_G=$ClipGRelative")
echo $ManifestLines.Add("T5XXL=$T5Relative")
echo.
echo Set-Content -Path $Manifest -Value $ManifestLines -Encoding ASCII
echo.
echo Write-Host
echo Write-Host "===================================================="
echo Write-Host " LOCAL MODEL MANIFEST CREATED"
echo Write-Host "===================================================="
echo Write-Host $Manifest
echo.
echo Write-Host "Primary model:"
echo Write-Host $DiffusionRelative
echo.
echo Write-Host "Diffusion quantization:"
echo Write-Host $DiffusionQuant
echo.
echo Write-Host "VAE:"
echo Write-Host $VaeRelative
echo.
echo Write-Host "LLM:"
echo Write-Host $LlmRelative
echo.
echo Write-Host "LLM quantization:"
echo Write-Host $LlmQuant
echo.
echo Write-Host "The model is now available to Run-Engine.bat."
goto :eof