#!/usr/bin/env bash

set -e

GRIM_DIR="$HOME/.grim"
PROMPT_FILE="$GRIM_DIR/system-prompt.txt"

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "ERROR: system-prompt.txt not found at $PROMPT_FILE" >&2
    echo "Reinstall GRIM: curl -fsSL https://raw.githubusercontent.com/Icy-Bear/Grim/main/install.sh | bash" >&2
    exit 1
fi

# Check for OpenCode
if ! command -v opencode >/dev/null 2>&1; then
    echo "ERROR: OpenCode is not installed." >&2
    echo "Install OpenCode first: https://opencode.ai" >&2
    exit 1
fi

clear

cat <<'EOF'

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

EOF

PROMPT="$(cat "$PROMPT_FILE")"

exec opencode --prompt "$PROMPT"
