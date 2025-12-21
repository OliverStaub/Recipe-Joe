#!/bin/bash

# Run Supabase Edge Function Tests
# This script runs unit and integration tests for the edge functions
#
# Usage:
#   ./scripts/run-edge-tests.sh          # Run all tests
#   ./scripts/run-edge-tests.sh unit     # Run only unit tests (no network)
#   ./scripts/run-edge-tests.sh integration # Run integration tests (requires network)
#
# Prerequisites:
#   - Deno installed
#   - For integration tests: .env file with Supabase credentials in supabase/functions/tests/
#     or environment variables set

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TESTS_DIR="$PROJECT_ROOT/supabase/functions/tests"

echo -e "${BLUE}🧪 Running Supabase Edge Function Tests${NC}"
echo ""

# Check if Deno is installed
if ! command -v deno &> /dev/null; then
    echo -e "${RED}❌ Deno is not installed${NC}"
    echo "Install Deno: https://deno.land/#installation"
    exit 1
fi

# Check if tests directory exists
if [ ! -d "$TESTS_DIR" ]; then
    echo -e "${RED}❌ Tests directory not found: $TESTS_DIR${NC}"
    exit 1
fi

cd "$TESTS_DIR"

# Parse command line argument
TEST_TYPE="${1:-all}"

run_unit_tests() {
    echo -e "${YELLOW}Running unit tests (no network required)...${NC}"
    if deno test --allow-read --allow-env video-detector-test.ts; then
        echo -e "${GREEN}✓ Unit tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Unit tests failed${NC}"
        return 1
    fi
}

run_integration_tests() {
    echo -e "${YELLOW}Running integration tests (requires network and Supabase)...${NC}"

    # Check for .env file or required environment variables
    if [ ! -f ".env" ] && [ -z "$SUPABASE_URL" ]; then
        echo -e "${YELLOW}⚠️  No .env file found and SUPABASE_URL not set${NC}"
        echo "Create supabase/functions/tests/.env with:"
        echo "  SUPABASE_URL=https://your-project.supabase.co"
        echo "  SUPABASE_ANON_KEY=your-anon-key"
        echo "  SUPABASE_SERVICE_ROLE_KEY=your-service-role-key"
        echo "  TEST_USER_EMAIL=test@example.com"
        echo "  TEST_USER_PASSWORD=your-test-password"
        echo ""
        echo -e "${YELLOW}Skipping integration tests...${NC}"
        return 0
    fi

    if deno test --allow-all recipe-import-test.ts; then
        echo -e "${GREEN}✓ Integration tests passed${NC}"
        return 0
    else
        echo -e "${RED}✗ Integration tests failed${NC}"
        return 1
    fi
}

case "$TEST_TYPE" in
    unit)
        run_unit_tests
        ;;
    integration)
        run_integration_tests
        ;;
    all)
        echo ""
        run_unit_tests
        UNIT_RESULT=$?
        echo ""
        run_integration_tests
        INTEGRATION_RESULT=$?
        echo ""

        if [ $UNIT_RESULT -eq 0 ] && [ $INTEGRATION_RESULT -eq 0 ]; then
            echo -e "${GREEN}✅ All edge function tests passed!${NC}"
            exit 0
        else
            echo -e "${RED}❌ Some edge function tests failed${NC}"
            exit 1
        fi
        ;;
    *)
        echo "Usage: $0 [unit|integration|all]"
        exit 1
        ;;
esac
