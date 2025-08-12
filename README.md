# Project Scaffold

A clean, language-agnostic project skeleton with sensible defaults for configuration, scripts, and docs. Customize it for Node.js, Python, or your preferred stack.

## Quick Start

1. Copy env and config samples:
   - `cp .env.example .env`
   - `cp config/app.example.yaml config/app.yaml` (then edit values)
2. Make scripts executable:
   - `make setup`
3. Run the app (tries Node or Python by convention):
   - `make run`

## Project Structure

```
.
├─ config/                 # App configuration files
│  └─ app.example.yaml     # Example app config (copy to app.yaml)
├─ docs/                   # Documentation
│  └─ README.md            # Docs index
├─ scripts/                # Project automation scripts
│  ├─ dev.sh               # Dev runner (Node or Python by convention)
│  └─ setup.sh             # One-time setup tasks
├─ src/                    # Application source code
│  └─ index.js             # Minimal entry point (Node-friendly)
├─ tests/                  # Test specs (add your framework)
│  └─ placeholder.test.md  # Notes on writing tests
├─ .editorconfig           # Editor consistency settings
├─ .env.example            # Example environment variables
├─ .gitattributes          # Git attributes (line endings, etc.)
├─ .gitignore              # Ignore build artifacts and local files
├─ Makefile                # Common project tasks
└─ README.md               # You are here
```

## Conventions

- Config lives in `config/` as YAML. Duplicate `app.example.yaml` to `app.yaml` for local overrides.
- Environment variables live in `.env` (never commit secrets).
- `scripts/` holds portable bash scripts for common tasks.
- `make` targets wrap scripts for a simple, consistent UX.

## Config and Env

- App config: `config/app.example.yaml` includes placeholders like `${VAR:-default}`. Standard YAML loaders don't expand these. Either:
  - Preprocess into `config/app.yaml` using a template step in your build/deploy pipeline; or
  - Resolve environment variables in your application code at startup and ignore `${...}` in YAML.
- `.env` loading: `scripts/dev.sh` loads `.env` safely by parsing literal `KEY=VALUE` pairs (with optional quotes). It does not execute shell code or support complex shell expansions.
- Shell compatibility: Scripts are written for `bash`. If invoked via `sh`, they will re-exec under `bash` automatically.

## Next Steps

- Replace `src/index.js` with your actual app (Node, Python, etc.).
- Pick and configure a test runner (e.g., Vitest/Jest, Pytest, etc.).
- Add CI later if needed.
