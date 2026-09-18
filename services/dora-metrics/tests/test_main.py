"""Self-check for the fawkes-on-fawkes DORA metrics computation.

Mocks the collector (no live gh/GitHub calls) so this runs fast and
deterministically - it's checking the arithmetic, not GitHub's API.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone
from unittest.mock import patch

from app.collectors.base import CommitInfo, MergedPR
from app.main import _compute_metrics

UTC = timezone.utc


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
    assert lead_time == 0.0
