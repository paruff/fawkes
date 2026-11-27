"""The canary gate must not fail a healthy rollout with no 5xx series or no traffic (#2322)."""

from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
TEMPLATE = ROOT / "platform/apps/python-fawkes-path/python-fawkes-path-analysis-template.yaml"


def _metric() -> dict:
    return yaml.safe_load(TEMPLATE.read_text())["spec"]["metrics"][0]


def test_no_5xx_series_counts_as_zero_errors() -> None:
    numerator = _metric()["provider"]["prometheus"]["query"].split("\n/\n")[0]
    assert "or vector(0)" in numerator


def test_nan_is_inconclusive_not_failed() -> None:
    # With both conditions set, a NaN result (no traffic) matches neither and pauses the rollout.
    metric = _metric()
    assert metric["successCondition"] == "result[0] < {{args.error-rate-threshold}}"
    assert metric["failureCondition"] == "result[0] >= {{args.error-rate-threshold}}"
