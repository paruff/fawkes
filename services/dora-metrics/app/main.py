"""fawkes-on-fawkes DORA self-measurement service.

Exposes Deployment Frequency and Lead Time for Changes for paruff/fawkes
itself, computed from real GitHub data via GitHubCollector (see
collectors/github.py) - the same live-verified approach as
scripts/weekly-metrics.sh's Rework Rate. Scraped by Prometheus like any
other target; no DevLake, no Pushgateway, no parallel pipeline
(docs/elite-engineering-bridge-plan.md Phase 5's own risk mitigation).

Deployment Frequency: merged `chore(main): release` PRs per day (the
release-please automated releases this repo already publishes) over a
rolling window.

Lead Time for Changes: average time from a release PR's first commit to
its merge, over the same window - the closest analog for a meta-repo with
no Kubernetes deployment target of its own.

Results are cached for CACHE_TTL_SECONDS to avoid hammering the GitHub API
on every Prometheus scrape.
"""

from __future__ import annotations

import logging
import os
import time
from contextlib import asynccontextmanager
from datetime import UTC, datetime, timedelta

from fastapi import FastAPI, Response

from .collectors import get_collector

logger = logging.getLogger(__name__)

REPO = os.getenv("DORA_METRICS_REPO", "paruff/fawkes")
WINDOW_DAYS = int(os.getenv("DORA_METRICS_WINDOW_DAYS", "30"))
CACHE_TTL_SECONDS = int(os.getenv("DORA_METRICS_CACHE_TTL_SECONDS", "600"))
RELEASE_TITLE_PREFIX = "chore(main): release"

_cache: dict[str, float] = {"computed_at": 0.0, "deployment_frequency": 0.0, "lead_time_hours": 0.0}


def _compute_metrics() -> tuple[float, float]:
    collector = get_collector("github")
    until = datetime.now(UTC)
    since = until - timedelta(days=WINDOW_DAYS)
    merged_prs = collector.list_merged_prs(REPO, since=since, until=until)
    release_prs = [pr for pr in merged_prs if pr.title.startswith(RELEASE_TITLE_PREFIX)]

    deployment_frequency = len(release_prs) / WINDOW_DAYS

    lead_times_hours = []
    for pr in release_prs:
        commits_with_dates = [c for c in pr.commits if c.committed_at is not None]
        if not commits_with_dates:
            continue
        first_commit_at = min(c.committed_at for c in commits_with_dates)
        lead_times_hours.append((pr.merged_at - first_commit_at).total_seconds() / 3600)
    lead_time_hours = sum(lead_times_hours) / len(lead_times_hours) if lead_times_hours else 0.0

    return deployment_frequency, lead_time_hours


def _get_cached_metrics() -> tuple[float, float]:
    now = time.time()
    if now - _cache["computed_at"] > CACHE_TTL_SECONDS:
        try:
            deployment_frequency, lead_time_hours = _compute_metrics()
            _cache["computed_at"] = now
            _cache["deployment_frequency"] = deployment_frequency
            _cache["lead_time_hours"] = lead_time_hours
        except Exception:
            logger.exception("Failed to refresh fawkes-on-fawkes DORA metrics; serving stale/zero values")
    return _cache["deployment_frequency"], _cache["lead_time_hours"]


@asynccontextmanager
async def lifespan(app: FastAPI):
    yield


app = FastAPI(title="dora-metrics", lifespan=lifespan)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.get("/metrics")
async def metrics() -> Response:
    deployment_frequency, lead_time_hours = _get_cached_metrics()
    body = (
        "# HELP fawkes_repo_deployment_frequency_per_day Merged release PRs per day "
        f"for {REPO} over a {WINDOW_DAYS}-day window.\n"
        "# TYPE fawkes_repo_deployment_frequency_per_day gauge\n"
        f'fawkes_repo_deployment_frequency_per_day{{repo="{REPO}"}} {deployment_frequency}\n'
        "# HELP fawkes_repo_lead_time_hours Average hours from a release PR's first "
        f"commit to merge for {REPO} over a {WINDOW_DAYS}-day window.\n"
        "# TYPE fawkes_repo_lead_time_hours gauge\n"
        f'fawkes_repo_lead_time_hours{{repo="{REPO}"}} {lead_time_hours}\n'
    )
    return Response(content=body, media_type="text/plain; version=0.0.4")
