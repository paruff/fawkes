# Lab cluster (mmm4)

Wave 1 of Fawkes on a single k3s node (Mac mini, ARM). It rehearses the Alpha
path. It does not prove anything Azure-specific; that stays on AKS.

```bash
scripts/lab-up.sh                      # install Argo CD, hand over to Git
kubectl --context mmm4 get applications -n argocd
```

- `lab-up.sh` installs Argo CD and applies `root-application.yaml`. Argo CD then
  keeps the two ApplicationSets here in step with `main`.
- The sample app follows the `lab` branch of `python-fawkes-path-gitops`, which
  also drops that repo's `amd64` node selector.
- Pipeline runs here must pass `gitops-branch=lab`. That promotes to the lab
  branch and records no production deployment.
