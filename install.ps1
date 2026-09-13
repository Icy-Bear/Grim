$ErrorActionPreference = "Stop"

$Repo = "https://raw.githubusercontent.com/Icy-Bear/Grim/main"
$InstallDir = "$env:USERPROFILE\.grim"
$BinDir = "$env:USERPROFILE\.local\bin"

Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Cyan

# Check OpenCode
if (-not (Get-Command opencode -ErrorAction SilentlyContinue)) {
    Write-Host ""
    Write-Host "ERROR: OpenCode is not installed." -ForegroundColor Red
    Write-Host "GRIM requires OpenCode to run."
    Write-Host "Install OpenCode first: https://opencode.ai" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

Write-Host "OpenCode found" -ForegroundColor Green

# Create directories
New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

Write-Host "Installing GRIM..." -ForegroundColor Cyan

# Download GRIM files
Invoke-WebRequest -Uri "$Repo/windows/grim.ps1" -OutFile "$InstallDir\grim.ps1"
Invoke-WebRequest -Uri "$Repo/system-prompt.txt" -OutFile "$InstallDir\system-prompt.txt"

Write-Host "GRIM installed" -ForegroundColor Green

# Create wrapper in BinDir and ensure BinDir is on PATH
$WrapperPath = "$BinDir\grim.ps1"
$WrapperContent = @"
`$InstallDir = "`$env:USERPROFILE\.grim"
`$PromptFile = "`$InstallDir\system-prompt.txt"
if (-not (Test-Path `$PromptFile)) {
    Write-Host "ERROR: system-prompt.txt not found at `$PromptFile" -ForegroundColor Red
    exit 1
}
`$Prompt = Get-Content `$PromptFile -Raw
opencode --prompt "`$Prompt"
"@
Set-Content -Path $WrapperPath -Value $WrapperContent -Encoding UTF8

# Also create a .cmd shim so `grim` works from cmd.exe
$CmdShim = "$BinDir\grim.cmd"
Set-Content -Path $CmdShim -Value "@echo off`r`npowershell -ExecutionPolicy Bypass -File `"%~dp0grim.ps1`" %*`r`n" -Encoding ASCII

# Add BinDir to user PATH if not already present
$UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($UserPath -notlike "*$BinDir*") {
    [Environment]::SetEnvironmentVariable("Path", "$UserPath;$BinDir", "User")
    $env:Path += ";$BinDir"
    Write-Host "Added $BinDir to PATH (restart terminal to apply)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Run it with:" -ForegroundColor Cyan
Write-Host "    grim" -ForegroundColor White
Write-Host ""

# Start GRIM via installed script
& "$InstallDir\grim.ps1"
