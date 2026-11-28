"""DevLake is decommissioned (#2312): nothing deploys it or sends to it."""

import subprocess
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
THIS = "tests/unit/test_devlake_removed.py"


def test_no_devlake_files_remain() -> None:
    names = subprocess.run(["git", "ls-files"], cwd=ROOT, capture_output=True, text=True, check=True).stdout
    left = [
        n
        for n in names.splitlines()
        if "devlake" in n.lower() and n.startswith(("platform/", "scripts/", "tests/")) and n != THIS
        if (ROOT / n).exists()
    ]
    assert not left, f"DevLake files remain: {left}"


def test_alertmanager_routes_only_to_receivers_that_exist() -> None:
    app = yaml.safe_load((ROOT / "platform/apps/prometheus/prometheus-application.yaml").read_text())
    config = yaml.safe_load(app["spec"]["source"]["helm"]["values"])["alertmanager"]["config"]
    receivers = {r["name"] for r in config["receivers"]}
    routed = {config["route"]["receiver"], *(r["receiver"] for r in config["route"]["routes"])}
    assert routed <= receivers
    assert not [name for name in receivers if "devlake" in name]
