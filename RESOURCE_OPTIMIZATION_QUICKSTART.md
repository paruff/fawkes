# Quick Start: Resource Optimization Validation

## What Was Done

Resource allocations optimized for all 25+ Fawkes platform components to maintain <70% CPU/Memory utilization.

**Result:**
- 35% reduction in CPU requests
- 40% reduction in CPU limits
- 24% reduction in memory requests
- 27% reduction in memory limits
- 15-20% more capacity for applications

## Quick Validation

### 1. Check Resource Usage

```bash
# Automated validation
make validate-resources

# Or directly
./scripts/validate-resource-usage.sh --namespace fawkes
```

### 2. Monitor Pod Health

```bash
# Check pods are running
kubectl get pods -n fawkes

# Check resource usage
kubectl top pods -n fawkes

# Check for evictions
kubectl get pods -A --field-selector=status.phase=Failed
```

### 3. Check Node Capacity

```bash
# Node resource usage
kubectl top nodes

# Node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"
```

## Performance Baselines

| Metric | Target | Command to Test |
|--------|--------|-----------------|
| Backstage Load | <2s (P95) | Open portal in browser, measure load time |
| API Response | <200ms (P95) | `kubectl logs -n fawkes -l app=backstage` |
| Jenkins Queue | <30s (P95) | Check Jenkins dashboard queue time |
| ArgoCD Sync | <30s (P95) | Trigger sync, monitor completion |

## Acceptance Criteria

- [x] **Resource limits tuned** - All components have limits
- [ ] **CPU <70% average** - Monitor for 48h
- [ ] **Memory <70% average** - Monitor for 48h
- [ ] **No evictions** - Check daily
- [ ] **Performance OK** - Run load tests

## Key Files

| File | Purpose |
|------|---------|
| [RESOURCE_OPTIMIZATION_SUMMARY.md](RESOURCE_OPTIMIZATION_SUMMARY.md) | Detailed change log |
| [docs/resource-sizing-guide.md](docs/resource-sizing-guide.md) | Complete sizing guide |
| [scripts/validate-resource-usage.sh](scripts/validate-resource-usage.sh) | Validation script |

## Troubleshooting

### Pod Evicted

```bash
# Check which pod was evicted
kubectl get pods -A --field-selector=status.phase=Failed

# Check logs before eviction
kubectl logs <pod-name> -n fawkes --previous

# Describe for eviction reason
kubectl describe pod <pod-name> -n fawkes
```

**Fix**: Increase memory requests/limits for that component

### High CPU Usage

```bash
# Check which pod
kubectl top pods -n fawkes --sort-by=cpu

# Check throttling
kubectl describe pod <pod-name> -n fawkes | grep -i throttl
```

**Fix**: Increase CPU limits (but keep requests low)

### Performance Degradation

```bash
# Check response times
kubectl logs -n fawkes -l app=backstage --tail=100

# Check Prometheus metrics
kubectl port-forward -n monitoring svc/prometheus-prometheus 9090:9090
# Visit http://localhost:9090
```

**Fix**: Identify bottleneck component and adjust resources

## Rollback

If critical issues occur:

```bash
# Full rollback
git revert 5d72997 a373571 38664b5
git push origin copilot/optimize-resource-usage
# Wait for ArgoCD auto-sync

# Emergency scale-up (single component)
kubectl patch deployment backstage -n fawkes \
  --patch '{"spec":{"template":{"spec":{"containers":[{"name":"backstage","resources":{"limits":{"cpu":"2","memory":"2Gi"}}}]}}}}'
```

## Monitoring Setup

Add Prometheus alerts (see `docs/resource-sizing-guide.md`):

```yaml
# High CPU usage alert
- alert: HighCPUUsage
  expr: (container_cpu_usage / container_cpu_limit) > 0.7
  for: 15m

# High memory usage alert
- alert: HighMemoryUsage
  expr: (container_memory_usage / container_memory_limit) > 0.7
  for: 15m
```

## Support

- **Documentation**: See files listed above
- **Issue**: #35 - Resource optimization and tuning
- **Script Help**: `./scripts/validate-resource-usage.sh --help`

---

**Status**: ✅ Ready for deployment validation
**Last Updated**: 2025-12-16
