#!/usr/bin/env bash

set -e

GRIM_DIR="$HOME/.grim"

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

PROMPT="$(cat "$GRIM_DIR/system-prompt.txt")"

exec opencode --prompt "$PROMPT"
