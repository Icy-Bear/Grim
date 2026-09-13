$ErrorActionPreference = "Stop"

# Resolve install dir
if ($env:GRIM_DIR) { $InstallDir = $env:GRIM_DIR } else { $InstallDir = "$env:USERPROFILE\.grim" }

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "GRIM requires Node.js 18+ to run." -ForegroundColor Yellow
    Write-Host "Install Node.js from https://nodejs.org" -ForegroundColor Yellow
    exit 1
}

# Check OpenCode
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: OpenCode is not installed." -ForegroundColor Red
    Write-Host "Install OpenCode first: https://opencode.ai" -ForegroundColor Yellow
    exit 1
}

# Locate entry
$Candidates = @(
    "$InstallDir\src\index.js",
    "$PSScriptRoot\..\src\index.js",
    "$PSScriptRoot\src\index.js"
)
$Entry = $null
foreach ($c in $Candidates) {
    if (Test-Path $c) { $Entry = $c; break }
}
# Also try relative to grim.ps1 location when running from repo
if (-not $Entry) {
    $RepoGuess = Join-Path $PSScriptRoot "..\src\index.js"
    if (Test-Path $RepoGuess) { $Entry = $RepoGuess }
}

if (-not $Entry) {
    # Fallback: minimal install — show banner and launch directly
    $PromptFile = "$InstallDir\system-prompt.txt"
    if (-not (Test-Path $PromptFile)) {
        Write-Host "ERROR: system-prompt.txt not found at $PromptFile" -ForegroundColor Red
        Write-Host "Reinstall: irm https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.ps1 | iex" -ForegroundColor Yellow
        exit 1
    }
    Clear-Host
    Write-Host @"

 ██████╗ ██████╗ ██╗███╗   ███╗
██╔════╝ ██╔══██╗██║████╗ ████║
██║  ███╗██████╔╝██║██╔████╔██║
██║   ██║██╔══██╗██║██║╚██╔╝██║
╚██████╔╝██║  ██║██║██║ ╚═╝ ██║
 ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝     ╚═╝

        V I B E   C O D I N G

GRIM:

The problem is yours.
The reasoning is yours.
The code comes after.

Describe the problem in your own words.

"@
    $Prompt = Get-Content $PromptFile -Raw
    opencode --prompt "$Prompt"
    exit $LASTEXITCODE
}

# Forward args to node
$ArgsList = $args
& node $Entry @ArgsList
exit $LASTEXITCODE
