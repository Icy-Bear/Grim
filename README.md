# Grim

Strict Vibe Coding Assessment — the AI won't code until you reason.

```
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
```

## Install

**Linux / macOS**

```bash
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.sh | bash
```

**Windows (PowerShell)**

```powershell
irm https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.ps1 | iex
```

Requires:

- **Node.js 18+** — https://nodejs.org
- **OpenCode** — https://opencode.ai (installer errors if missing)

## Run

```bash
grim
```

The TUI lets you browse and select a coding problem, then launches OpenCode with GRIM's strict assessment system prompt + the selected problem.

Other commands:

```bash
grim --list    # list available problems
grim --check   # check OpenCode installation
grim --help    # help
```

> The problem is yours. The reasoning is yours. The code comes after.

## What it does

```
Run GRIM
   ↓
GRIM TUI  (browse problems)
   ↓
Choose coding problem
   ↓
Start OpenCode
   ↓
OpenCode receives GRIM's system prompt + selected problem
   ↓
Candidate begins the assessment
```

Wraps `opencode --prompt` with a strict assessment system prompt (`system-prompt.txt`) that enforces:

1. **Understanding** → 2. **Approach** → 3. **Algorithm** → 4. **Code** — no skipping steps.

The candidate must explain reasoning before the AI generates code. `solve this` without reasoning is rejected.

## Structure

```
GRIM
├── src/                 # application (Node.js, cross-platform)
│   ├── index.js         # CLI entry (bin: grim)
│   ├── tui.js           # terminal UI
│   ├── questions.js     # questions parser
│   └── opencode.js      # OpenCode detection + launcher
├── questions.md         # assessment content (human-editable)
├── system-prompt.txt    # AI behavior / source of truth
├── linux/grim.sh        # launcher for Linux/macOS
├── windows/grim.ps1     # launcher for Windows
├── install.sh           # installer (Linux/macOS)
└── install.ps1          # installer (Windows)
```

## Questions

Problems are stored in `questions.md` (also supports `questions.txt`). Each problem starts with:

```markdown
## Title

Full problem statement, constraints, examples...
```

Edit `questions.md` without touching code — add `## New Problem` sections freely. The TUI picks them up automatically.

Included problems:

- **XOR-AND Inversions**
- Token Bucket Rate Limiter
- Log Compaction — Eventual Consistency
- Dependency Build Order
- Sliding Window Aggregator
- Concurrent Counter — Lost Updates

## Manual install

```bash
mkdir -p ~/.grim/src ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/linux/grim.sh -o ~/.grim/grim.sh
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/system-prompt.txt -o ~/.grim/system-prompt.txt
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/questions.md -o ~/.grim/questions.md
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/package.json -o ~/.grim/package.json
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/src/index.js -o ~/.grim/src/index.js
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/src/tui.js -o ~/.grim/src/tui.js
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/src/questions.js -o ~/.grim/src/questions.js
curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/src/opencode.js -o ~/.grim/src/opencode.js
chmod +x ~/.grim/grim.sh
ln -sf ~/.grim/grim.sh ~/.local/bin/grim
```

Or from this repo via npm:

```bash
npm link   # makes `grim` available globally
grim --list
```

## Philosophy

Local-first, lightweight. No accounts, auth, DB, cloud, telemetry, or custom LLM APIs. GRIM is the assessment environment around your existing OpenCode installation.
