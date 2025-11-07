#!/bin/bash
# Setup Git Hooks for ShadowsocksX-NG
# Automatically installs pre-commit hook for code quality checks

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "[*] Setting up Git hooks..."

# Pre-commit hook
cat > "$GIT_HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for ShadowsocksX-NG
# Runs SwiftLint checks on staged files before commit

set -e

echo "[>] Running SwiftLint..."

# Check if SwiftLint is installed
if ! command -v swiftlint &> /dev/null; then
    echo "Error: SwiftLint not found. Please install it:"
    echo "  brew install swiftlint"
    exit 1
fi

# Get list of staged Swift files
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=d | grep "\.swift$" || true)

if [ -z "$SWIFT_FILES" ]; then
    echo "[i] No Swift files to lint"
    exit 0
fi

echo "Checking files:"
echo "$SWIFT_FILES"

# Run SwiftLint
# Process files one at a time to handle spaces properly
echo "$SWIFT_FILES" | xargs swiftlint lint --quiet --config .swiftlint.yml
if [ $? -eq 0 ]; then
    echo "[+] SwiftLint passed"
else
    echo "[-] SwiftLint found issues. Please fix them before committing."
    echo "   Run 'swiftlint autocorrect' to fix some issues automatically."
    exit 1
fi

echo "[+] Pre-commit checks passed"
EOF

chmod +x "$GIT_HOOKS_DIR/pre-commit"

echo "[+] Git hooks installed successfully"
echo ""
echo "[i] Note: Run 'swiftlint autocorrect' to automatically fix some issues"
