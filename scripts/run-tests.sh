#!/bin/bash

# Run Tests Script for RecipeJoe
# Executes the same tests as the pre-commit hook
# Usage: ./scripts/run-tests.sh

set -e

echo "🧪 Running RecipeJoe Tests..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the project root directory
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
cd "$PROJECT_ROOT"

# Check if we can find the xcodeproj
XCODE_PROJECT="RecipeJoe.xcodeproj"
if [ ! -d "$XCODE_PROJECT" ]; then
    echo -e "${RED}❌ Could not find $XCODE_PROJECT${NC}"
    exit 1
fi

# Function to run tests
run_tests() {
    local scheme=$1
    local test_type=$2
    local test_target=$3

    echo -e "${YELLOW}Running $test_type...${NC}"
    echo ""

    # Run xcodebuild and let it output directly to terminal
    local exit_code=0
    if [ -n "$test_target" ]; then
        xcodebuild test \
            -project "$XCODE_PROJECT" \
            -scheme "$scheme" \
            -destination 'platform=iOS Simulator,name=iPhone Air' \
            -only-testing:"$test_target" || exit_code=$?
    else
        xcodebuild test \
            -project "$XCODE_PROJECT" \
            -scheme "$scheme" \
            -destination 'platform=iOS Simulator,name=iPhone Air' || exit_code=$?
    fi

    echo ""

    # Check if xcodebuild succeeded
    if [ $exit_code -eq 0 ]; then
        echo -e "${GREEN}✓ $test_type passed${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ $test_type failed${NC}"
        echo ""
        return 1
    fi
}

# Run unit tests
if ! run_tests "RecipeJoe" "Unit Tests" "RecipeJoeTests"; then
    echo -e "${RED}❌ Unit tests failed.${NC}"
    exit 1
fi

# Run UI tests
if ! run_tests "RecipeJoe" "UI Tests" "RecipeJoeUITests"; then
    echo -e "${RED}❌ UI tests failed.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All tests passed!${NC}"
echo ""

exit 0
