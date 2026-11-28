"""The DORA verification plane passes only when Prometheus has the service's values (#2312)."""

import json
import os
import shutil
import subprocess
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[2]
pytestmark = pytest.mark.skipif(not shutil.which("jq"), reason="jq not installed")


@pytest.mark.parametrize(("result", "exit_code"), [([{"value": [0, "1.5"]}], 0), ([], 1)])
def test_plane_follows_prometheus(tmp_path: Path, result: list, exit_code: int) -> None:
    (tmp_path / "scripts").mkdir()
    script = tmp_path / "scripts" / "validate-golden-path-dora.sh"
    shutil.copy(ROOT / "scripts" / script.name, script)
    kubectl = tmp_path / "kubectl"
    kubectl.write_text(f"#!/bin/sh\ncat <<'JSON'\n{json.dumps({'data': {'result': result}})}\nJSON\n")
    kubectl.chmod(0o755)
    env = {**os.environ, "PATH": f"{tmp_path}:{os.environ['PATH']}"}
    run = subprocess.run(["bash", str(script)], cwd=tmp_path, env=env, capture_output=True, text=True, check=False)
    assert run.returncode == exit_code, run.stdout + run.stderr
