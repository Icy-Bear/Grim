$ErrorActionPreference = "Stop"

$PromptFile = "$env:USERPROFILE\.grim\system-prompt.txt"

if (-not (Test-Path $PromptFile)) {
    Write-Host "ERROR: system-prompt.txt not found at $PromptFile" -ForegroundColor Red
    Write-Host "Reinstall GRIM: irm https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.ps1 | iex" -ForegroundColor Yellow
    exit 1
}

if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: OpenCode is not installed." -ForegroundColor Red
    Write-Host "Install OpenCode first: https://opencode.ai" -ForegroundColor Yellow
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
