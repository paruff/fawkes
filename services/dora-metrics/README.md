# dora-metrics

Pluggable interface for DORA data sources — `app/collectors/`.

Only GitHub is implemented (`collectors/github.py`, mirroring the
live-verified logic in `scripts/weekly-metrics.sh`). The other 6 sources
named in the platform's roadmap (GitLab, Bitbucket, AWS, Azure, GCP,
in-cluster git, Harbor) have stub classes in `collectors/stubs.py` that
raise `NotImplementedError` — filling one in is future work, gated behind
AGENTS.md §6's "ask before adding an external dependency" rule.

```python
from app.collectors import get_collector

collector = get_collector("github")
prs = collector.list_merged_prs("paruff/fawkes", since=..., until=...)
```

No FastAPI app lives here yet — this directory previously existed empty.
`scripts/weekly-metrics.sh` remains the actual entry point that computes
and publishes the Rework Rate; this package is the reusable library it
will eventually delegate to once source #2 is prioritized.
