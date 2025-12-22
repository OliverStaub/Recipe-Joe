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

# Function to run tests with fail-fast
run_tests() {
    local scheme=$1
    local test_type=$2
    local test_target=$3

    echo -e "${YELLOW}Running $test_type...${NC}"
    echo ""

    # Create temp file for output and failure flag
    local temp_output=$(mktemp)
    local failure_flag=$(mktemp)
    echo "0" > "$failure_flag"

    # Build xcodebuild command
    local xcode_cmd="xcodebuild test -project $XCODE_PROJECT -scheme $scheme -destination 'platform=iOS Simulator,name=iPhone Air' -parallel-testing-enabled NO -test-timeouts-enabled YES"
    if [ -n "$test_target" ]; then
        xcode_cmd="$xcode_cmd -only-testing:$test_target"
    fi

    # Run xcodebuild in background
    eval "$xcode_cmd" > "$temp_output" 2>&1 &
    local xcode_pid=$!

    # Monitor output for failures
    tail -f "$temp_output" 2>/dev/null &
    local tail_pid=$!

    # Wait and check for failures
    while kill -0 $xcode_pid 2>/dev/null; do
        if grep -q "failed (" "$temp_output" 2>/dev/null; then
            echo ""
            echo -e "${RED}❌ Test failure detected - stopping immediately${NC}"
            echo "1" > "$failure_flag"
            kill $xcode_pid 2>/dev/null || true
            kill $tail_pid 2>/dev/null || true
            # Also kill any simulator processes
            pkill -f "xcodebuild.*$scheme" 2>/dev/null || true
            break
        fi
        sleep 0.5
    done

    # Wait for xcodebuild to finish
    wait $xcode_pid 2>/dev/null || true
    kill $tail_pid 2>/dev/null || true

    # Check if we detected a failure
    local failure_detected=$(cat "$failure_flag")
    local test_succeeded=0
    if grep -q "TEST SUCCEEDED" "$temp_output" 2>/dev/null; then
        test_succeeded=1
    fi

    # Cleanup
    rm -f "$temp_output" "$failure_flag"

    echo ""

    if [ "$failure_detected" = "1" ]; then
        echo -e "${RED}✗ $test_type failed${NC}"
        echo ""
        return 1
    elif [ "$test_succeeded" = "1" ]; then
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
