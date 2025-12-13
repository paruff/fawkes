# Validation Checklist: Azure Load Balancer and Ingress

Use this checklist to verify your Azure Load Balancer and Ingress deployment.

## Prerequisites Validation

- [ ] Azure AKS cluster is running
- [ ] kubectl is configured and connected to the cluster
- [ ] ArgoCD is installed (optional, for GitOps deployment)
- [ ] Azure CLI is installed (for DNS and resource verification)

## Task 2.1: nginx-ingress Controller

### Deployment

- [ ] Applied ingress-nginx ArgoCD Application:
  ```bash
  kubectl apply -f platform/apps/ingress-nginx/ingress-nginx-azure-application.yaml
  ```

- [ ] Namespace created:
  ```bash
  kubectl get namespace ingress-nginx
  # Expected: ingress-nginx namespace exists
  ```

- [ ] Deployment is ready:
  ```bash
  kubectl get deployment ingress-nginx-controller -n ingress-nginx
  # Expected: 2/2 READY
  ```

- [ ] Pods are running:
  ```bash
  kubectl get pods -n ingress-nginx
  # Expected: 2+ controller pods in Running state
  ```

### Load Balancer Configuration

- [ ] Service type is LoadBalancer:
  ```bash
  kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.type}'
  # Expected: LoadBalancer
  ```

- [ ] External IP is assigned:
  ```bash
  kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
  # Expected: IP address (not <pending>)
  ```

- [ ] Azure Load Balancer health probe is configured:
  ```bash
  kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.metadata.annotations.service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path}'
  # Expected: /healthz
  ```

- [ ] External traffic policy is Local:
  ```bash
  kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.externalTrafficPolicy}'
  # Expected: Local
  ```

### High Availability

- [ ] HorizontalPodAutoscaler is configured:
  ```bash
  kubectl get hpa ingress-nginx-controller -n ingress-nginx
  # Expected: HPA exists with min=2, max=10
  ```

- [ ] Pod anti-affinity is configured:
  ```bash
  kubectl get deployment ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.template.spec.affinity}'
  # Expected: podAntiAffinity configuration present
  ```

### Metrics and Monitoring

- [ ] Metrics service exists:
  ```bash
  kubectl get svc ingress-nginx-controller-metrics -n ingress-nginx
  # Expected: Service exists
  ```

- [ ] ServiceMonitor is created (requires Prometheus Operator):
  ```bash
  kubectl get servicemonitor ingress-nginx-controller -n ingress-nginx
  # Expected: ServiceMonitor exists (or skip if Prometheus Operator not installed)
  ```

- [ ] PrometheusRule is created:
  ```bash
  kubectl get prometheusrule ingress-nginx -n ingress-nginx
  # Expected: PrometheusRule exists (or skip if Prometheus Operator not installed)
  ```

### Validation Script

- [ ] Run validation script:
  ```bash
  ./platform/apps/ingress-nginx/validate-azure.sh
  # Expected: All checks pass
  ```

### Azure Resources

- [ ] Azure Load Balancer exists (requires Azure CLI):
  ```bash
  az network lb list --resource-group MC_fawkes-rg_fawkes-aks_eastus -o table
  # Expected: Load Balancer listed with kubernetes prefix
  ```

## Task 2.2: Azure DNS (Optional)

### Terraform Configuration

- [ ] DNS variables configured in `infra/azure/terraform.tfvars`:
  ```
  dns_zone_name = "fawkes.yourdomain.com"
  create_dns_records = true
  ```

- [ ] Terraform initialized:
  ```bash
  cd infra/azure && terraform init
  # Expected: Success
  ```

- [ ] Terraform planned:
  ```bash
  terraform plan
  # Expected: Shows DNS zone and A records to be created
  ```

### DNS Deployment

- [ ] Terraform applied:
  ```bash
  terraform apply
  # Expected: DNS zone and A records created
  ```

