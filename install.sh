#!/usr/bin/env bash

set -e

REPO="https://raw.githubusercontent.com/Icy-Bear/Grim/main"

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

# Installation directories
INSTALL_DIR="$HOME/.grim"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"

echo "Downloading GRIM..."

curl -fsSL "$REPO/linux/grim.sh" > "$INSTALL_DIR/grim.sh"
curl -fsSL "$REPO/system-prompt.txt" > "$INSTALL_DIR/system-prompt.txt"

chmod +x "$INSTALL_DIR/grim.sh"

# Create executable wrapper
cat > "$BIN_DIR/grim" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/grim.sh" "\$@"
EOF

chmod +x "$BIN_DIR/grim"

echo
echo "✓ GRIM installed"
echo

# Warn if BIN_DIR not on PATH
case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *)
        echo "NOTE: $BIN_DIR is not on your PATH."
        echo "Add it with:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        echo
        ;;
esac

echo "Run it with:"
echo
echo "    grim"
echo

exec "$BIN_DIR/grim"
