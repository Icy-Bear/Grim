# Grim

Strict Vibe Coding Assessment — the AI won't code until you reason.

## Install

**Linux / macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.ps1 | iex
```

Requires [OpenCode](https://opencode.ai) — the installer will error if it's missing.

## Run

```bash
grim
```

> The problem is yours. The reasoning is yours. The code comes after.

## What it does

Wraps `opencode --prompt` with a strict assessment system prompt (`system-prompt.txt`) that enforces:

1. **Understanding** → 2. **Approach** → 3. **Algorithm** → 4. **Code** — no skipping steps.

## Structure

- `linux/grim.sh` — launcher for Linux/macOS
- `windows/grim.ps1` — launcher for Windows
- `system-prompt.txt` — assessment instructions
- `install.sh` / `install.ps1` — installers

## Manual install

```bash
mkdir -p ~/.grim ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/linux/grim.sh -o ~/.grim/grim.sh
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/system-prompt.txt -o ~/.grim/system-prompt.txt
chmod +x ~/.grim/grim.sh
ln -sf ~/.grim/grim.sh ~/.local/bin/grim
```
