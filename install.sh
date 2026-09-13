#!/usr/bin/env bash

set -e

REPO="https://raw.githubusercontent.com/YOUR_USERNAME/grim/main"

echo
echo "Installing GRIM..."
echo

# Check for OpenCode
if ! command -v opencode >/dev/null 2>&1; then
    echo "ERROR: OpenCode is not installed."
    echo
    echo "GRIM requires OpenCode to run."
    echo "Install OpenCode first:"
    echo "https://opencode.ai"
    echo
    exit 1
fi

echo "✓ OpenCode found"

# Installation directory
INSTALL_DIR="$HOME/.grim"

mkdir -p "$INSTALL_DIR"

echo "Downloading GRIM..."

curl -fsSL "$REPO/grim.sh" > "$INSTALL_DIR/grim.sh"
curl -fsSL "$REPO/system-prompt.txt" > "$INSTALL_DIR/system-prompt.txt"

chmod +x "$INSTALL_DIR/grim.sh"

# Create executable
mkdir -p "$HOME/.local/bin"

cat > "$HOME/.local/bin/grim" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/grim.sh" "\$@"
EOF

chmod +x "$HOME/.local/bin/grim"

echo
echo "✓ GRIM installed"
echo
echo "Run it with:"
echo
echo "    grim"
echo
