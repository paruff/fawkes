"""Not-yet-implemented RepoSourceCollector stubs.

Each of these needs its own credentials/API client before it can do
anything — adding that is an external dependency, which AGENTS.md SS6 gates
behind asking a human first. These stubs exist so `registry.py` can name
all 7 sources the platform intends to eventually support, and so a caller
gets a clear "not implemented yet" instead of a KeyError when one is
requested. Fill one in (and remove NotImplementedError) when that source is
actually prioritized — see github.py for the shape a real implementation
takes.
"""

from __future__ import annotations

from datetime import datetime

from .base import MergedPR, RepoSourceCollector


class _UnimplementedCollector(RepoSourceCollector):
    source_name = "unimplemented"

    def list_merged_prs(self, repo: str, since: datetime, until: datetime) -> list[MergedPR]:
        raise NotImplementedError(f"{self.source_name} collector is not implemented yet")

    def get_golden_path(self, repo: str) -> str | None:
        raise NotImplementedError(f"{self.source_name} collector is not implemented yet")


class GitLabCollector(_UnimplementedCollector):
    """Would use python-gitlab or GitLab's REST API + a project access token."""

    source_name = "gitlab"


class BitbucketCollector(_UnimplementedCollector):
    """Would use Bitbucket Cloud/Server REST API + an app password or OAuth."""

    source_name = "bitbucket"


class AWSCollector(_UnimplementedCollector):
    """CodeCommit (repo) + ECR (registry) via boto3, IAM-role auth."""

    source_name = "aws"


class AzureCollector(_UnimplementedCollector):
    """Azure Repos (repo) + ACR (registry) via azure-devops + azure-identity."""

    source_name = "azure"


class GCPCollector(_UnimplementedCollector):
    """Cloud Source Repositories (repo) + Artifact Registry via google-cloud SDKs."""

    source_name = "gcp"


class InClusterGitCollector(_UnimplementedCollector):
    """An in-cluster Gitea/Forgejo instance or similar — no external API at all."""

    source_name = "in-cluster-git"


class HarborCollector(_UnimplementedCollector):
    """Harbor's REST API for registry-side push/scan events (not PR/MR data —
    Harbor has no repo/PR concept, so this collector's real shape will likely
    differ from RepoSourceCollector once implemented; kept here as a named
    placeholder rather than modeled prematurely."""

    source_name = "harbor"
