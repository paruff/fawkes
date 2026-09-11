# Register a Service in the Backstage Catalog

> **Goal**: make your service discoverable in the Backstage service catalog (portal + TechDocs).

## Prerequisites

- Backstage running (`make dev-up`, then `make dev-status` for the URL)
- A `catalog-info.yaml` in your service repo (see root `catalog-info.yaml` for a `Component` example)

## Steps

1. **Add a `Component` entry** to your repo's `catalog-info.yaml`:

   ```yaml
   apiVersion: backstage.io/v1alpha1
   kind: Component
   metadata:
     name: my-service
     title: My Service
     description: What it does, in one sentence
   spec:
     type: service
     lifecycle: experimental
     owner: platform-team
     system: fawkes-platform
   ```

2. **Reference it from the root catalog** (`catalog-info.yaml`) or register the repo URL in Backstage (**Catalog → Register Existing Component**).

3. **Verify**: open Backstage → Catalog → search `my-service`. It should appear with owner `platform-team` and system `fawkes-platform`.

## Verify success

```bash
# Catalog file is valid YAML and contains a Component kind
python3 -c "import yaml,sys; print([d.get('kind') for d in yaml.safe_load_all(open('catalog-info.yaml'))])"
```

## Troubleshooting

- Not appearing? Check Backstage logs for catalog processing errors and confirm `spec.owner` matches a group in the catalog.
- See [Backstage app](../../platform/apps/backstage/README.md) for portal configuration.
