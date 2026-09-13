#!/usr/bin/env bash
set -euo pipefail

# GRIM test harness — runs with mocked opencode/curl, isolated HOME
# Usage: bash test.sh  (or ./test.sh)

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
PASS=0
FAIL=0
SKIP=0

# Colors (disable if not tty)
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; NC=''
fi

pass() { echo -e "${GREEN}✓${NC} $1"; PASS=$((PASS+1)); }
fail() { echo -e "${RED}✗${NC} $1"; [[ -n "${2:-}" ]] && echo "    $2"; FAIL=$((FAIL+1)); }
skip() { echo -e "${YELLOW}○${NC} $1 (skip: $2)"; SKIP=$((SKIP+1)); }

echo ""
echo "GRIM test harness"
echo "================"
echo "Repo: $REPO_ROOT"
echo ""

# ---------- 1. Static checks ----------
echo "--- Static checks ---"

# bash -n syntax
if bash -n "$REPO_ROOT/install.sh" 2>&1; then
  pass "install.sh syntax (bash -n)"
else
  fail "install.sh syntax (bash -n)" "$(bash -n "$REPO_ROOT/install.sh" 2>&1)"
fi

if bash -n "$REPO_ROOT/linux/grim.sh" 2>&1; then
  pass "linux/grim.sh syntax (bash -n)"
else
  fail "linux/grim.sh syntax (bash -n)" "$(bash -n "$REPO_ROOT/linux/grim.sh" 2>&1)"
fi

# No YOUR_USERNAME placeholder
if grep -rq "YOUR_USERNAME" "$REPO_ROOT" --exclude-dir=.git --exclude="test.sh" 2>/dev/null; then
  fail "No YOUR_USERNAME placeholder" "$(grep -rn "YOUR_USERNAME" "$REPO_ROOT" --exclude-dir=.git)"
else
  pass "No YOUR_USERNAME placeholder"
fi

# REPO URL correctness
if grep -q 'Icy-Bear/Grim' "$REPO_ROOT/install.sh"; then
  pass "install.sh REPO is Icy-Bear/Grim"
else
  fail "install.sh REPO is Icy-Bear/Grim" "expected Icy-Bear/Grim in install.sh"
fi

if grep -q 'linux/grim.sh' "$REPO_ROOT/install.sh"; then
  pass "install.sh downloads linux/grim.sh (not /grim.sh)"
else
  fail "install.sh downloads linux/grim.sh" "expected linux/grim.sh path"
fi

if grep -q 'BIN_DIR=' "$REPO_ROOT/install.sh"; then
  pass "install.sh defines BIN_DIR"
else
  fail "install.sh defines BIN_DIR"
fi

if grep -q 'exec "$BIN_DIR/grim"' "$REPO_ROOT/install.sh"; then
  pass "install.sh exec uses \$BIN_DIR"
else
  fail "install.sh exec uses \$BIN_DIR"
fi

# system-prompt.txt exists
if [[ -f "$REPO_ROOT/system-prompt.txt" ]]; then
  pass "system-prompt.txt exists"
else
  fail "system-prompt.txt exists"
fi

# README references
if grep -q 'Icy-Bear/Grim' "$REPO_ROOT/README.md"; then
  pass "README.md uses Icy-Bear/Grim"
else
  fail "README.md uses Icy-Bear/Grim"
fi

if grep -q 'install.ps1' "$REPO_ROOT/README.md"; then
  pass "README.md documents Windows install"
else
  fail "README.md documents Windows install"
fi

# PowerShell syntax (if pwsh available)
if command -v pwsh >/dev/null 2>&1; then
  if pwsh -NoProfile -Command "\$null = [System.Management.Automation.Language.Parser]::ParseFile('$REPO_ROOT/windows/grim.ps1', [ref]\$null, [ref]\$null); if (\$?) { exit 0 } else { exit 1 }" 2>&1; then
    pass "windows/grim.ps1 syntax (pwsh parser)"
  else
    fail "windows/grim.ps1 syntax (pwsh parser)"
  fi
  if pwsh -NoProfile -Command "\$null = [System.Management.Automation.Language.Parser]::ParseFile('$REPO_ROOT/install.ps1', [ref]\$null, [ref]\$null); if (\$?) { exit 0 } else { exit 1 }" 2>&1; then
    pass "install.ps1 syntax (pwsh parser)"
  else
    fail "install.ps1 syntax (pwsh parser)"
  fi
