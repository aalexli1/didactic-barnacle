SHELL := /bin/bash

.PHONY: help setup run test lint fmt clean

help:
	@echo "Available targets:"
	@echo "  setup  - One-time setup tasks"
	@echo "  run    - Run the app via scripts/dev.sh"
	@echo "  test   - Run tests (placeholder)"
	@echo "  lint   - Lint sources (placeholder)"
	@echo "  fmt    - Format sources (placeholder)"
	@echo "  clean  - Clean build artifacts"

setup:
	@./scripts/setup.sh

run:
	@./scripts/dev.sh

test:
	@echo "No test runner configured yet."

lint:
	@echo "No linter configured yet."

fmt:
	@echo "No formatter configured yet."

clean:
	@rm -rf dist build coverage .cache .pytest_cache || true
