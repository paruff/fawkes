"""GitHub implementation of RepoSourceCollector.

The only source actually wired up today. Mirrors scripts/weekly-metrics.sh's
live-verified approach: shell out to `gh` rather than call the REST/GraphQL
API directly, because `gh` already handles auth (gh auth login) the same
way this repo's other tooling does, and because a straight GraphQL
`commits` query for PR lists blew GitHub's 500,000-node budget on a repo
this active (confirmed live 2026-09-16) — `gh pr view <n> --json commits`
per-PR, scoped to a small candidate set, avoids that.
"""

from __future__ import annotations

import json
import subprocess
from datetime import datetime

from .base import CommitInfo, MergedPR, RepoSourceCollector

GH_TIMEOUT_SECONDS = 30
PR_LIST_LIMIT = 500


class GitHubCollector(RepoSourceCollector):
    def __init__(self, gh_binary: str = "gh") -> None:
        self._gh = gh_binary

    def _run_gh(self, *args: str) -> str:
        result = subprocess.run(
            [self._gh, *args],
            capture_output=True,
            text=True,
            check=True,
            timeout=GH_TIMEOUT_SECONDS,  # a hung gh must not hang the refresh for good
        )
        return result.stdout

    def list_merged_prs(self, repo: str, since: datetime, until: datetime) -> list[MergedPR]:
        since_str = since.date().isoformat()
        raw = self._run_gh(
            "pr",
            "list",
            "--repo",
            repo,
            "--state",
            "merged",
            "--search",
            f"merged:>={since_str}",
            "--json",
            "number,title,mergedAt",
            "--limit",
            str(PR_LIST_LIMIT),
        )
        prs_json = json.loads(raw)
        if len(prs_json) >= PR_LIST_LIMIT:
            # gh truncates silently; an undercount would look like a real number.
            raise RuntimeError(f"{repo}: merged PR list hit the limit of {PR_LIST_LIMIT}; narrow the window")

        merged_prs = []
        for pr in prs_json:
            merged_at = datetime.fromisoformat(pr["mergedAt"])
            if not (since <= merged_at < until):
                continue
            commits_raw = self._run_gh(
                "pr",
                "view",
                str(pr["number"]),
                "--repo",
                repo,
                "--json",
                "commits",
            )
            commits_json = json.loads(commits_raw).get("commits", [])
            commits = [
                CommitInfo(
                    sha=c.get("oid", ""),
                    message_headline=c.get("messageHeadline", "") or "",
                    message_body=c.get("messageBody", "") or "",
                    committed_at=(datetime.fromisoformat(c["committedDate"]) if c.get("committedDate") else None),
                )
                for c in commits_json
            ]
            merged_prs.append(
                MergedPR(
                    id=str(pr["number"]),
                    title=pr["title"],
                    merged_at=merged_at,
                    repo=repo,
                    commits=commits,
                )
            )
        return merged_prs

    def get_golden_path(self, repo: str) -> str | None:
        try:
            raw = self._run_gh(
                "api",
                f"repos/{repo}/contents/catalog-info.yaml",
                "--jq",
                ".content",
            )
        except subprocess.CalledProcessError:
            return None

        import base64

        import yaml

        try:
            content = base64.b64decode(raw.strip()).decode("utf-8")
            # catalog-info.yaml can be a multi-document YAML file (Component
            # + API, see templates/*/skeleton/catalog-info.yaml) — the
            # golden-path annotation lives on the first (Component) doc.
            doc = next(yaml.safe_load_all(content))
            return doc.get("metadata", {}).get("annotations", {}).get("fawkes.io/golden-path")
        except Exception:
            return None
