from pathlib import Path


def test_scaffold_directories_exist():
    root = Path(__file__).resolve().parents[1]
    expected_dirs = [
        root / "src",
        root / "tests",
        root / "tools",
        root / "docs",
        root / "scripts",
        root / "ios",
    ]
    for d in expected_dirs:
        assert d.exists() and d.is_dir(), f"Missing directory: {d}"


def test_basic_files_exist():
    root = Path(__file__).resolve().parents[1]
    for f in [root / ".gitignore", root / ".editorconfig", root / "pyproject.toml", root / "README.md"]:
        assert f.exists(), f"Missing file: {f}"

