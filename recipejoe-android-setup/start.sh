#!/bin/bash
set -e

echo "🤖 RecipeJoe Android - Autonomous Claude Code Builder"
echo "=================================================="
echo ""

# Check if ANTHROPIC_API_KEY is set
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "❌ Error: ANTHROPIC_API_KEY environment variable not set"
    echo ""
    echo "Please set your API key:"
    echo "  export ANTHROPIC_API_KEY='your-api-key-here'"
    echo ""
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Error: docker-compose not found"
    echo "Please install Docker Compose"
    exit 1
fi

# Check if recipejoe folder exists
if [ ! -d "./recipejoe" ]; then
    echo "⚠️  Warning: ./recipejoe folder not found"
    echo ""
    read -p "Enter path to your RecipeJoe project: " PROJECT_PATH
    if [ ! -d "$PROJECT_PATH" ]; then
        echo "❌ Error: Directory $PROJECT_PATH does not exist"
        exit 1
    fi
    # Create symlink
    ln -s "$PROJECT_PATH" ./recipejoe
    echo "✅ Linked $PROJECT_PATH to ./recipejoe"
fi

# Build Docker image
echo ""
echo "🐳 Building Docker image..."
docker-compose build

# Start container
echo ""
echo "🚀 Starting container..."
docker-compose up -d

# Wait for container to be ready
echo "⏳ Waiting for container to be ready..."
sleep 3

# Show instructions
echo ""
echo "✅ Container is running!"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 NEXT STEPS:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Option 1: 🤖 Voll Autonom (YOLO Mode)"
echo "  docker exec -it recipejoe-claude bash -c 'cd /workspace/recipejoe && claude --dangerously-skip-permissions --max-turns 200 \"\$(cat /workspace/android-task.md)\" 2>&1 | tee android-build.log'"
echo ""
echo "Option 2: 🤝 Semi-Autonom (Auto-Accept Mode)"
echo "  docker exec -it recipejoe-claude bash"
echo "  Dann: cd /workspace/recipejoe && claude"
echo "  Shift+Tab drücken bis 'auto-accept edit on'"
echo "  Initial task kopieren: cat /workspace/android-task.md"
echo ""
echo "Option 3: 🎮 Interaktiv (Volle Kontrolle)"
echo "  docker exec -it recipejoe-claude bash"
echo "  Dann: cd /workspace/recipejoe && claude"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 MONITORING:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Logs:             docker-compose logs -f"
echo "Build log:        tail -f recipejoe/android-build.log"
echo "Git commits:      watch -n 5 'cd recipejoe && git log --oneline -10'"
echo "Enter container:  docker exec -it recipejoe-claude bash"
echo "Stop:             docker-compose down"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Ask if user wants to start autonomous mode now
read -p "Start autonomous mode now? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "🚀 Starting autonomous build..."
    echo "📝 Output will be logged to recipejoe/android-build.log"
    echo ""
    echo "⚠️  This will run for up to 200 turns"
    echo "💰 Estimated cost: $50-150 depending on complexity"
    echo "🛑 Stop anytime: Ctrl+C or 'docker-compose down'"
    echo ""
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo ""
        echo "🎯 Launching autonomous mode..."
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        # Start autonomous mode
        docker exec -it recipejoe-claude bash -c "cd /workspace/recipejoe && claude --dangerously-skip-permissions --max-turns 200 \"\$(cat /workspace/android-task.md)\" 2>&1 | tee android-build.log"
    else
        echo "Cancelled."
    fi
else
    echo "Container is ready. Use one of the options above to start."
fi
