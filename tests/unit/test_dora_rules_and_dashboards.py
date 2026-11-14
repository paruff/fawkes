"""Keep DORA recording rules, deployed dashboards and Grafana datasources in sync.

Known gaps are listed as constants and asserted for EXACT equality: a new drift
fails the test, and so does fixing a gap without deleting its entry.
"""

import json
import re
from collections.abc import Iterator
from pathlib import Path
from typing import Any

import yaml

ROOT = Path(__file__).resolve().parents[2]
REFERENCE_RULES = "platform/apps/prometheus/rules/dora.yml"
PROM_APP = "platform/apps/prometheus/prometheus-application.yaml"
DASHBOARDS_DIR = "platform/apps/grafana-dashboards"

# Tracked in paruff/fawkes#2310: in the reference copy, missing from the live rule map.
KNOWN_MISSING_FROM_LIVE = {
    "dora:fawkes_repo_deployment_frequency:rate30d",
    "dora:fawkes_repo_lead_time_hours:avg30d",
}
KNOWN_ALERTS_MISSING_FROM_LIVE: set[str] = set()

# Tracked in paruff/fawkes#2310: queried by a deployed dashboard, produced by nothing in fawkes.
# dora_* gauges come only from uFawkesObs dora-api; the two records are the gap above.
KNOWN_UNPRODUCED_SERIES = {
    "dora:fawkes_repo_deployment_frequency:rate30d",
    "dora:fawkes_repo_lead_time_hours:avg30d",
    "dora_cfr_pct",
    "dora_deployment_frequency_per_week",
    "dora_fdrt_p50_hours",
    "dora_lead_time_p50_hours",
    "dora_lead_time_p95_hours",
    "dora_rework_rate_pct",
}

# Tracked in paruff/fawkes#2310: dashboard datasource uid that no manifest provisions.
KNOWN_UNPROVISIONED_UIDS = {"ufawkesres-postgres"}

# Series fawkes does not produce itself; every entry is used by a live or reference rule.
EXTERNAL_SERIES = {
    "argocd_app_sync_total",  # Argo CD controller metrics
    "argocd_app_info",  # Argo CD controller metrics
    "tekton_pipelines_controller_pipelinerun_duration_seconds_bucket",  # Tekton controller
    "ALERTS_FOR_STATE",  # Prometheus itself, from the ArgoCDAppDegraded alert
    "fawkes_repo_deployment_frequency_per_day",  # services/dora-metrics/app/main.py
    "fawkes_repo_lead_time_hours",  # services/dora-metrics/app/main.py
}

# The chart provisions these implicitly (kube-prometheus-stack sidecar); not verifiable from manifests.
IMPLICIT_DATASOURCE_UIDS = {"prometheus", "alertmanager"}

PROMQL_WORDS = {
    "sum", "avg", "min", "max", "count", "rate", "increase", "irate", "histogram_quantile",
    "last_over_time", "avg_over_time", "max_over_time", "min_over_time", "sum_over_time",
    "count_over_time", "stddev_over_time", "absent", "absent_over_time", "vector", "scalar",
    "time", "clamp_min", "clamp_max", "label_replace", "label_join", "by", "without", "on",
    "ignoring", "group_left", "group_right", "or", "and", "unless", "bool", "offset", "topk",
    "bottomk", "abs", "ceil", "floor", "round", "changes", "delta", "deriv", "resets", "sort",
    "sort_desc",
}  # fmt: skip


def _rules(root: Path, ref: bool) -> list[dict[str, Any]]:
    if ref:
        groups = yaml.safe_load((root / REFERENCE_RULES).read_text())["groups"]
        return [r for g in groups for r in g["rules"]]
    app = yaml.safe_load((root / PROM_APP).read_text())
    values = yaml.safe_load(app["spec"]["source"]["helm"]["values"])  # values is a YAML string
    rule_map = _find_key(values, "additionalPrometheusRulesMap")
    return [r for m in rule_map.values() for g in m["groups"] for r in g["rules"]]


def _find_key(obj: Any, key: str) -> Any:
    if isinstance(obj, dict):
        if key in obj:
            return obj[key]
        for v in obj.values():
            if (found := _find_key(v, key)) is not None:
                return found
    return None


def reference_records(root: Path) -> tuple[set[str], set[str]]:
    rules = _rules(root, True)
    return {r["record"] for r in rules if "record" in r}, {r["alert"] for r in rules if "alert" in r}


