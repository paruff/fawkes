#!/usr/bin/env python3
"""
Validate User Research Repository Structure

This script validates that the user research repository structure is correctly set up
with all required directories, documentation, and configuration files.
"""

import os
import sys
from pathlib import Path


def check_path_exists(path, path_type="file"):
    """Check if a path exists and is of the expected type."""
    if not path.exists():
        return False, f"{path_type.capitalize()} not found: {path}"

    if path_type == "file" and not path.is_file():
        return False, f"Expected file but found directory: {path}"

    if path_type == "directory" and not path.is_dir():
        return False, f"Expected directory but found file: {path}"

    return True, f"✓ {path_type.capitalize()} exists: {path}"


def validate_structure():
    """Validate the user research repository structure."""

    # Get the repository root (script is in scripts/)
    repo_root = Path(__file__).resolve().parent.parent
    research_dir = repo_root / "docs" / "research"

    print("=" * 80)
    print("User Research Repository Structure Validation")
    print("=" * 80)
    print()

    checks = []
    errors = []

    # Check main research directory
    check, msg = check_path_exists(research_dir, "directory")
    checks.append((check, msg))
    if not check:
        print(msg)
        return False

    # Check required directories
    required_dirs = [
        research_dir / "personas",
        research_dir / "interviews",
        research_dir / "journey-maps",
        research_dir / "insights",
        research_dir / "data",
        research_dir / "data" / "raw",
        research_dir / "data" / "processed",
        research_dir / "assets",
        research_dir / "assets" / "images",
        research_dir / "assets" / "videos",
        research_dir / "assets" / "audio",
        research_dir / "assets" / "diagrams",
        research_dir / "templates",
    ]

    print("Checking required directories...")
    for directory in required_dirs:
        check, msg = check_path_exists(directory, "directory")
        checks.append((check, msg))
        if not check:
            errors.append(msg)
        print(f"  {msg}")
    print()

    # Check required documentation files
    required_docs = [
        research_dir / "README.md",
        research_dir / "personas" / "README.md",
        research_dir / "interviews" / "README.md",
        research_dir / "journey-maps" / "README.md",
        research_dir / "insights" / "README.md",
        research_dir / "data" / "README.md",
        research_dir / "assets" / "README.md",
    ]

    print("Checking required documentation...")
    for doc in required_docs:
        check, msg = check_path_exists(doc, "file")
        checks.append((check, msg))
        if not check:
            errors.append(msg)
        print(f"  {msg}")
    print()

    # Check template files
    required_templates = [
        research_dir / "templates" / "persona.md",
        research_dir / "templates" / "interview-guide.md",
        research_dir / "templates" / "journey-map.md",
    ]

    print("Checking template files...")
    for template in required_templates:
        check, msg = check_path_exists(template, "file")
        checks.append((check, msg))
        if not check:
            errors.append(msg)
        print(f"  {msg}")
    print()

    # Check Git LFS configuration
    print("Checking Git LFS configuration...")
    gitattributes = repo_root / ".gitattributes"
    check, msg = check_path_exists(gitattributes, "file")
    checks.append((check, msg))
    if not check:
        errors.append(msg)
    print(f"  {msg}")

    if check:
        # Verify LFS tracking for media files
        with open(gitattributes, "r") as f:
            content = f.read()
            lfs_patterns = ["*.mp4", "*.mp3", "*.mov", "*.wav"]
            for pattern in lfs_patterns:
                if pattern in content and "filter=lfs" in content:
                    print(f"  ✓ LFS tracking configured for {pattern}")
                else:
                    error_msg = f"  ✗ LFS tracking not found for {pattern}"
                    errors.append(error_msg)
                    print(error_msg)
    print()

    # Check .gitkeep files in empty directories
    print("Checking .gitkeep files...")
    gitkeep_dirs = [
        research_dir / "personas",
        research_dir / "interviews",
        research_dir / "journey-maps",
        research_dir / "insights",
        research_dir / "data" / "raw",
        research_dir / "data" / "processed",
        research_dir / "assets" / "images",
        research_dir / "assets" / "videos",
        research_dir / "assets" / "audio",
        research_dir / "assets" / "diagrams",
    ]

    for directory in gitkeep_dirs:
        gitkeep = directory / ".gitkeep"
        check, msg = check_path_exists(gitkeep, "file")
        checks.append((check, msg))
        if not check:
            errors.append(msg)
        print(f"  {msg}")
    print()

    # Summary
    print("=" * 80)
    print("Validation Summary")
    print("=" * 80)
    total_checks = len(checks)
    passed_checks = sum(1 for check, _ in checks if check)
    failed_checks = total_checks - passed_checks

    print(f"Total checks: {total_checks}")
    print(f"Passed: {passed_checks}")
    print(f"Failed: {failed_checks}")
    print()

    if errors:
        print("Errors found:")
        for error in errors:
            print(f"  - {error}")
        print()
        return False
    else:
        print("✓ All validation checks passed!")
        print()
        print("User research repository structure is correctly set up.")
        print()
        print("Next steps:")
        print("  1. Review the main README: docs/research/README.md")
        print("  2. Start creating research artifacts using the templates")
        print("  3. Ensure Git LFS is installed: git lfs install")
        print()
        return True


if __name__ == "__main__":
    success = validate_structure()
    sys.exit(0 if success else 1)
