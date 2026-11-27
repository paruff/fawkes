"""Guard: .gitleaks.toml must keep gitleaks' default rules switched on (issue #684).

A custom config replaces the default rules. Without `useDefault` every scan that
loads it passes while checking nothing.
"""

import shutil
import subprocess
import tomllib
from pathlib import Path

import pytest

CONFIG = Path(__file__).resolve().parents[2] / ".gitleaks.toml"


def test_default_rules_are_enabled() -> None:
    assert tomllib.loads(CONFIG.read_text()).get("extend", {}).get("useDefault") is True


@pytest.mark.skipif(shutil.which("gitleaks") is None, reason="gitleaks not installed")
@pytest.mark.parametrize(
    "path",
    ["app.py", "tests/test_app.py", ".kube.local.yaml", "README.md", "a-sealed.yaml"],
)
def test_planted_token_is_found(tmp_path: Path, path: str) -> None:
    # Assembled at runtime so this file is not itself a finding.
    token = "ghp_" + "aB3dE5fG7hJ9kL1mN3pQ5rS7tU9vW1xY3zA5"
    target = tmp_path / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(f'token: "{token}"\n')

    result = subprocess.run(
        ["gitleaks", "dir", str(tmp_path), "-c", str(CONFIG), "--no-banner", "--redact"],
        capture_output=True,
        text=True,
        check=False,
    )

    assert result.returncode == 1, result.stderr
