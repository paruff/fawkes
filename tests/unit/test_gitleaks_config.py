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


def test_no_syntax_that_ci_gitleaks_ignores() -> None:
    # The shared security workflow pins gitleaks 8.24.3, which silently ignores
    # top-level [[allowlists]]. Scope allowlists with [[rules.allowlists]].
    assert "allowlists" not in tomllib.loads(CONFIG.read_text())


# #684: the unit-test runner has no gitleaks binary, so these run locally only.
needs_gitleaks = pytest.mark.skipif(shutil.which("gitleaks") is None, reason="gitleaks not installed")


def scan(root: Path, path: str, line: str) -> subprocess.CompletedProcess[str]:
    target = root / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(line + "\n")
    return subprocess.run(
        ["gitleaks", "dir", str(root), "-c", str(CONFIG), "--no-banner", "--redact"],
        capture_output=True,
        text=True,
        check=False,
    )


@needs_gitleaks
@pytest.mark.parametrize(
    "path",
    ["app.py", "tests/test_app.py", ".kube.local.yaml", "README.md", "a-sealed.yaml"],
)
def test_planted_token_is_found(tmp_path: Path, path: str) -> None:
    # Assembled at runtime so this file is not itself a finding.
    token = "ghp_" + "aB3dE5fG7hJ9kL1mN3pQ5rS7tU9vW1xY3zA5"
    result = scan(tmp_path, path, f'token: "{token}"')

    assert result.returncode == 1, result.stderr


@needs_gitleaks
@pytest.mark.parametrize(
    ("path", "template"),
    [
        # A placeholder must be the whole value, not just part of it.
        # A private key, because gitleaks' own stopwords skip most other probes.
        (
            "app.pem",
            "-----BEGIN RSA " + "PRIVATE KEY-----\ntest-password-123\n{0}{0}{0}\n-----END RSA " + "PRIVATE KEY-----",
        ),
        # Only ciphertext is excused in a sealed manifest.
        ("a-sealed.yaml", 'password: "{}"'),
        # Only the one known default login is excused in this script.
        (
            "scripts/validate-golden-path-observability.sh",
            "curl " + '-u "admin:admin{}" https://example.com',
        ),
    ],
)
def test_allowlists_do_not_hide_real_values(tmp_path: Path, path: str, template: str) -> None:
    value = "q7Rz2Lx9" + "Vb4Nk8Tw3Hm6Pc1Jd5Fg0Sy"

    result = scan(tmp_path, path, template.format(value))

    assert result.returncode == 1, result.stderr