- [ ] DNS zone exists:
  ```bash
  az network dns zone show -g fawkes-rg -n fawkes.yourdomain.com
  # Expected: DNS zone details
  ```

- [ ] A records created:
  ```bash
  az network dns record-set a list -g fawkes-rg -z fawkes.yourdomain.com -o table
  # Expected: @ and * records pointing to ingress IP
  ```

### DNS Delegation

- [ ] Nameservers obtained:
  ```bash
  terraform output dns_zone_name_servers
  # Expected: 4 Azure DNS nameservers
  ```

- [ ] Domain registrar updated with nameservers

- [ ] DNS resolution working (may take up to 48 hours):
  ```bash
  dig test.fawkes.yourdomain.com
  # Expected: Resolves to ingress IP
  ```

## Task 2.3: cert-manager

### Deployment

- [ ] Applied cert-manager ArgoCD Application:
  ```bash
  kubectl apply -f platform/apps/cert-manager/cert-manager-application.yaml
  ```

- [ ] Namespace created:
  ```bash
  kubectl get namespace cert-manager
  # Expected: cert-manager namespace exists
  ```

- [ ] Deployments are ready:
  ```bash
  kubectl get deployment -n cert-manager
  # Expected: cert-manager, cert-manager-webhook, cert-manager-cainjector all ready
  ```

- [ ] Pods are running:
  ```bash
  kubectl get pods -n cert-manager
  # Expected: All pods in Running state
  ```

### CRDs Installation

- [ ] CRDs are installed:
  ```bash
  kubectl get crd | grep cert-manager
  # Expected: 6 CRDs (certificates, certificaterequests, challenges, clusterissuers, issuers, orders)
  ```

### ClusterIssuers Configuration

- [ ] Email address updated in ClusterIssuer files:
  ```bash
  grep "email:" platform/apps/cert-manager/cluster-issuer-*.yaml
  # Expected: Your actual email, not platform-team@example.com
  ```

- [ ] ClusterIssuers applied:
  ```bash
  kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-staging.yaml
  kubectl apply -f platform/apps/cert-manager/cluster-issuer-letsencrypt-prod.yaml
  ```

- [ ] ClusterIssuers are ready:
  ```bash
  kubectl get clusterissuer
  # Expected: letsencrypt-staging and letsencrypt-prod both Ready=True
  ```

### Validation Script

- [ ] Run validation script:
  ```bash
  ./platform/apps/cert-manager/validate.sh
  # Expected: All checks pass
  ```

## Testing

### Test Ingress Deployment

- [ ] Deploy test echo server:
  ```bash
  kubectl apply -f platform/apps/ingress-nginx/test-ingress.yaml
  ```

- [ ] Test namespace created:
  ```bash
  kubectl get namespace ingress-test
  # Expected: Namespace exists
  ```

- [ ] Echo server running:
  ```bash
  kubectl get pods -n ingress-test
  # Expected: echo-server pod in Running state
  ```

### HTTP Testing

- [ ] Test HTTP access with nip.io:
  ```bash
  EXTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
  curl http://test.${EXTERNAL_IP}.nip.io
  # Expected: Echo server response (JSON with request details)
  ```

- [ ] Test HTTP access with custom domain (if DNS configured):
  ```bash
  curl http://test.fawkes.yourdomain.com
  # Expected: Echo server response
  ```

### TLS Certificate Testing

- [ ] Create test ingress with TLS:
  ```yaml
  # Create ingress with cert-manager annotation
  # Use letsencrypt-staging first!
  ```

- [ ] Certificate resource created:
  ```bash
  kubectl get certificate -n ingress-test
  # Expected: Certificate resource exists
  ```

- [ ] CertificateRequest created:
  ```bash
  kubectl get certificaterequest -n ingress-test
  # Expected: CertificateRequest exists
  ```

- [ ] Certificate issued (may take 1-2 minutes):
  ```bash
  kubectl get certificate -n ingress-test -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}'
  # Expected: True
  ```

