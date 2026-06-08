"""
DORA Metrics Exporter for Fawkes Platform

Collects and exposes DORA 5 metrics as Prometheus gauges:
- Deployment Frequency (per day/week)
- Lead Time for Changes (commit → production)
- Change Failure Rate (% of deployments causing failures)
- Mean Time to Recovery (incident → resolution)
- Rework Rate (% of work that is rework)

Data sources:
- ArgoCD: deployment events, sync status, health
- GitHub Actions: CI pipeline durations, commit timestamps

Architecture note:
This is a lightweight scraper, not a full pipeline. It queries ArgoCD and GitHub
APIs on a configurable interval, caches results, and exposes them as Prometheus
metrics. The DORA dashboard consumes these metrics directly.
"""

import os
import time
import logging
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
from fastapi import FastAPI
from fastapi.responses import PlainTextResponse
from prometheus_client import Counter, Gauge, Histogram, generate_latest, REGISTRY

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------
ARGOCD_BASE_URL = os.getenv("ARGOCD_BASE_URL", "http://argocd-server.argocd.svc:80")
ARGOCD_TOKEN = os.getenv("ARGOCD_TOKEN", "")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN", "")
GITHUB_REPO = os.getenv("GITHUB_REPO", "paruff/fawkes")
SCRAPE_INTERVAL = int(os.getenv("SCRAPE_INTERVAL", "60"))  # seconds

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("dora-metrics")

# ---------------------------------------------------------------------------
# Prometheus Metrics
# ---------------------------------------------------------------------------
DEPLOYMENTS_TOTAL = Gauge(
    "dora_deployments_total",
    "Total deployments to production",
    ["environment", "team", "service"],
)

DEPLOYMENT_FAILURES_TOTAL = Gauge(
    "dora_deployment_failures_total",
    "Total deployments causing failures",
    ["environment", "team", "service"],
)

LEAD_TIME_SECONDS = Gauge(
    "dora_lead_time_seconds",
    "Lead time from commit to production deployment",
    ["environment", "team", "service"],
)

MTTR_SECONDS = Gauge(
    "dora_mttr_seconds",
    "Mean time to restore after failed deployment",
    ["environment", "team", "service"],
)

REWORK_RATE = Gauge(
    "dora_rework_rate",
    "Percentage of work that is rework",
    ["environment", "team", "service"],
)

# AI Amplification Metrics
AI_ADOPTION_RATE = Gauge(
    "dora_ai_adoption_rate",
    "Percentage of PRs using AI assistance",
    ["service"],
)

AI_PR_SIZE_RATIO = Gauge(
    "dora_ai_pr_size_ratio",
    "Ratio of AI-assisted PR size to manual PR size",
    ["service"],
)

AI_REVIEW_TIME_RATIO = Gauge(
    "dora_ai_review_time_ratio",
    "Ratio of AI-assisted PR review time to manual PR review time",
    ["service"],
)

PR_CONTEXT_LOAD = Gauge(
    "dora_pr_context_load",
    "Average concurrent PRs per developer",
    ["service"],
)

# ---------------------------------------------------------------------------
# FastAPI App
# ---------------------------------------------------------------------------
app = FastAPI(title="DORA Metrics Exporter", version="1.0.0")

_last_scrape: Optional[float] = None


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/ready")
def ready():
    return {"status": "ready"}


@app.get("/metrics")
def metrics():
    return PlainTextResponse(generate_latest(REGISTRY), media_type="text/plain")


@app.get("/api/v1/scrape")
def trigger_scrape():
    """Manually trigger a scrape cycle."""
    _scrape_dora_metrics()
    return {"status": "scraped", "timestamp": datetime.now(timezone.utc).isoformat()}


# ---------------------------------------------------------------------------
# ArgoCD Collection
# ---------------------------------------------------------------------------
async def _collect_argocd_deployments() -> dict:
    """Query ArgoCD for application sync history."""
    apps = {}
    try:
        async with httpx.AsyncClient(timeout=10, verify=False) as client:
            headers = {}
            if ARGOCD_TOKEN:
                headers["Authorization"] = f"Bearer {ARGOCD_TOKEN}"

            resp = await client.get(
                f"{ARGOCD_BASE_URL}/api/v1/applications",
                headers=headers,
            )
            resp.raise_for_status()
            data = resp.json()

            for app_data in data.get("items", []):
                name = app_data.get("metadata", {}).get("name", "unknown")
                spec = app_data.get("spec", {})
                status = app_data.get("status", {})

                # Extract environment from spec
                env = "dev"
                dest = spec.get("destination", {})
                namespace = dest.get("namespace", "")
                if "prod" in namespace:
                    env = "production"
                elif "staging" in namespace:
                    env = "staging"

                # Sync status
                sync_status = status.get("sync", {}).get("status", "Unknown")
                health_status = status.get("health", {}).get("status", "Unknown")

                # Operation phase (last sync result)
                operation = status.get("operationState", {})
                op_phase = operation.get("phase", "Unknown")
                op_finish = operation.get("finishedAt", "")

                # Sync history
                history = status.get("history", [])
                sync_count = len(history)

                apps[name] = {
                    "environment": env,
                    "sync_status": sync_status,
                    "health_status": health_status,
                    "operation_phase": op_phase,
                    "sync_count": sync_count,
                    "last_sync": op_finish,
                }

    except Exception as e:
        logger.error(f"Failed to query ArgoCD: {e}")

    return apps


