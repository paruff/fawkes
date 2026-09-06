# Multi-Provider Git and Container Registry Setup

The golden-path Tekton pipeline (`platform/apps/tekton/golden-path-pipeline.yaml`)
is provider-agnostic by design: it takes a plain git clone URL (`repo-url`) and
a plain image reference (`image-name`), and authenticates to whichever registry
that image reference points at via a generic `dockerconfig` Secret. Nothing
provider-specific is hardcoded in the pipeline itself - what differs per
provider is only (a) the URL/reference format and (b) how you generate the
credential that goes into that Secret. This doc is the reference for both,
per provider.

## How the pipeline consumes these

```yaml
# PipelineRun params
params:
  - name: repo-url
    value: <see "Git source" below for your provider>
  - name: image-name
    value: <see "Container registry" below for your provider>

# PipelineRun workspaces - dockerconfig is optional; omit it entirely for a
# public repo/registry that needs no auth.
workspaces:
  - name: source
    persistentVolumeClaim:
      claimName: golden-path-workspace
  - name: dockerconfig
    secret:
      secretName: <registry-creds-secret-name>
      items:
        - key: .dockerconfigjson
          path: config.json
```

Every registry section below ends in the same `kubectl create secret docker-registry`
command shape - only `--docker-server`, `--docker-username`, and `--docker-password`
change.

---

## Git source providers