- [ ] TLS secret created:
  ```bash
  kubectl get secret -n ingress-test | grep tls
  # Expected: TLS secret exists
  ```

- [ ] Test HTTPS access:
  ```bash
  curl https://test.fawkes.yourdomain.com
  # Expected: Successful HTTPS connection
  ```

## Azure Resources Verification

### Load Balancer

- [ ] Load Balancer rules exist:
  ```bash
  az network lb rule list --resource-group MC_fawkes-rg_fawkes-aks_eastus --lb-name kubernetes -o table
  # Expected: Rules for ports 80 and 443
  ```

- [ ] Health probes configured:
  ```bash
  az network lb probe list --resource-group MC_fawkes-rg_fawkes-aks_eastus --lb-name kubernetes -o table
  # Expected: Health probe for /healthz
  ```

### Public IP

- [ ] Public IP exists:
  ```bash
  az network public-ip list --resource-group MC_fawkes-rg_fawkes-aks_eastus -o table
  # Expected: Public IP with kubernetes prefix
  ```

## Monitoring and Alerting

### Prometheus Metrics

- [ ] Metrics endpoints accessible:
  ```bash
  kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller-metrics 9402:10254 &
  curl http://localhost:9402/metrics | grep nginx_ingress_controller_requests
  # Expected: Metrics data returned
  ```

- [ ] cert-manager metrics accessible:
  ```bash
  kubectl port-forward -n cert-manager svc/cert-manager 9402:9402 &
  curl http://localhost:9402/metrics | grep certmanager_certificate
  # Expected: Certificate metrics data
  ```

### Alerts

- [ ] PrometheusRules configured:
  ```bash
  kubectl get prometheusrule -n ingress-nginx
  kubectl get prometheusrule -n cert-manager
  # Expected: Rules for ingress and certificates
  ```

## Documentation

- [ ] Read setup guide: `docs/azure-ingress-setup.md`
- [ ] Read quickstart guide: `docs/azure-ingress-quickstart.md`
- [ ] Read implementation summary: `docs/azure-ingress-implementation-summary.md`
- [ ] Read nginx-ingress README: `platform/apps/ingress-nginx/README.md`
- [ ] Read cert-manager README: `platform/apps/cert-manager/README.md`

## Common Issues Resolved

If you encounter any issues, check the following:

### External IP Pending
- Wait 2-3 minutes for Azure to provision the Load Balancer
- Check service events: `kubectl describe svc ingress-nginx-controller -n ingress-nginx`

### Certificate Not Issuing
- Verify DNS points to ingress IP: `dig +short yourapp.fawkes.yourdomain.com`
- Check challenge status: `kubectl get challenge -A`
- Check cert-manager logs: `kubectl logs -n cert-manager deployment/cert-manager`
- Verify ClusterIssuer is ready: `kubectl describe clusterissuer letsencrypt-prod`

### 404 Not Found
- Verify ingress resource: `kubectl describe ingress <name> -n <namespace>`
- Check backend service exists: `kubectl get svc <name> -n <namespace>`
- Check controller logs: `kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller`

### DNS Not Resolving
- Wait up to 48 hours for DNS propagation
- Verify nameserver delegation: `dig NS fawkes.yourdomain.com`
- Check Azure DNS records: `az network dns record-set a list -g fawkes-rg -z fawkes.yourdomain.com`

## Final Verification

All items checked? You're ready to use Azure Load Balancer and Ingress!

Summary:
- ✅ nginx-ingress deployed with Azure Load Balancer
- ✅ Azure Load Balancer created with health probes
- ✅ Public IP assigned
- ✅ DNS configured (if enabled)
- ✅ cert-manager deployed
- ✅ Let's Encrypt ClusterIssuers configured
- ✅ Test ingress working
- ✅ TLS certificates issuing

Next steps:
1. Deploy your application services
2. Create Ingress resources with cert-manager annotations
3. Monitor certificate status
4. Set up alerts for expiring certificates
5. Configure rate limiting and WAF (optional)