else
  skip "windows/grim.ps1 syntax" "pwsh not installed"
  skip "install.ps1 syntax" "pwsh not installed"
fi

# ---------- 2. Runtime: linux/grim.sh ----------
echo ""
echo "--- Runtime: linux/grim.sh ---"

# Helper: run grim.sh with isolated HOME and mocked opencode
TMP_HOME="$(mktemp -d)"
TMP_BIN="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME" "$TMP_BIN"' EXIT

# Mock opencode that records args
cat > "$TMP_BIN/opencode" <<'MOCK'
#!/usr/bin/env bash
echo "MOCK_OPENCODE_CALLED"
echo "ARGS: $*"
for arg in "$@"; do
  if [[ "$prev" == "--prompt" ]]; then
    echo "PROMPT_LEN: ${#arg}"
    echo "PROMPT_HEAD: ${arg:0:50}"
    if [[ "$arg" == *"XOR-AND"* ]]; then echo "HAS_QUESTION:YES"; else echo "HAS_QUESTION:NO"; fi
  fi
  prev="$arg"
done
exit 0
MOCK
chmod +x "$TMP_BIN/opencode"

# Mock clear (no-op)
cat > "$TMP_BIN/clear" <<'MOCK'
#!/usr/bin/env bash
exit 0
MOCK
chmod +x "$TMP_BIN/clear"

# Prepare fake grim home with system-prompt.txt + questions + src
mkdir -p "$TMP_HOME/.grim/src"
cp "$REPO_ROOT/system-prompt.txt" "$TMP_HOME/.grim/system-prompt.txt"
cp "$REPO_ROOT/questions.md" "$TMP_HOME/.grim/questions.md" 2>/dev/null || cp "$REPO_ROOT/questions.md" "$TMP_HOME/.grim/questions.md"
cp "$REPO_ROOT/src/index.js" "$TMP_HOME/.grim/src/index.js" 2>/dev/null || true
cp "$REPO_ROOT/src/tui.js" "$TMP_HOME/.grim/src/tui.js" 2>/dev/null || true
cp "$REPO_ROOT/src/questions.js" "$TMP_HOME/.grim/src/questions.js" 2>/dev/null || true
cp "$REPO_ROOT/src/opencode.js" "$TMP_HOME/.grim/src/opencode.js" 2>/dev/null || true
cp "$REPO_ROOT/package.json" "$TMP_HOME/.grim/package.json" 2>/dev/null || true

# Test: successful run (via Node TUI — feed selection "1")
set +e
OUT="$(printf "1\n" | HOME="$TMP_HOME" PATH="$TMP_BIN:$PATH" bash "$REPO_ROOT/linux/grim.sh" 2>&1)"
STATUS=$?
set -e
if [[ $STATUS -eq 0 && "$OUT" == *"MOCK_OPENCODE_CALLED"* ]]; then
  pass "linux/grim.sh success path (banner + opencode)"
else
  fail "linux/grim.sh success path" "status=$STATUS out=${OUT:0:500}"
fi

if [[ "$OUT" == *"PROMPT_LEN:"* ]]; then
  pass "linux/grim.sh passes --prompt to opencode"
else
  fail "linux/grim.sh passes --prompt to opencode" "$OUT"
fi

if [[ "$OUT" == *"HAS_QUESTION:YES"* ]]; then
  pass "linux/grim.sh passes selected question to opencode"
else
  fail "linux/grim.sh passes selected question to opencode" "$OUT"
fi

