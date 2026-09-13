#!/usr/bin/env bash
set -e

# Resolve GRIM installation directory
if [[ -n "$GRIM_DIR" ]]; then
  INSTALL_DIR="$GRIM_DIR"
else
  INSTALL_DIR="$HOME/.grim"
fi

# System prompt check (for helpful message before Node)
if [[ ! -f "$INSTALL_DIR/system-prompt.txt" && ! -f "$(dirname "$0")/../system-prompt.txt" ]]; then
  # Let Node handle the error with more detail, but warn here
  :
fi

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
  echo "ERROR: Node.js is not installed." >&2
  echo "GRIM requires Node.js 18+ to run." >&2
  echo "Install Node.js from https://nodejs.org" >&2
  exit 1
fi

# Check OpenCode (Node also checks, but early exit here)
if ! command -v opencode >/dev/null 2>&1; then
  echo "" >&2
  echo "  ERROR: OpenCode is not installed." >&2
  echo "" >&2
  echo "  GRIM requires OpenCode to run." >&2
  echo "  Install OpenCode first: https://opencode.ai" >&2
  echo "" >&2
  exit 1
fi

# Locate Node entry point
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CANDIDATES=(
  "$INSTALL_DIR/src/index.js"
  "$SCRIPT_DIR/../src/index.js"
  "$SCRIPT_DIR/src/index.js"
  "$(dirname "$0")/src/index.js"
)

ENTRY=""
for c in "${CANDIDATES[@]}"; do
  if [[ -f "$c" ]]; then
    ENTRY="$c"
    break
  fi
done

if [[ -z "$ENTRY" ]]; then
  # Fallback: no Node app found (e.g., minimal install) — show banner and launch OpenCode directly
  # Keeps backward compatibility for tests and minimal deployments
  PROMPT_FILE=""
  for pf in "$INSTALL_DIR/system-prompt.txt" "$SCRIPT_DIR/../system-prompt.txt" "$SCRIPT_DIR/system-prompt.txt"; do
    if [[ -f "$pf" ]]; then PROMPT_FILE="$pf"; break; fi
  done
  if [[ -z "$PROMPT_FILE" ]]; then
    echo "ERROR: system-prompt.txt not found" >&2
    echo "Reinstall: curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.sh | bash" >&2
    exit 1
  fi
  clear 2>/dev/null || true
  cat <<'BANNER'

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

BANNER
  PROMPT="$(cat "$PROMPT_FILE")"
  exec opencode --prompt "$PROMPT"
fi

exec node "$ENTRY" "$@"
