$ErrorActionPreference = "Stop"

$Repo = "https://raw.githubusercontent.com/Icy-Bear/Grim/main"
$InstallDir = "$env:USERPROFILE\.grim"
$BinDir = "$env:USERPROFILE\.local\bin"

Write-Host ""
Write-Host "Checking dependencies..." -ForegroundColor Cyan

# Check Node.js
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Node.js is not installed." -ForegroundColor Red
    Write-Host "GRIM requires Node.js 18+ to run."
    Write-Host "Install Node.js from https://nodejs.org" -ForegroundColor Yellow
    exit 1
}
$NodeVer = node --version
Write-Host "Node.js $NodeVer found" -ForegroundColor Green

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
New-Item -ItemType Directory -Force -Path "$InstallDir\src" | Out-Null
New-Item -ItemType Directory -Force -Path $BinDir | Out-Null

Write-Host "Installing GRIM..." -ForegroundColor Cyan

Invoke-WebRequest -Uri "$Repo/windows/grim.ps1" -OutFile "$InstallDir\grim.ps1"
Invoke-WebRequest -Uri "$Repo/system-prompt.txt" -OutFile "$InstallDir\system-prompt.txt"
Invoke-WebRequest -Uri "$Repo/questions.md" -OutFile "$InstallDir\questions.md"
Invoke-WebRequest -Uri "$Repo/package.json" -OutFile "$InstallDir\package.json"
Invoke-WebRequest -Uri "$Repo/src/index.js" -OutFile "$InstallDir\src\index.js"
Invoke-WebRequest -Uri "$Repo/src/tui.js" -OutFile "$InstallDir\src\tui.js"
Invoke-WebRequest -Uri "$Repo/src/questions.js" -OutFile "$InstallDir\src\questions.js"
Invoke-WebRequest -Uri "$Repo/src/opencode.js" -OutFile "$InstallDir\src\opencode.js"

Write-Host "GRIM installed to $InstallDir" -ForegroundColor Green

# Create wrapper in BinDir
$WrapperPath = "$BinDir\grim.ps1"
$WrapperContent = @"
`$InstallDir = "`$env:USERPROFILE\.grim"
& "`$InstallDir\grim.ps1" @args
"@
Set-Content -Path $WrapperPath -Value $WrapperContent -Encoding UTF8

$CmdShim = "$BinDir\grim.cmd"
Set-Content -Path $CmdShim -Value "@echo off`r`npowershell -ExecutionPolicy Bypass -File `"%USERPROFILE%\.grim\grim.ps1`" %*`r`n" -Encoding ASCII

# Add BinDir to PATH
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

& "$InstallDir\grim.ps1"
