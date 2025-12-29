#!/bin/bash
set -e

echo "RecipeJoe Android - Claude Code Builder"
echo "========================================"
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"
echo ""

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    echo "Error: docker compose not found"
    echo "Please install Docker Desktop"
    exit 1
fi

# Verify we're in the right place
if [ ! -f "$PROJECT_ROOT/CLAUDE.md" ]; then
    echo "Error: CLAUDE.md not found in project root"
    echo "Make sure this folder is inside the RecipeJoe project"
    exit 1
fi

# Build Docker image
echo ""
echo "Building Docker image (this may take a few minutes first time)..."
cd "$SCRIPT_DIR"
docker compose build

# Start container
echo ""
echo "Starting container..."
docker compose up -d

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 3

# Show instructions
echo ""
echo "Container is running!"
echo ""
echo "============================================================"
echo "STEP 1: LOGIN TO CLAUDE (First time only)"
echo "============================================================"
echo ""
echo "Run these commands:"
echo ""
echo "  docker exec -it recipejoe-claude claude login"
echo ""
echo "This will give you a URL and code to authorize in your browser."
echo "Your Max subscription login will be saved for future sessions."
echo ""
echo "============================================================"
echo "STEP 2: START WORKING"
echo "============================================================"
echo ""
echo "Interactive mode (recommended):"
echo "  docker exec -it recipejoe-claude bash"
echo "  cd /workspace/RecipeJoe"
echo "  claude"
echo ""
echo "Then paste the task:"
echo "  cat /workspace/android-task.md"
echo ""
echo "============================================================"
echo "MONITORING"
echo "============================================================"
echo ""
echo "Enter container:  docker exec -it recipejoe-claude bash"
echo "Git commits:      watch -n 5 'git -C $PROJECT_ROOT log --oneline -10'"
echo "Stop:             docker-compose down"
echo ""
echo "============================================================"
echo ""

# Ask if user wants to login now
read -p "Login to Claude now? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo ""
    echo "Starting Claude login..."
    echo "Follow the instructions to authorize with your Max subscription."
    echo ""
    docker exec -it recipejoe-claude claude login

    echo ""
    echo "Login complete! You can now start Claude:"
    echo ""
    echo "  docker exec -it recipejoe-claude bash"
    echo "  cd /workspace/RecipeJoe && claude"
    echo ""
else
    echo "Container is ready. Run 'docker exec -it recipejoe-claude claude login' when ready."
fi
