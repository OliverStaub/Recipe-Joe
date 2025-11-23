# Makefile for RecipeJoe
# Installs git hooks for automated testing

.PHONY: help install-hooks

# Default target
help:
	@echo "RecipeJoe - Available Commands"
	@echo ""
	@echo "  make install-hooks    Install pre-commit git hook"
	@echo "  make help             Show this help message"
	@echo ""
	@echo "Note: Use xcodebuild or Xcode to run tests"

# Install git hooks
install-hooks:
	@echo "📦 Installing git hooks..."
	@chmod +x scripts/pre-commit
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Pre-commit hook installed successfully!"
	@echo ""
	@echo "The hook will run tests before each commit."
	@echo "To bypass: git commit --no-verify"