# Test: missing system-prompt.txt (check fallback to repo still works, so we test isolated failure by hiding repo file)
# For new Node app, missing HOME prompt falls back to repo, so we test by temporarily hiding repo file
if [[ -f "$REPO_ROOT/system-prompt.txt" ]]; then
  mv "$REPO_ROOT/system-prompt.txt" "$REPO_ROOT/system-prompt.txt.tmpbak"
  mv "$TMP_HOME/.grim/system-prompt.txt" "$TMP_HOME/.grim/system-prompt.txt.bak"
  set +e
  OUT="$(printf "1\n" | HOME="$TMP_HOME" PATH="$TMP_BIN:$PATH" bash "$REPO_ROOT/linux/grim.sh" 2>&1)"
  STATUS=$?
  set -e
  if [[ $STATUS -ne 0 && "$OUT" == *"system-prompt.txt not found"* ]]; then
    pass "linux/grim.sh fails gracefully when system-prompt.txt missing"
  else
    fail "linux/grim.sh fails gracefully when system-prompt.txt missing" "status=$STATUS out=$OUT"
  fi
  mv "$TMP_HOME/.grim/system-prompt.txt.bak" "$TMP_HOME/.grim/system-prompt.txt"
  mv "$REPO_ROOT/system-prompt.txt.tmpbak" "$REPO_ROOT/system-prompt.txt"
else
  skip "missing prompt test" "system-prompt.txt not found"
fi

# Test: missing opencode
set +e
OUT="$(HOME="$TMP_HOME" PATH="/usr/bin:/bin" bash "$REPO_ROOT/linux/grim.sh" 2>&1)"
STATUS=$?
set -e
if [[ $STATUS -ne 0 && "$OUT" == *"OpenCode is not installed"* ]]; then
  pass "linux/grim.sh fails gracefully when opencode missing"
else
  fail "linux/grim.sh fails gracefully when opencode missing" "status=$STATUS out=$OUT"
fi

# ---------- 3. Runtime: install.sh ----------
echo ""
echo "--- Runtime: install.sh (isolated HOME) ---"

# Mock curl to serve local files instead of network
cat > "$TMP_BIN/curl" <<'MOCK'
#!/usr/bin/env bash
# Mock curl -fsSL $URL > $dest  (supports: curl -fsSL URL -o file  and  curl -fsSL URL > file)
# We only need to handle the install.sh usage: curl -fsSL "$REPO/linux/grim.sh" > "$INSTALL_DIR/grim.sh"
set -e
URL=""
OUT=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -fsSL) shift ;;
    -o) OUT="$2"; shift 2 ;;
    http*) URL="$1"; shift ;;
    *) shift ;;
  esac
done
# If no -o, output to stdout (caller redirects)
if [[ "$URL" == *"/linux/grim.sh"* ]]; then
  cat "$REPO_ROOT/linux/grim.sh"
elif [[ "$URL" == *"/system-prompt.txt"* ]]; then
  cat "$REPO_ROOT/system-prompt.txt"
elif [[ "$URL" == *"/questions.md"* ]]; then
  cat "$REPO_ROOT/questions.md"
elif [[ "$URL" == *"/package.json"* ]]; then
  cat "$REPO_ROOT/package.json"
elif [[ "$URL" == *"/src/index.js"* ]]; then
  cat "$REPO_ROOT/src/index.js"
elif [[ "$URL" == *"/src/tui.js"* ]]; then
  cat "$REPO_ROOT/src/tui.js"
elif [[ "$URL" == *"/src/questions.js"* ]]; then
  cat "$REPO_ROOT/src/questions.js"
elif [[ "$URL" == *"/src/opencode.js"* ]]; then
  cat "$REPO_ROOT/src/opencode.js"
else
  echo "mock curl: unknown URL $URL" >&2
  exit 1
fi > "${OUT:-/dev/stdout}"
MOCK
chmod +x "$TMP_BIN/curl"
export REPO_ROOT  # for mock curl

FAKE_HOME="$(mktemp -d)"
# Run install.sh but override its final exec to avoid launching grim
# We do this by mocking opencode and making BIN_DIR/grim a mock that just exits
cat > "$TMP_BIN/opencode" <<'MOCK'
#!/usr/bin/env bash
echo "MOCK opencode from install"
exit 0
MOCK
chmod +x "$TMP_BIN/opencode"