def live_records(root: Path) -> tuple[set[str], set[str]]:
    # The live map holds only DORA groups (dora-alerts, dora-metrics), so no filtering.
    rules = _rules(root, False)
    return {r["record"] for r in rules if "record" in r}, {r["alert"] for r in rules if "alert" in r}


def live_rule_inputs(root: Path) -> set[str]:
    return {s for r in _rules(root, False) for s in series_in_expr(r["expr"])}


def _panels(panels: list[dict[str, Any]]) -> Iterator[dict[str, Any]]:
    for p in panels:
        yield p
        yield from _panels(p.get("panels", []))


def _dashboards(root: Path) -> Iterator[tuple[str, dict[str, Any]]]:
    kust = yaml.safe_load((root / DASHBOARDS_DIR / "kustomization.yaml").read_text())
    for name in kust["resources"]:
        for blob in yaml.safe_load((root / DASHBOARDS_DIR / name).read_text())["data"].values():
            yield name, json.loads(blob)


def dashboard_expressions(root: Path) -> Iterator[tuple[str, str, str, str]]:
    for name, dash in _dashboards(root):
        for panel in _panels(dash.get("panels", [])):
            for target in panel.get("targets", []):
                if target.get("expr"):
                    yield name, dash.get("title", ""), panel.get("title", ""), target["expr"]


def series_in_expr(expr: str) -> set[str]:
    # shortcut: regex tokenizer, not a parser; fine for these dashboards, upgrade if PromQL gets fancier.
    expr = re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'', " ", expr)
    expr = re.sub(r"\{[^}]*\}|\[[^\]]*\]|\$\{[^}]*\}|\$\w+", " ", expr)
    expr = re.sub(r"\b(?:by|without|on|ignoring|group_left|group_right)\s*\([^)]*\)", " ", expr)
    names = re.findall(r"[a-zA-Z_:][a-zA-Z0-9_:]*(?!\s*\()(?![a-zA-Z0-9_:])", expr)
    return {n for n in names if n not in PROMQL_WORDS}


def unproduced_series(root: Path) -> set[tuple[str, str, str]]:
    """(dashboard file, panel title, series) for series no live rule or external source produces."""
    produced = live_records(root)[0] | EXTERNAL_SERIES
    return {
        (f, panel, s)
        for f, _, panel, expr in dashboard_expressions(root)
        for s in series_in_expr(expr)
        if s not in produced
    }


def datasource_uids(root: Path) -> set[tuple[str, str, str]]:
    """(dashboard file, panel title, uid) for every panel/target datasource uid."""
    found = set()
    for name, dash in _dashboards(root):
        for panel in _panels(dash.get("panels", [])):
            for ds in [panel.get("datasource"), *(t.get("datasource") for t in panel.get("targets", []))]:
                uid = ds.get("uid") if isinstance(ds, dict) else None
                if uid and not uid.startswith(("-- ", "$")) and uid != "grafana":
                    found.add((name, panel.get("title", ""), uid))
    return found


def provisioned_uids(root: Path) -> set[str]:
    app = yaml.safe_load((root / PROM_APP).read_text())
    values = yaml.safe_load(app["spec"]["source"]["helm"]["values"])
    extra = _find_key(values, "additionalDataSources") or []
    return {d["uid"] for d in extra if "uid" in d} | IMPLICIT_DATASOURCE_UIDS


def unprovisioned_uids(root: Path) -> set[tuple[str, str, str]]:
    ok = provisioned_uids(root)
    return {t for t in datasource_uids(root) if t[2] not in ok}


# --- real manifests ---------------------------------------------------------


def _drift_msg(what: str, actual: set[Any], known: set[Any]) -> str:
    return (
        f"{what}: new drift {sorted(actual - known)}; "
        f"fixed but still listed (delete the entry from the KNOWN_* constant) {sorted(known - actual)}"
    )


def test_not_vacuous() -> None:
    assert live_records(ROOT)[0]
    assert list(_dashboards(ROOT))
    assert list(dashboard_expressions(ROOT))


def test_reference_and_live_records_match() -> None:
    ref, live = reference_records(ROOT)[0], live_records(ROOT)[0]
    assert ref - live == KNOWN_MISSING_FROM_LIVE, _drift_msg(
        "reference-only records", ref - live, KNOWN_MISSING_FROM_LIVE
    )
    assert not live - ref, f"live records absent from {REFERENCE_RULES}: {sorted(live - ref)}"


def test_reference_and_live_alerts_match() -> None:
    ref, live = reference_records(ROOT)[1], live_records(ROOT)[1]
    assert ref - live == KNOWN_ALERTS_MISSING_FROM_LIVE, _drift_msg(
        "reference-only alerts", ref - live, KNOWN_ALERTS_MISSING_FROM_LIVE
    )
    assert not live - ref, f"live alerts absent from {REFERENCE_RULES}: {sorted(live - ref)}"


