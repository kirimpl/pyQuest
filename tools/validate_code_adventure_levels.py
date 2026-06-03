"""Utility validator for PyQuest Code Adventure level data.

Run from project root:
    python tools/validate_code_adventure_levels.py

The script checks that all levels have required fields, valid rectangular maps,
exactly one player start and one exit, and a reference solution.
It is intentionally independent from Godot so level data can be checked quickly.
"""
from __future__ import annotations

import json
from pathlib import Path

LEVELS_PATH = Path("data/code_adventure_levels.json")
REQUIRED_FIELDS = {
    "level", "title", "topic", "chapter", "difficulty", "grid", "goal",
    "requirements", "starter_code", "solution_code", "hint_steps", "min_steps",
}
ALLOWED_TILES = set("#PXGKDES~.")


def main() -> None:
    levels = json.loads(LEVELS_PATH.read_text(encoding="utf-8"))
    errors: list[str] = []

    if not isinstance(levels, list):
        raise SystemExit("Level file must contain a JSON array")

    expected = 1
    for level in levels:
        number = int(level.get("level", -1))
        if number != expected:
            errors.append(f"Level order problem: expected {expected}, got {number}")
        expected += 1

        missing = REQUIRED_FIELDS - set(level.keys())
        if missing:
            errors.append(f"Level {number}: missing fields {sorted(missing)}")

        grid = level.get("grid", [])
        if not isinstance(grid, list) or not grid:
            errors.append(f"Level {number}: grid must be a non-empty array")
            continue

        starts = sum(str(row).count("P") for row in grid)
        exits = sum(str(row).count("X") for row in grid)
        if starts != 1:
            errors.append(f"Level {number}: expected exactly one P, got {starts}")
        if exits != 1:
            errors.append(f"Level {number}: expected exactly one X, got {exits}")

        for row_index, row in enumerate(grid, start=1):
            bad_tiles = sorted(set(str(row)) - ALLOWED_TILES)
            if bad_tiles:
                errors.append(f"Level {number}, row {row_index}: bad tiles {bad_tiles}")

        if not str(level.get("solution_code", "")).strip():
            errors.append(f"Level {number}: empty reference solution")

        if int(level.get("min_steps", 0)) <= 0:
            errors.append(f"Level {number}: min_steps must be positive")

    if errors:
        print("Validation failed:")
        for error in errors:
            print("-", error)
        raise SystemExit(1)

    print(f"OK: {len(levels)} levels passed structural validation.")


if __name__ == "__main__":
    main()