# ---------------------------------------------------------------------------
# GitHub Collection
# ---------------------------------------------------------------------------
async def _collect_github_deployments() -> dict:
    """Query GitHub Actions for deployment workflow runs."""
    deployments = {}
    try:
        async with httpx.AsyncClient(timeout=10) as client:
            headers = {}
            if GITHUB_TOKEN:
                headers["Authorization"] = f"token {GITHUB_TOKEN}"

            # Get recent workflow runs for CI/CD pipeline
            resp = await client.get(
                f"https://api.github.com/repos/{GITHUB_REPO}/actions/runs",
                headers=headers,
                params={"per_page": 100, "status": "completed"},
            )
            resp.raise_for_status()
            data = resp.json()

            for run in data.get("workflow_runs", []):
                name = run.get("name", "unknown")
                created = run.get("created_at", "")
                updated = run.get("updated_at", "")
                conclusion = run.get("conclusion", "unknown")

                if created and updated:
                    try:
                        t_created = datetime.fromisoformat(created.replace("Z", "+00:00"))
                        t_updated = datetime.fromisoformat(updated.replace("Z", "+00:00"))
                        duration = (t_updated - t_created).total_seconds()
                    except (ValueError, TypeError):
                        duration = 0
                else:
                    duration = 0

                if name not in deployments:
                    deployments[name] = {
                        "total_runs": 0,
                        "successful": 0,
                        "failed": 0,
                        "avg_duration": 0,
                        "durations": [],
                    }

                deployments[name]["total_runs"] += 1
                if conclusion == "success":
                    deployments[name]["successful"] += 1
                else:
                    deployments[name]["failed"] += 1
                deployments[name]["durations"].append(duration)

            # Calculate averages
            for name, data in deployments.items():
                durations = data.pop("durations", [])
                if durations:
                    data["avg_duration"] = sum(durations) / len(durations)

    except Exception as e:
        logger.error(f"Failed to query GitHub: {e}")

    return deployments


# ---------------------------------------------------------------------------
# Scrape Logic
# ---------------------------------------------------------------------------
def _scrape_dora_metrics():
    """Main scrape cycle — collects from all sources and updates Prometheus gauges."""
    global _last_scrape

    logger.info("Starting DORA metrics scrape cycle")

    # Run async collection
    import asyncio
    try:
        loop = asyncio.get_event_loop()
    except RuntimeError:
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)

    argocd_apps = loop.run_until_complete(_collect_argocd_deployments())
    github_runs = loop.run_until_complete(_collect_github_deployments())

    # --- DORA Metric: Deployment Frequency ---
    # Count successful ArgoCD syncs as deployments
    for name, info in argocd_apps.items():
        env = info["environment"]
        DEPLOYMENTS_TOTAL.labels(
            environment=env, team="platform-team", service=name
        ).set(info["sync_count"])

        # --- DORA Metric: Change Failure Rate ---
        failed_count = 1 if info["operation_phase"] == "Error" else 0
        DEPLOYMENT_FAILURES_TOTAL.labels(
            environment=env, team="platform-team", service=name
        ).set(failed_count)

    # --- DORA Metric: Lead Time ---
    # Use GitHub workflow run duration as a proxy for lead time
    for name, info in github_runs.items():
        LEAD_TIME_SECONDS.labels(
            environment="production", team="platform-team", service=name
        ).set(info.get("avg_duration", 0))

    # --- DORA Metric: MTTR ---
    # MTTR is derived from incident resolution time
    # For now, use a placeholder — real MTTR needs Alertmanager integration
    for name in argocd_apps:
        MTTR_SECONDS.labels(
            environment=argocd_apps[name]["environment"],
            team="platform-team",
            service=name,
        ).set(0)  # Will be populated when Alertmanager is wired

    # --- AI Amplification Metrics ---
    # These will be populated by GitHub API analysis of PR labels/metadata
    for name in github_runs:
        AI_ADOPTION_RATE.labels(service=name).set(0)  # TODO: analyze PR labels
        AI_PR_SIZE_RATIO.labels(service=name).set(1.0)  # TODO: compare AI vs manual
        AI_REVIEW_TIME_RATIO.labels(service=name).set(1.0)  # TODO: compare review times

    _last_scrape = time.time()
    logger.info(
        f"Scrape complete: {len(argocd_apps)} ArgoCD apps, "
        f"{len(github_runs)} GitHub workflows"
    )


# ---------------------------------------------------------------------------
# Background Scraper
# ---------------------------------------------------------------------------
@app.on_event("startup")
async def start_scraper():
    import asyncio

    async def _loop():
        while True:
            try:
                _scrape_dora_metrics()
            except Exception as e:
                logger.error(f"Scrape failed: {e}")
            await asyncio.sleep(SCRAPE_INTERVAL)

    asyncio.create_task(_loop())
    logger.info(f"Background scraper started (interval: {SCRAPE_INTERVAL}s)")