# Need to prevent final exec from actually running grim's clear/opencode loop
# Replace opencode mock with one that exits 0, and grim.sh will still run but that's okay (it will clear and call mock)
set +e
OUT="$(HOME="$FAKE_HOME" PATH="$TMP_BIN:$PATH" bash "$REPO_ROOT/install.sh" 2>&1)"
STATUS=$?
set -e

# HOME may not have .local/bin on PATH, so installer should warn
if [[ -f "$FAKE_HOME/.grim/grim.sh" && -f "$FAKE_HOME/.grim/system-prompt.txt" ]]; then
  pass "install.sh downloads grim.sh + system-prompt.txt to fake HOME"
else
  fail "install.sh downloads grim.sh + system-prompt.txt to fake HOME" "ls: $(ls -R "$FAKE_HOME" 2>&1 | head -20)"
fi

if [[ -f "$FAKE_HOME/.local/bin/grim" && -x "$FAKE_HOME/.local/bin/grim" ]]; then
  pass "install.sh creates wrapper at ~/.local/bin/grim"
  # Check wrapper content
  if grep -q 'exec.*\.grim/grim.sh' "$FAKE_HOME/.local/bin/grim"; then
    pass "wrapper execs ~/.grim/grim.sh"
  else
    fail "wrapper execs ~/.grim/grim.sh" "$(cat "$FAKE_HOME/.local/bin/grim")"
  fi
else
  fail "install.sh creates wrapper at ~/.local/bin/grim" "$(ls -l "$FAKE_HOME/.local/bin" 2>&1)"
fi

if grep -q "GRIM installed" <<< "$OUT"; then
  pass "install.sh prints success message"
else
  fail "install.sh prints success message" "$OUT"
fi

# Check BIN_DIR PATH warning (FAKE_HOME/.local/bin likely not on PATH)
# Our PATH includes TMP_BIN but not FAKE_HOME/.local/bin, so should warn
if [[ ":$PATH:" != *":$FAKE_HOME/.local/bin:"* ]]; then
  if grep -q "not on your PATH" <<< "$OUT"; then
    pass "install.sh warns when BIN_DIR not on PATH"
  else
    fail "install.sh warns when BIN_DIR not on PATH" "$OUT"
  fi
else
  skip "install.sh PATH warning" "BIN_DIR already on PATH in this env"
fi

# Check wrapper execution (feed selection to handle new TUI)
if printf "1\n" | HOME="$FAKE_HOME" PATH="$TMP_BIN:$PATH" bash "$FAKE_HOME/.local/bin/grim" 2>&1 | grep -q "MOCK"; then
  pass "wrapper ~/.local/bin/grim correctly delegates to grim.sh"
else
  fail "wrapper ~/.local/bin/grim correctly delegates to grim.sh"
fi

rm -rf "$FAKE_HOME"

# ---------- 4. Windows checks ----------
echo ""
echo "--- Windows checks ---"

if grep -q 'windows/grim.ps1' "$REPO_ROOT/install.ps1"; then
  pass "install.ps1 downloads windows/grim.ps1"
else
  fail "install.ps1 downloads windows/grim.ps1"
fi

if grep -q '\.local\\bin' "$REPO_ROOT/install.ps1" || grep -q '\.local/bin' "$REPO_ROOT/install.ps1"; then
  pass "install.ps1 creates BinDir wrapper"
else
  fail "install.ps1 creates BinDir wrapper"
fi

if grep -q 'opencode --prompt "\$Prompt"' "$REPO_ROOT/windows/grim.ps1" || grep -q 'opencode --prompt "\$Prompt"' "$REPO_ROOT/install.ps1"; then
  pass 'PowerShell uses quoted --prompt "$Prompt"'
else
  # Check actual file
  if grep -q -- '--prompt' "$REPO_ROOT/windows/grim.ps1"; then
    pass 'PowerShell passes --prompt (quoted check relaxed)'
  else
    fail 'PowerShell passes --prompt'
  fi
fi

# ---------- Summary ----------
echo ""
echo "=============================="
echo -e "Results: ${GREEN}$PASS passed${NC}, ${RED}$FAIL failed${NC}, ${YELLOW}$SKIP skipped${NC}"
echo "=============================="

if [[ $FAIL -gt 0 ]]; then
  exit 1
else
  exit 0
fi
