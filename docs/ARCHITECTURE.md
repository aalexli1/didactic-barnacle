# Architecture Overview

This repository hosts a minimal, multi-language scaffold:
- iOS SwiftUI client app (under `ios/`)
- Python tooling and shared modules (under `tools/` and `src/`)
- Tests and CI-friendly configuration (under `tests/` and `pyproject.toml`)

See `specs.md` for the product requirements and milestones.

## Layout
- `ios/`: Placeholder for the SwiftUI app sources and Xcode project.
- `src/`: Python package namespace for reusable code.
- `tools/`: Standalone utility scripts (e.g., repo access validator).
- `tests/`: Python tests (scaffold and future unit tests).
- `scripts/`: Helper shell scripts for local dev tasks.
- `docs/`: Documentation and design notes.

## Next Steps
- Initialize the iOS app (Xcode project) under `ios/` per `specs.md`.
- Add API client code in `src/` for orchestrator interactions.
- Extend tests to cover functionality as it lands.

