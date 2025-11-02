#!/bin/bash
# Setup Git Hooks for ShadowsocksX-NG
# ????????????? pre-commit ???? ??? ???????? ???????? ????

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GIT_HOOKS_DIR="$PROJECT_ROOT/.git/hooks"

echo "?? Setting up Git hooks..."

# Pre-commit hook
cat > "$GIT_HOOKS_DIR/pre-commit" << 'EOF'
#!/bin/bash
# Pre-commit hook for ShadowsocksX-NG
# ????????? SwiftLint ????? ?????? ????????

set -e

echo "?? Running SwiftLint..."

# ?????????, ?????????? ?? SwiftLint
if ! command -v swiftlint &> /dev/null; then
    echo "??  SwiftLint not found. Installing..."
    brew install swiftlint
fi

# ????????? SwiftLint ?????? ?? staged ??????
SWIFT_FILES=$(git diff --cached --name-only --diff-filter=d | grep "\.swift$" || true)

if [ -z "$SWIFT_FILES" ]; then
    echo "? No Swift files to lint"
    exit 0
fi

echo "Checking files:"
echo "$SWIFT_FILES"

# ????????? SwiftLint
if swiftlint lint --quiet --config .swiftlint.yml $SWIFT_FILES; then
    echo "? SwiftLint passed"
else
    echo "? SwiftLint found issues. Please fix them before committing."
    echo "   Run 'swiftlint autocorrect' to fix some issues automatically."
    exit 1
fi

echo "? Pre-commit checks passed"
EOF

chmod +x "$GIT_HOOKS_DIR/pre-commit"

echo "? Git hooks installed successfully"
echo ""
echo "?? Note: Run 'swiftlint autocorrect' to automatically fix some issues"
