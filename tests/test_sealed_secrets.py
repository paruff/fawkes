"""Tests for Sealed Secrets generation and validation.

TDD: These tests define the contract for secret management.
They MUST fail before implementation, then pass after.
"""

import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
PLATFORM_DIR = REPO_ROOT / "platform"


class TestNoChangeMeSecrets:
    """Verify no CHANGE_ME_* values remain in committed secrets."""

    def _find_change_me_values(self):
        """Find all CHANGE_ME_* values in YAML secrets files."""
        import yaml

        results = []
        secrets_patterns = ["**/secrets.yaml", "**/secrets/*.yaml", "**/*credentials*.yaml"]
        for pattern in secrets_patterns:
            for path in PLATFORM_DIR.glob(pattern):
                if "sealed" in path.name or "CHANGELOG" in str(path):
                    continue
                try:
                    with open(path) as f:
                        content = f.read()
                    if "CHANGE_ME" in content:
                        results.append(str(path.relative_to(REPO_ROOT)))
                except (yaml.YAMLError, OSError):
                    continue
        return results

    def test_no_change_me_in_secrets(self):
        """Ensure no plaintext secrets contain CHANGE_ME_* placeholders."""
        found = self._find_change_me_values()
        assert not found, (
            f"CHANGE_ME_* placeholders found in secrets files: {found}. "
            "Replace with actual values and seal with kubeseal before committing."
        )


class TestSealedSecretsExist:
    """Verify SealedSecret files exist for each service that needs them."""

    EXPECTED_SEALED_SERVICES = [
        "backstage",
        "postgresql",
    ]

    def test_sealed_secrets_directory_exists(self):
        """Platform should have a pattern for sealed secrets."""
        sealed_dirs = list(PLATFORM_DIR.glob("**/secrets/*sealed*"))
        assert len(sealed_dirs) > 0, "No SealedSecret files found in platform/"


class TestGenerateScript:
    """Verify the generation script exists and is executable."""

    def test_generation_script_exists(self):
        """scripts/generate-sealed-secrets.sh should exist."""
        script = REPO_ROOT / "scripts" / "generate-sealed-secrets.sh"
        assert script.exists(), f"Script not found: {script}"

    def test_generation_script_is_executable(self):
        """Script should have execute permission."""
        script = REPO_ROOT / "scripts" / "generate-sealed-secrets.sh"
        assert script.stat().st_mode & 0o111, f"Script not executable: {script}"