| Provider | `repo-url` format | Auth needed for a private repo |
|---|---|---|
| GitHub | `https://github.com/<org>/<repo>.git` | `https://x-access-token:<PAT>@github.com/<org>/<repo>.git` |
| GitLab | `https://gitlab.com/<group>/<repo>.git` | `https://oauth2:<PAT>@gitlab.com/<group>/<repo>.git` |
| Bitbucket | `https://bitbucket.org/<workspace>/<repo>.git` | `https://x-token-auth:<app-password>@bitbucket.org/<workspace>/<repo>.git` |
| AWS CodeCommit | `https://git-codecommit.<region>.amazonaws.com/v1/repos/<repo>` | IAM Git credentials (generated in IAM console) embedded the same way, or `git-remote-codecommit` (needs the AWS CLI baked into `fetch-source`'s image - not there by default) |
| Azure Repos | `https://dev.azure.com/<org>/<project>/_git/<repo>` | `https://<any-string>:<PAT>@dev.azure.com/<org>/<project>/_git/<repo>` |
| Google Cloud Source Repositories | `https://source.developers.google.com/p/<project>/r/<repo>` | Needs a Google credential helper in the clone image - simplest path is mirroring to GitHub/GitLab instead, or baking `gcloud`/the Cloud Source Repos credential helper into a custom `fetch-source` image |
| Local/native git (self-hosted, e.g. `git-daemon`/Gitea/self-hosted GitLab) | `https://git.internal.example/<org>/<repo>.git` (or `git://` for anonymous read) | Same embedded-credential pattern as GitHub, or an SSH deploy key (see below) |

For all HTTPS-with-embedded-token forms above, the token goes directly in
`repo-url` - fine for a `PipelineRun` param (not logged in plaintext by
Tekton, but visible to anyone who can `kubectl get pipelinerun -o yaml`).
For anything more sensitive, mount the token as a workspace/Secret and have
`fetch-source`'s script read it into the clone URL at runtime instead of
passing it as a literal param - the current `fetch-source` task
(`platform/apps/tekton/golden-path-pipeline.yaml`) would need a small change
to do that; it currently clones with the URL as given.

### SSH instead of HTTPS (any provider, including local native git)

Add an `ssh-creds` workspace backed by a `kubernetes.io/ssh-auth` Secret,
mount it at `fetch-source`'s `$HOME/.ssh`, and use an `ssh://` or
`git@host:org/repo.git` form for `repo-url`:

```bash
kubectl create secret generic git-ssh-creds \
  --type=kubernetes.io/ssh-auth \
  --from-file=ssh-privatekey=/path/to/deploy_key \
  -n fawkes
```

---

## Container registries

### GitHub Container Registry (GHCR) - reference implementation, already wired up

```bash
kubectl create secret docker-registry ghcr-push-creds \
  --docker-server=ghcr.io \
  --docker-username=<github-username> \
  --docker-password=<classic PAT with write:packages> \
  -n fawkes
```
`image-name`: `ghcr.io/<owner>/<repo>`

### GitLab Container Registry

```bash
kubectl create secret docker-registry gitlab-registry-creds \
  --docker-server=registry.gitlab.com \
  --docker-username=<gitlab-username-or-deploy-token-name> \
  --docker-password=<personal access token or deploy token, scope: write_registry> \
  -n fawkes
```
`image-name`: `registry.gitlab.com/<group>/<project>`

### Bitbucket (via a linked registry - Bitbucket itself doesn't host images)

Bitbucket has no first-party container registry; pair it with any registry
below (commonly Docker Hub or ECR) and use Bitbucket only as the git source.

### AWS ECR

ECR auth tokens expire after 12 hours, so this secret needs periodic
regeneration (a CronJob, or re-run before each pipeline batch) rather than
being a one-time setup step like the others:

```bash
aws ecr get-login-password --region <region> | \
kubectl create secret docker-registry ecr-push-creds \
  --docker-server=<account-id>.dkr.ecr.<region>.amazonaws.com \
  --docker-username=AWS \
  --docker-password-stdin \
  -n fawkes
```
`image-name`: `<account-id>.dkr.ecr.<region>.amazonaws.com/<repo>`

(Longer-term: an IRSA-bound ServiceAccount + kaniko's ECR credential helper
avoids the 12-hour rotation entirely - out of scope for this doc, flagging
as the better long-term path if AWS becomes a primary registry rather than
an example.)

### Azure Container Registry (ACR)

```bash
kubectl create secret docker-registry acr-push-creds \
  --docker-server=<registry-name>.azurecr.io \
  --docker-username=<service-principal-app-id> \
  --docker-password=<service-principal-password> \
  -n fawkes
```
`image-name`: `<registry-name>.azurecr.io/<repo>`

(Service principal needs `AcrPush` role on the registry: `az role assignment
create --assignee <app-id> --scope <acr-resource-id> --role AcrPush`.)

### Google Artifact Registry (GCR's successor - GCR itself is deprecated)

```bash
kubectl create secret docker-registry gar-push-creds \
  --docker-server=<region>-docker.pkg.dev \
  --docker-username=_json_key \
  --docker-password="$(cat service-account-key.json)" \
  -n fawkes
```
`image-name`: `<region>-docker.pkg.dev/<project>/<repository>/<image>`

(The service account needs the `roles/artifactregistry.writer` role.)

### Harbor (self-hosted)

```bash
kubectl create secret docker-registry harbor-push-creds \
  --docker-server=harbor.127.0.0.1.nip.io \
  --docker-username=<harbor-user> \
  --docker-password=<harbor-user-password-or-robot-account-token> \
  -n fawkes
```
`image-name`: `harbor.127.0.0.1.nip.io/<project>/<repo>`

Harbor's robot accounts (Project → Robot Accounts) are the better fit for a
pipeline than a real user's password - scoped to push-only on one project,
revocable independently.

### Local/native registry (e.g. a bare `registry:2` container, no auth)

```yaml
# No dockerconfig workspace needed at all - omit it from the PipelineRun.
image-name: <registry-host>:5000/<repo>
```
kaniko's `--insecure`/`--skip-tls-verify` flags (added to `build-and-push`'s
`args` in the pipeline) are needed if this registry has no valid TLS cert -
not on by default, since every other provider above uses real TLS.

---

## Adding a new provider not listed here

Nothing in the pipeline needs to change for a provider that fits the
`https://<host>/<path>.git` + `docker-registry` Secret pattern above - only
this doc needs a new row/section. A provider needing a genuinely different
auth mechanism (a cloud SDK credential helper, a custom clone protocol) would
need a change to `fetch-source`'s or `build-and-push`'s step image/script in
`platform/apps/tekton/golden-path-pipeline.yaml`.
