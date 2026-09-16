"""Source name -> RepoSourceCollector lookup.

Only "github" is usable today; the other 6 names are registered so callers
and config can refer to them by the same stable name they'll keep once
implemented, and get a clear NotImplementedError rather than a KeyError.
"""

from __future__ import annotations

from .base import RepoSourceCollector
from .github import GitHubCollector
from .stubs import (
    AWSCollector,
    AzureCollector,
    BitbucketCollector,
    GCPCollector,
    GitLabCollector,
    HarborCollector,
    InClusterGitCollector,
)

_COLLECTOR_CLASSES: dict[str, type[RepoSourceCollector]] = {
    "github": GitHubCollector,
    "gitlab": GitLabCollector,
    "bitbucket": BitbucketCollector,
    "aws": AWSCollector,
    "azure": AzureCollector,
    "gcp": GCPCollector,
    "in-cluster-git": InClusterGitCollector,
    "harbor": HarborCollector,
}


def get_collector(source_name: str) -> RepoSourceCollector:
    try:
        collector_class = _COLLECTOR_CLASSES[source_name]
    except KeyError:
        raise ValueError(f"Unknown source '{source_name}'. Known sources: {sorted(_COLLECTOR_CLASSES)}") from None
    return collector_class()
