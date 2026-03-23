# Jupyter

[Jupyter Notebooks](https://jupyter.org/) provide an interactive computing environment
combining code, prose, and rich output (charts, tables, maps) in a single shareable
document. JupyterHub is the multi-user server that deploys notebooks as a platform
service.

## How Fawkes Uses Jupyter

Jupyter is deployed as part of the data platform and serves two primary use cases:

### DORA Metrics Exploration

Data analysts and platform engineers use notebooks to:
- Query DevLake's PostgreSQL database for raw DORA event data
- Build ad-hoc charts showing deployment frequency trends by team
- Prototype new metrics calculations before formalising them in Grafana dashboards

### Training and Dojo Support

Jupyter notebooks serve as interactive learning materials for the dojo modules.
Learners can run code examples directly in the browser, experiment with changes,
and see results immediately without needing a local development environment.

## Connecting to Platform Data

```python
import pandas as pd
import sqlalchemy

# Connect to DevLake analytics database
engine = sqlalchemy.create_engine(os.environ['DEVLAKE_DB_URL'])
df = pd.read_sql("""
    SELECT team, deployment_date, lead_time_hours
    FROM deployments
    WHERE deployment_date >= NOW() - INTERVAL '90 days'
""", engine)
df.groupby('team')['lead_time_hours'].median().plot(kind='bar')
```

## Accessing JupyterHub

Navigate to the JupyterHub URL configured for your environment. Log in with your
SSO credentials. Each user gets a dedicated notebook server with platform libraries
pre-installed: `pandas`, `matplotlib`, `sqlalchemy`, `opentelemetry-sdk`.

## Sharing Notebooks

Save notebooks to Git (`docs/` or a dedicated `notebooks/` directory) so they can
be reviewed, versioned, and rendered in GitHub. Clear all outputs before committing
to keep diffs readable.

## See Also

- [Data Platform Overview](../data-platform/index.md)
- [View DORA Metrics](../how-to/observability/view-dora-metrics-devlake.md)
- [Dojo Getting Started](../dojo/getting-started.md)