def test_live_rule_inputs_are_known_sources() -> None:
    unknown = live_rule_inputs(ROOT) - EXTERNAL_SERIES - live_records(ROOT)[0]
    assert not unknown, f"live rules read series not in EXTERNAL_SERIES: {sorted(unknown)}"


def test_dashboard_series_are_produced() -> None:
    gaps = unproduced_series(ROOT)
    series = {s for _, _, s in gaps}
    detail = sorted(g for g in gaps if g[2] not in KNOWN_UNPRODUCED_SERIES)
    assert series == KNOWN_UNPRODUCED_SERIES, (
        f"new unproduced series (file, panel, series): {detail}; "
        f"fixed but still listed (delete from KNOWN_UNPRODUCED_SERIES): {sorted(KNOWN_UNPRODUCED_SERIES - series)}"
    )


def test_dashboard_datasource_uids_are_provisioned() -> None:
    gaps = unprovisioned_uids(ROOT)
    assert {u for _, _, u in gaps} == KNOWN_UNPROVISIONED_UIDS, (
        f"unprovisioned datasource uids (file, panel, uid): {sorted(gaps)}"
    )


# --- red paths on fixtures --------------------------------------------------


def _fixture(tmp_path: Path, ref: list[str], live: list[str], expr: str, nested: bool = False) -> Path:
    def rules(names: list[str]) -> list[dict[str, str]]:
        return [{"record": n, "expr": "up"} for n in names]

    (tmp_path / REFERENCE_RULES).parent.mkdir(parents=True)
    (tmp_path / REFERENCE_RULES).write_text(yaml.safe_dump({"groups": [{"name": "g", "rules": rules(ref)}]}))
    values = {"x": {"additionalPrometheusRulesMap": {"m": {"groups": [{"name": "g", "rules": rules(live)}]}}}}
    app = {"spec": {"source": {"helm": {"values": yaml.safe_dump(values)}}}}
    (tmp_path / PROM_APP).write_text(yaml.safe_dump(app))
    d = tmp_path / DASHBOARDS_DIR
    d.mkdir(parents=True)
    panel: dict[str, Any] = {"title": "P1", "targets": [{"expr": expr}]}
    if nested:
        panel = {"title": "Row", "panels": [panel]}
    (d / "kustomization.yaml").write_text(yaml.safe_dump({"resources": ["cm.yaml"]}))
    cm = {"data": {"d.json": json.dumps({"title": "D", "panels": [panel]})}}
    (d / "cm.yaml").write_text(yaml.safe_dump(cm))
    return tmp_path


def test_rule_missing_from_live_is_reported(tmp_path: Path) -> None:
    root = _fixture(tmp_path, ["a:b", "c:d"], ["a:b"], "a:b")
    assert reference_records(root)[0] - live_records(root)[0] == {"c:d"}


def test_unproduced_series_is_reported_with_panel(tmp_path: Path) -> None:
    root = _fixture(tmp_path, ["a:b"], ["a:b"], "sum(a:b) + dora_made_up_total")
    assert unproduced_series(root) == {("cm.yaml", "P1", "dora_made_up_total")}


def test_nested_row_panel_target_is_found(tmp_path: Path) -> None:
    root = _fixture(tmp_path, [], [], "up", nested=True)
    assert list(dashboard_expressions(root)) == [("cm.yaml", "D", "P1", "up")]


def test_series_in_expr() -> None:
    cases = {
        'last_over_time(dora_cfr_pct{team_id=~"$team_id"}[$window]) * 100': {"dora_cfr_pct"},
        'histogram_quantile(0.5, sum(tekton_x_bucket{status="success"}) by (le)) / 3600': {"tekton_x_bucket"},
        "count(dora:lead_time_hours:p50_30d) or vector(0)": {"dora:lead_time_hours:p50_30d"},
        "(sum(a_total) - count(count by (name) (a_total))) / count(count by (name) (a_total))": {"a_total"},
        'avg(time() - ALERTS_FOR_STATE{alertname="X"}) or vector(0)': {"ALERTS_FOR_STATE"},
        'sum(increase(argocd_app_sync_total{phase="Failed"}[30d])) / sum(rate(b[${__interval}]))': {
            "argocd_app_sync_total",
            "b",
        },
    }
    for expr, expected in cases.items():
        assert series_in_expr(expr) == expected, expr
