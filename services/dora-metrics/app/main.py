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

A background task refreshes the numbers every CACHE_TTL_SECONDS. A scrape
only reads the last good snapshot, so it never waits on GitHub and /health
keeps answering during a refresh (#2319). Until a refresh has succeeded no
value is exposed: a failure must not look like "0 deployments".
"""

from __future__ import annotations

import asyncio
import logging
import os
import time
from contextlib import asynccontextmanager
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta

from fastapi import FastAPI, Response

from .collectors import get_collector

logger = logging.getLogger(__name__)

REPO = os.getenv("DORA_METRICS_REPO", "paruff/fawkes")
WINDOW_DAYS = int(os.getenv("DORA_METRICS_WINDOW_DAYS", "30"))
CACHE_TTL_SECONDS = int(os.getenv("DORA_METRICS_CACHE_TTL_SECONDS", "600"))
RELEASE_TITLE_PREFIX = "chore(main): release"


@dataclass(frozen=True)
class Snapshot:
    deployment_frequency: float
    lead_time_hours: float | None  # None: no release PR in the window had commit timestamps
    computed_at: float


# Replaced whole by _refresh, never mutated, so a scrape reads one consistent snapshot.
_snapshot: Snapshot | None = None
_refresh_failures = 0


def _compute_metrics() -> tuple[float, float | None]:
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
    lead_time_hours = sum(lead_times_hours) / len(lead_times_hours) if lead_times_hours else None

    return deployment_frequency, lead_time_hours


def _refresh() -> None:
    """Blocking (shells out to gh). Keeps the last good snapshot when it fails."""
    global _snapshot, _refresh_failures
    try:
        deployment_frequency, lead_time_hours = _compute_metrics()
    except Exception:
        _refresh_failures += 1
        logger.exception("DORA refresh for %s failed; the last good values stay in place", REPO)
        return
    _snapshot = Snapshot(deployment_frequency, lead_time_hours, time.time())


async def _refresh_forever() -> None:
    while True:
        await asyncio.to_thread(_refresh)  # off the event loop, so /health and /metrics keep answering
        await asyncio.sleep(CACHE_TTL_SECONDS)


@asynccontextmanager
async def lifespan(app: FastAPI):
    task = asyncio.create_task(_refresh_forever())
    yield
    task.cancel()


app = FastAPI(title="dora-metrics", lifespan=lifespan)


@app.get("/health")
async def health() -> dict:
    return {"status": "ok"}


@app.get("/metrics")
async def metrics() -> Response:
    snapshot = _snapshot
    labels = f'{{repo="{REPO}"}}'
    lines = [
        "# HELP fawkes_repo_dora_refresh_failures_total Failed refreshes from GitHub since this process started.",
        "# TYPE fawkes_repo_dora_refresh_failures_total counter",
        f"fawkes_repo_dora_refresh_failures_total{labels} {_refresh_failures}",
    ]
    if snapshot is not None:
        lines += [
            "# HELP fawkes_repo_dora_last_success_timestamp_seconds Unix time of the last successful refresh.",
            "# TYPE fawkes_repo_dora_last_success_timestamp_seconds gauge",
            f"fawkes_repo_dora_last_success_timestamp_seconds{labels} {snapshot.computed_at}",
            f"# HELP fawkes_repo_deployment_frequency_per_day Merged release PRs per day for {REPO} "
            + f"over a {WINDOW_DAYS}-day window.",
            "# TYPE fawkes_repo_deployment_frequency_per_day gauge",
            f"fawkes_repo_deployment_frequency_per_day{labels} {snapshot.deployment_frequency}",
        ]
        if snapshot.lead_time_hours is not None:
            lines += [
                "# HELP fawkes_repo_lead_time_hours Average hours from a release PR's first commit to merge "
                + f"for {REPO} over a {WINDOW_DAYS}-day window.",
                "# TYPE fawkes_repo_lead_time_hours gauge",
                f"fawkes_repo_lead_time_hours{labels} {snapshot.lead_time_hours}",
            ]
    return Response(content="\n".join(lines) + "\n", media_type="text/plain; version=0.0.4")
