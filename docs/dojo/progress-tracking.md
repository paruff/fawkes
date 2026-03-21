# Dojo Progress Tracking

This document explains how Fawkes Dojo belt progress is stored, displayed,
and reset.

## Overview

Each time a learner successfully completes a dojo lab, the lab's `validate.sh`
script automatically records the result in a Kubernetes ConfigMap named
**`fawkes-dojo-progress`** in the `fawkes` namespace.

A Backstage frontend plugin — **`@fawkes/backstage-plugin-dojo-progress`** —
reads that ConfigMap and renders a belt-progression dashboard accessible from
the sidebar under **Dojo**.

```
validate.sh (passes) → kubectl patch ConfigMap → Backstage plugin reads ConfigMap → Dashboard UI
```

---

## Data Storage

### ConfigMap structure

```
Namespace : fawkes
Name      : fawkes-dojo-progress
```

Each key in `.data` is a **GitHub username**. The value is a **JSON string**
describing that learner's progress across all five belts:

```json
{
  "white":  { "labs": { "lab-01": "PASS", "lab-02": "PASS", "lab-03": "FAIL" } },
  "yellow": { "labs": { "lab-05": "PASS" } },
  "green":  { "labs": {} },
  "brown":  { "labs": {} },
  "black":  { "labs": {} }
}
```

Lab status values:

| Value     | Meaning                             |
|-----------|-------------------------------------|
| `PASS`    | `validate.sh` exited with code 0    |
| `FAIL`    | `validate.sh` exited with code 1    |
| `PENDING` | Lab not yet attempted               |

### Belt levels

| Belt   | Modules | Labs      |
|--------|---------|-----------|
| White  | 01–04   | lab-01–04 |
| Yellow | 05–08   | lab-05–08 |
| Green  | 09–12   | lab-09–12 |
| Brown  | 13–16   | lab-13–16 |
| Black  | 17–20   | lab-17–20 |

---

## How validate.sh writes progress

At the end of every lab's `validate.sh`, a call to `write_dojo_progress` is
made when all checks pass:

```bash
write_dojo_progress "$DOJO_GITHUB_USERNAME" "$DOJO_BELT" "$DOJO_LAB_ID" "PASS"
```

The function:

1. Resolves the GitHub username from the `GITHUB_USER` environment variable,
   falling back to `git config user.name`.
2. Creates the `fawkes-dojo-progress` ConfigMap if it does not already exist.
3. Reads the current JSON progress for that user.
4. Merges the new lab result into the JSON blob.
5. Patches the ConfigMap with `kubectl patch --type merge`.

The progress update is **best-effort**: if `kubectl` is unavailable or RBAC
denies the patch, a warning is printed and the overall exit code of
`validate.sh` remains `0` (lab is still considered passed).

### Setting your GitHub username

```bash
# Option 1: environment variable (preferred in CI)
export GITHUB_USER=alice

# Option 2: git config (picked up automatically)
git config --global user.name alice
```

---

## How the Backstage plugin reads progress

The plugin uses the Backstage proxy endpoint `/dojo/progress`, which is
configured in `platform/apps/backstage/app-config.yaml` to forward requests to
the Kubernetes API:

```
GET /api/proxy/dojo/progress
  → https://kubernetes.default.svc/api/v1/namespaces/fawkes/configmaps/fawkes-dojo-progress
```

The plugin then:

1. Retrieves the signed-in user's GitHub username from the Backstage identity
   API.
2. Looks up that username in the ConfigMap's `.data`.
3. Parses the JSON and renders the belt-progress dashboard.

### Plugin location

```
platform/backstage/plugins/dojo-progress/
  configmap.yaml   — K8s ConfigMap manifest (apply once)
  rbac.yaml        — Role + RoleBinding for Backstage and validate.sh
  src/
    plugin.ts      — Backstage plugin registration
    api.ts         — DojoProgressApi + DojoProgressClient
    index.ts       — Public exports
    components/
      DojoProgressPage/
        DojoProgressPage.tsx   — Belt dashboard React component
```

### Wiring the plugin into Backstage

After applying the Kubernetes manifests:

```bash
kubectl apply -f platform/backstage/plugins/dojo-progress/configmap.yaml
kubectl apply -f platform/backstage/plugins/dojo-progress/rbac.yaml
```

Install the package and add two code snippets:

```bash
# 1. Install
yarn workspace app add @fawkes/backstage-plugin-dojo-progress
```

```tsx
// 2. packages/app/src/App.tsx — add a route
import { DojoProgressPage } from '@fawkes/backstage-plugin-dojo-progress';
// inside <FlatRoutes>:
<Route path="/dojo" element={<DojoProgressPage />} />
```

```tsx
// 3. packages/app/src/components/Root/Root.tsx — add a sidebar item
import SchoolIcon from '@material-ui/icons/School';
// inside the sidebar:
<SidebarItem icon={SchoolIcon} to="dojo" text="Dojo" />
```

---

## Resetting progress

### Reset a single lab

```bash
kubectl patch configmap fawkes-dojo-progress \
  -n fawkes \
  --type json \
  -p '[{"op":"remove","path":"/data/alice"}]'
```

### Reset a specific lab result (Python helper)

```bash
python3 - <<'EOF'
import json, subprocess

USERNAME = "alice"
BELT = "white"
LAB_ID = "lab-01"

raw = subprocess.check_output([
  "kubectl", "get", "configmap", "fawkes-dojo-progress",
  "-n", "fawkes", "-o", f"jsonpath={{.data.{USERNAME}}}"
]).decode()

progress = json.loads(raw) if raw.strip() else {}
progress.setdefault(BELT, {"labs": {}})["labs"].pop(LAB_ID, None)

new_val = json.dumps(progress).replace('"', '\\"')
subprocess.run([
  "kubectl", "patch", "configmap", "fawkes-dojo-progress",
  "-n", "fawkes", "--type", "merge",
  "-p", f'{{"data":{{"{USERNAME}":"{new_val}"}}}}'
], check=True)
print(f"Reset {USERNAME}/{BELT}/{LAB_ID}")
EOF
```

### Reset all progress

```bash
kubectl delete configmap fawkes-dojo-progress -n fawkes
kubectl apply -f platform/backstage/plugins/dojo-progress/configmap.yaml
```

---

## RBAC requirements

| Actor                    | Verbs          | Resource         |
|--------------------------|----------------|------------------|
| Backstage ServiceAccount | `get`          | ConfigMap        |
| `validate.sh` (default SA) | `get`, `patch`, `create` | ConfigMap |

Apply the roles:

```bash
kubectl apply -f platform/backstage/plugins/dojo-progress/rbac.yaml
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|-------------|-----|
| Dashboard shows "No progress recorded" | ConfigMap empty or username mismatch | Check `kubectl get cm fawkes-dojo-progress -n fawkes -o yaml` |
| `validate.sh` warns "Could not patch ConfigMap" | Missing RBAC | Apply `rbac.yaml` |
| Plugin shows "Failed to fetch dojo progress" | Proxy misconfigured | Verify `/dojo/progress` proxy in `app-config.yaml` and the `KUBERNETES_SERVICE_ACCOUNT_TOKEN` env var |
| Username is wrong on dashboard | Identity resolver mismatch | Ensure GitHub OAuth `usernameMatchingUserEntityName` resolver is active |
