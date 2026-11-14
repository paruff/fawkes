"""Self-check for the fawkes-on-fawkes DORA metrics computation.

Mocks the collector (no live gh/GitHub calls) so this runs fast and
deterministically - it's checking the arithmetic, not GitHub's API.
"""

from __future__ import annotations

import asyncio
import subprocess
from datetime import UTC, datetime, timedelta
from unittest.mock import patch

import pytest
from app import main
from app.collectors.base import CommitInfo, MergedPR
from app.collectors.github import PR_LIST_LIMIT, GitHubCollector
from app.main import _compute_metrics


def _pr(title: str, merged_at: datetime, first_commit_at: datetime | None) -> MergedPR:
    commits = [CommitInfo(sha="abc", message_headline=title, message_body="", committed_at=first_commit_at)]
    return MergedPR(id="1", title=title, merged_at=merged_at, repo="paruff/fawkes", commits=commits)


def test_deployment_frequency_counts_only_release_prs():
    now = datetime(2026, 9, 18, tzinfo=UTC)
    prs = [
        _pr("chore(main): release 0.3.1", now, now - timedelta(hours=5)),
        _pr("feat: unrelated feature", now, now - timedelta(hours=5)),
        _pr("chore(main): release 0.3.2", now - timedelta(days=1), now - timedelta(days=1, hours=10)),
    ]
    with patch("app.main.get_collector") as mock_get_collector:
        mock_get_collector.return_value.list_merged_prs.return_value = prs
        freq, lead_time = _compute_metrics()

    # 2 release PRs out of 30-day window (default WINDOW_DAYS=30)
    assert freq == 2 / 30
    # lead times: 5h and 10h -> average 7.5h
    assert lead_time == 7.5


def test_lead_time_skips_prs_with_no_commit_timestamps():
    now = datetime(2026, 9, 18, tzinfo=UTC)
    prs = [
        _pr("chore(main): release 0.3.1", now, None),  # no committed_at -> skipped
        _pr("chore(main): release 0.3.2", now, now - timedelta(hours=4)),
    ]
    with patch("app.main.get_collector") as mock_get_collector:
        mock_get_collector.return_value.list_merged_prs.return_value = prs
        freq, lead_time = _compute_metrics()

    assert freq == 2 / 30
    assert lead_time == 4.0


def test_no_release_prs_yields_zero_without_crashing():
    with patch("app.main.get_collector") as mock_get_collector:
        mock_get_collector.return_value.list_merged_prs.return_value = []
        freq, lead_time = _compute_metrics()

    assert freq == 0.0
    # No release PR means no lead time to report, not a lead time of 0 hours (#2319).
    assert lead_time is None


# --- #2319: the refresh runs off the request path and a failure is visible ---


@pytest.fixture(autouse=True)
def _fresh_state(monkeypatch):
    monkeypatch.setattr(main, "_snapshot", None)
    monkeypatch.setattr(main, "_refresh_failures", 0)


def _scrape() -> str:
    return asyncio.run(main.metrics()).body.decode()


def _samples(body: str) -> dict[str, float]:
    lines = [line for line in body.splitlines() if line and not line.startswith("#")]
    return {line.split("{")[0]: float(line.rsplit(" ", 1)[1]) for line in lines}


def _collector_returning(prs):
    patcher = patch("app.main.get_collector")
    patcher.start().return_value.list_merged_prs.return_value = prs
    return patcher


def test_scrape_never_calls_github():
    with patch("app.main.get_collector", side_effect=AssertionError("scrape reached the collector")):
        _scrape()


def test_no_values_before_the_first_successful_refresh():
    samples = _samples(_scrape())
    assert "fawkes_repo_deployment_frequency_per_day" not in samples
    assert "fawkes_repo_lead_time_hours" not in samples
    assert "fawkes_repo_dora_last_success_timestamp_seconds" not in samples
    assert samples["fawkes_repo_dora_refresh_failures_total"] == 0


def test_first_refresh_failing_reports_a_failure_not_zeros():
    with patch("app.main.get_collector", side_effect=subprocess.CalledProcessError(1, "gh")):
        main._refresh()
    samples = _samples(_scrape())
    assert "fawkes_repo_deployment_frequency_per_day" not in samples
    assert samples["fawkes_repo_dora_refresh_failures_total"] == 1


def test_later_failure_keeps_the_last_good_values_and_their_age():
    now = datetime.now(UTC)
    patcher = _collector_returning([_pr("chore(main): release 0.3.1", now, now - timedelta(hours=6))])
    main._refresh()
    patcher.stop()
    good = _samples(_scrape())
    with patch("app.main.get_collector", side_effect=subprocess.TimeoutExpired("gh", 30)):
        main._refresh()
    after = _samples(_scrape())

    assert after["fawkes_repo_deployment_frequency_per_day"] == good["fawkes_repo_deployment_frequency_per_day"] > 0
    assert after["fawkes_repo_lead_time_hours"] == 6.0
    assert (
        after["fawkes_repo_dora_last_success_timestamp_seconds"]
        == good["fawkes_repo_dora_last_success_timestamp_seconds"]
    )
    assert after["fawkes_repo_dora_refresh_failures_total"] == 1


def test_no_release_prs_reports_zero_frequency_and_no_lead_time():
    patcher = _collector_returning([])
    main._refresh()
    patcher.stop()
    samples = _samples(_scrape())
    assert samples["fawkes_repo_deployment_frequency_per_day"] == 0
    assert "fawkes_repo_lead_time_hours" not in samples


def test_gh_is_called_with_a_timeout():
    with patch("app.collectors.github.subprocess.run") as run:
        run.return_value.stdout = "[]"
        GitHubCollector().list_merged_prs("o/r", datetime(2026, 1, 1, tzinfo=UTC), datetime(2026, 2, 1, tzinfo=UTC))
    assert run.call_args.kwargs["timeout"] > 0


def test_a_truncated_pr_list_fails_instead_of_undercounting():
    full_page = "[" + ",".join(["{}"] * PR_LIST_LIMIT) + "]"
    with patch("app.collectors.github.subprocess.run") as run:
        run.return_value.stdout = full_page
        with pytest.raises(RuntimeError, match="limit"):
            GitHubCollector().list_merged_prs("o/r", datetime(2026, 1, 1, tzinfo=UTC), datetime(2026, 2, 1, tzinfo=UTC))
