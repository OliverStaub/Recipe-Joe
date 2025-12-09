# Makefile for RecipeJoe
# Installs git hooks for automated testing

.PHONY: help install-hooks

# Default target
help:
	@echo "RecipeJoe - Available Commands"
	@echo ""
	@echo "  make install-hooks    Install git hooks (pre-commit & pre-merge-commit)"
	@echo "  make help             Show this help message"
	@echo ""
	@echo "Note: Use xcodebuild or Xcode to run tests"

# Install git hooks
install-hooks:
	@echo "📦 Installing git hooks..."
	@chmod +x scripts/pre-commit
	@cp scripts/pre-commit .git/hooks/pre-commit
	@chmod +x .git/hooks/pre-commit
	@echo "✅ Pre-commit hook installed!"
	@chmod +x scripts/pre-merge-commit
	@cp scripts/pre-merge-commit .git/hooks/pre-merge-commit
	@chmod +x .git/hooks/pre-merge-commit
	@echo "✅ Pre-merge-commit hook installed!"
	@echo ""
	@echo "Hooks will run tests:"
	@echo "  - pre-commit: before each commit on main/develop"
	@echo "  - pre-merge-commit: before merge commits on main/develop"
	@echo ""
	@echo "To bypass: git commit --no-verify / git merge --no-verify"
