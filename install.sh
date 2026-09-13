#!/usr/bin/env bash
set -e

REPO="https://raw.githubusercontent.com/Icy-Bear/Grim/main"

echo
echo "Installing GRIM..."
echo

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    echo "ERROR: Node.js is not installed."
    echo
    echo "GRIM requires Node.js 18+ to run."
    echo "Install Node.js from https://nodejs.org"
    echo
    exit 1
fi

NODE_MAJOR="$(node -p "process.versions.node.split('.')[0]")"
if [[ "$NODE_MAJOR" -lt 18 ]]; then
    echo "ERROR: Node.js 18+ required (found v$(node -v))"
    echo "Update Node.js from https://nodejs.org"
    exit 1
fi

# Check OpenCode
if ! command -v opencode >/dev/null 2>&1; then
    echo "ERROR: OpenCode is not installed."
    echo
    echo "GRIM requires OpenCode to run."
    echo "Install OpenCode first:"
    echo "https://opencode.ai"
    echo
    exit 1
fi

echo "✓ Node.js $(node -v) found"
echo "✓ OpenCode found"

INSTALL_DIR="$HOME/.grim"
BIN_DIR="$HOME/.local/bin"

mkdir -p "$INSTALL_DIR"
mkdir -p "$BIN_DIR"
mkdir -p "$INSTALL_DIR/src"

echo "Downloading GRIM..."

curl -fsSL "$REPO/linux/grim.sh" -o "$INSTALL_DIR/grim.sh"
curl -fsSL "$REPO/system-prompt.txt" -o "$INSTALL_DIR/system-prompt.txt"
curl -fsSL "$REPO/questions.md" -o "$INSTALL_DIR/questions.md"
curl -fsSL "$REPO/package.json" -o "$INSTALL_DIR/package.json"
curl -fsSL "$REPO/src/index.js" -o "$INSTALL_DIR/src/index.js"
curl -fsSL "$REPO/src/tui.js" -o "$INSTALL_DIR/src/tui.js"
curl -fsSL "$REPO/src/questions.js" -o "$INSTALL_DIR/src/questions.js"
curl -fsSL "$REPO/src/opencode.js" -o "$INSTALL_DIR/src/opencode.js"

chmod +x "$INSTALL_DIR/grim.sh"

cat > "$BIN_DIR/grim" <<EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/grim.sh" "\$@"
EOF
chmod +x "$BIN_DIR/grim"

echo
echo "✓ GRIM installed to $INSTALL_DIR"
echo

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
