"""Pluggable interface for DORA data sources.

Fawkes' Rework Rate (and eventually Deployment Frequency / Lead Time, if a
non-ArgoCD deployment path needs them) is computed from PR history and
commit metadata. Today only GitHub is implemented — see github.py, which
ports the live-verified logic from scripts/weekly-metrics.sh. This module
is the abstraction that lets GitLab, Bitbucket, cloud-provider git+registry
services, in-cluster git, and Harbor be added later without reshaping the
computation that consumes them (rework_rate.py, once it exists, iterates
`RepoSourceCollector` instances rather than knowing about any one API).

Scope note: this is the interface only. No new source beyond GitHub is
wired up — each one needs its own credentials, and AGENTS.md SS6 gates
adding a new external dependency behind asking a human first.
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime


@dataclass(frozen=True)
class CommitInfo:
    sha: str
    message_headline: str
    message_body: str


@dataclass(frozen=True)
class MergedPR:
    """One merged pull/merge request, normalized across source systems."""

    id: str
    """Source-native identifier (PR number for GitHub/GitLab, MR IID, etc.)."""
    title: str
    merged_at: datetime
    repo: str
    """owner/repo, project path, or equivalent source-native repo identifier."""
    commits: list[CommitInfo] = field(default_factory=list)
    golden_path: str | None = None
    """From RepoSourceCollector.get_golden_path(repo); None if not annotated."""


class RepoSourceCollector(ABC):
    """One implementation per source system (GitHub, GitLab, Bitbucket, ...).

    Each concrete collector owns its own auth (env var, secret mount, etc.)
    — the interface intentionally has no constructor contract beyond "you
    can produce MergedPR objects for a repo and time range," so a source
    that authenticates via OIDC and one that uses a static token both fit.
    """

    @abstractmethod
    def list_merged_prs(self, repo: str, since: datetime, until: datetime) -> list[MergedPR]:
        """Merged PRs/MRs for `repo` in [since, until), with commits populated."""
        raise NotImplementedError

    @abstractmethod
    def get_golden_path(self, repo: str) -> str | None:
        """Read the golden-path label for `repo`, or None if unset/unknown.

        GitHub: the `fawkes.io/golden-path` annotation in the repo's
        catalog-info.yaml (see templates/*/skeleton/catalog-info.yaml for
        where scaffolded repos get this set).
        """
        raise NotImplementedError
