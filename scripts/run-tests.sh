#!/bin/bash
# NASBox Build Tests
# Validates the build output

set -e

echo "Running NASBox build tests..."

ERRORS=0

# Test 1: Check directory structure
echo -n "Testing directory structure... "
REQUIRED_DIRS=(
    "base-system/kernel"
    "base-system/init"
    "docker-support"
    "gui/components"
    "gui/themes"
    "nas-features/storage"
    "nas-features/networking"
    "scripts"
    "docs"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "FAIL: Missing directory $dir"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "OK"

# Test 2: Check required files
echo -n "Testing required files... "
REQUIRED_FILES=(
    "README.md"
    "Makefile"
    "LICENSE"
    "base-system/kernel/config"
    "base-system/kernel/config-x86_64"
    "base-system/kernel/config-aarch64"
    "docker-support/daemon.json"
    "gui/index.html"
    "scripts/build-rootfs.sh"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "FAIL: Missing file $file"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "OK"

# Test 3: Shell script syntax
echo -n "Testing shell script syntax... "
for script in scripts/*.sh; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "FAIL: Syntax error in $script"
        ERRORS=$((ERRORS + 1))
    fi
done
echo "OK"

# Test 4: JSON syntax
echo -n "Testing JSON syntax... "
for json in docker-support/*.json; do
    if [ -f "$json" ]; then
        if ! python3 -c "import json; json.load(open('$json'))" 2>/dev/null; then
            echo "FAIL: Invalid JSON in $json"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done
echo "OK"

# Test 5: HTML syntax (basic)
echo -n "Testing HTML files... "
for html in gui/*.html; do
    if [ -f "$html" ]; then
        if ! grep -q "<!DOCTYPE html>" "$html"; then
            echo "WARN: Missing DOCTYPE in $html"
        fi
    fi
done
echo "OK"

# Test 6: CSS syntax (basic)
echo -n "Testing CSS files... "
for css in gui/themes/*.css; do
    if [ -f "$css" ]; then
        # Basic check for balanced braces
        open_braces=$(grep -o '{' "$css" | wc -l)
        close_braces=$(grep -o '}' "$css" | wc -l)
        if [ "$open_braces" -ne "$close_braces" ]; then
            echo "WARN: Unbalanced braces in $css"
        fi
    fi
done
echo "OK"

# Test 7: JavaScript syntax (basic)
echo -n "Testing JavaScript files... "
for js in gui/components/*.js; do
    if [ -f "$js" ]; then
        if command -v node &> /dev/null; then
            if ! node --check "$js" 2>/dev/null; then
                echo "WARN: Potential issue in $js"
            fi
        fi
    fi
done
echo "OK"

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo "All tests passed!"
    exit 0
else
    echo "Tests completed with $ERRORS error(s)"
    exit 1
fi
