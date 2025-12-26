.PHONY: help deploy-local test-bdd validate sync pre-commit-setup validate-research-structure validate-at-e0-001 validate-at-e1-001 validate-at-e1-002 validate-at-e1-003 validate-at-e1-004 validate-at-e1-005 validate-at-e1-006 validate-at-e1-007 validate-at-e1-009 validate-at-e1-012 validate-at-e2-001 validate-at-e2-002 validate-at-e2-003 validate-at-e2-004 validate-at-e2-005 validate-at-e2-006 validate-at-e2-007 validate-at-e2-008 validate-at-e2-009 validate-at-e2-010 validate-at-e3-001 validate-at-e3-002 validate-at-e3-003 validate-at-e3-004 validate-at-e3-005 validate-at-e3-006 validate-at-e3-007 validate-at-e3-008 validate-at-e3-009 validate-at-e3-010 validate-at-e3-011 validate-at-e3-012 validate-epic-3-final validate-discovery-metrics test-e2e-argocd test-e2e-integration test-e2e-integration-verbose test-e2e-integration-dry-run test-e2e-all

# Variables
NAMESPACE ?= fawkes-local
COMPONENT ?= all
ENVIRONMENT ?= dev
AZURE_RESOURCE_GROUP ?= fawkes-rg
AZURE_CLUSTER_NAME ?= fawkes-aks
ARGO_NAMESPACE ?= fawkes

help: ## Show this help message
	@echo "Fawkes Development Commands:"
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

deploy-local: ## Deploy component to local K8s (COMPONENT=backstage|argocd|all)
	@./infra/local-dev/deploy-local.sh $(NAMESPACE) $(COMPONENT)

test-bdd: ## Run BDD acceptance tests (COMPONENT=backstage|argocd|all)
	@behave tests/bdd/features --tags=@local -D namespace=$(NAMESPACE) -D component=$(COMPONENT)

validate: ## Validate manifests and run policy checks
	@./infra/local-dev/validate.sh $(NAMESPACE)

validate-resources: ## Validate resource usage stays within 70% target
	@./scripts/validate-resource-usage.sh --namespace $(NAMESPACE) --target-cpu 70 --target-memory 70

validate-research-structure: ## Validate user research repository structure
	@python3 scripts/validate-research-structure.py

sync: ## Sync to GitOps for environment (ENVIRONMENT=dev|prod)
	@./infra/local-dev/sync-to-argocd.sh $(ENVIRONMENT)

pre-commit-setup: ## Install pre-commit hooks
	@pip install pre-commit
	@pre-commit install
	@echo "✅ Pre-commit hooks installed"

terraform-validate: ## Validate Terraform configurations
	@cd infra/terraform && terraform fmt -check -recursive
	@cd infra/terraform && terraform validate

k8s-validate: ## Validate Kubernetes manifests
	@kubeval manifests/**/*.yaml
	@kustomize build manifests/overlays/local | kubectl apply --dry-run=client -f -

lint: ## Run all linters
	@pre-commit run --all-files

test-unit: ## Run unit tests
	@pytest tests/unit -v

test-integration: ## Run integration tests
	@pytest tests/integration -v

test-all: test-unit test-bdd test-integration ## Run all tests

test-e2e-argocd: ## Run ArgoCD E2E sync tests
	@./tests/e2e/argocd-sync-test.sh --namespace $(ARGO_NAMESPACE)

test-e2e-integration: ## Run complete E2E integration test (scaffold → deploy → metrics)
	@./tests/e2e/run-e2e-integration-test.sh --namespace $(NAMESPACE) --argocd-ns $(ARGO_NAMESPACE)

test-e2e-integration-verbose: ## Run E2E integration test with verbose output
	@./tests/e2e/run-e2e-integration-test.sh --namespace $(NAMESPACE) --argocd-ns $(ARGO_NAMESPACE) --verbose

test-e2e-integration-dry-run: ## Show what E2E test would do without executing
	@./tests/e2e/run-e2e-integration-test.sh --dry-run

test-e2e-all: test-e2e-argocd test-e2e-integration ## Run all E2E tests

validate-at-e0-001: ## Run AT-E0-001 acceptance test validation for Code Quality Standards
	@./scripts/validate-at-e0-001.sh

validate-at-e1-001: ## Run AT-E1-001 acceptance test validation for AKS cluster
	@./scripts/validate-at-e1-001.sh --resource-group $(AZURE_RESOURCE_GROUP) --cluster-name $(AZURE_CLUSTER_NAME)

validate-at-e1-002: ## Run AT-E1-002 acceptance test validation for GitOps/ArgoCD
	@./scripts/validate-at-e1-002.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-003: ## Run AT-E1-003 acceptance test validation for Backstage Developer Portal
	@./scripts/validate-at-e1-003.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-004: ## Run AT-E1-004 acceptance test validation for Jenkins CI/CD
	@./scripts/validate-at-e1-004.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-005: ## Run AT-E1-005 acceptance test validation for DevSecOps Security Scanning
	@./scripts/validate-at-e1-005.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-006: ## Run AT-E1-006 acceptance test validation for Observability Stack (Prometheus/Grafana)
	@./scripts/validate-at-e1-006.sh --namespace monitoring --argocd-namespace $(ARGO_NAMESPACE)

validate-at-e1-007: ## Run AT-E1-007 acceptance test validation for DORA Metrics
	@./scripts/validate-at-e1-007.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-009: ## Run AT-E1-009 acceptance test validation for Harbor Container Registry
	@./scripts/validate-at-e1-009.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-012: ## Run AT-E1-012 acceptance test validation for Full Platform Workflow
	@./scripts/validate-at-e1-012.sh --verify-metrics --verify-observability

validate-at-e2-001: ## Run AT-E2-001 acceptance test validation for AI Coding Assistant (GitHub Copilot)
	@./scripts/validate-at-e2-001.sh --namespace $(NAMESPACE)

validate-at-e2-002: ## Run AT-E2-002 acceptance test validation for RAG Service
	@./scripts/validate-at-e2-002.sh --namespace $(NAMESPACE)

validate-at-e2-003: ## Run AT-E2-003 acceptance test validation for DataHub Data Catalog
	@./scripts/validate-at-e2-003.sh --namespace $(NAMESPACE)

validate-at-e2-004: ## Run AT-E2-004 acceptance test validation for Data Quality (Great Expectations)
	@./scripts/validate-at-e2-004.sh --namespace $(NAMESPACE)

validate-at-e2-005: ## Run AT-E2-005 acceptance test validation for VSM (Value Stream Mapping)
	@./scripts/validate-at-e2-005.sh --namespace $(NAMESPACE)

validate-at-e2-006: ## Run AT-E2-006 acceptance test validation for AI Governance
	@./scripts/validate-at-e2-006.sh --namespace $(NAMESPACE)

validate-at-e2-007: ## Run AT-E2-007 acceptance test validation for AI Code Review Bot
	@./scripts/validate-at-e2-007.sh --namespace $(NAMESPACE)

validate-at-e2-008: ## Run AT-E2-008 acceptance test validation for Unified GraphQL Data API
	@./scripts/validate-at-e2-008.sh --namespace $(NAMESPACE)

validate-at-e2-009: ## Run AT-E2-009 acceptance test validation for AI Observability Dashboard
	@./scripts/validate-at-e2-009.sh --namespace $(NAMESPACE)

validate-at-e2-010: ## Run AT-E2-010 acceptance test validation for Feedback Analytics Dashboard
	@./scripts/validate-at-e2-010.sh --namespace $(NAMESPACE)

validate-at-e3-001: ## Run AT-E3-001 acceptance test validation for Research Infrastructure
	@./scripts/validate-at-e3-001.sh --namespace $(NAMESPACE)

validate-at-e3-002: ## Run AT-E3-002 acceptance test validation for SPACE Framework Implementation
	@./scripts/validate-at-e3-002.sh $(NAMESPACE)

validate-at-e3-003: ## Run AT-E3-003 acceptance test validation for Multi-Channel Feedback System
	@./scripts/validate-at-e3-003.sh --namespace $(NAMESPACE) --monitoring-ns monitoring

validate-at-e3-004: ## Run AT-E3-004 acceptance test validation for Design System Component Library
	@./scripts/validate-at-e3-004.sh

validate-at-e3-005: ## Run AT-E3-005 acceptance test validation for Journey Mapping
	@./scripts/validate-at-e3-005.sh

validate-at-e3-009: ## Run AT-E3-009 acceptance test validation for Accessibility WCAG 2.1 AA
	@./scripts/validate-at-e3-009.sh --namespace $(NAMESPACE)

validate-at-e3-006: ## Run AT-E3-006 acceptance test validation for Feature Flags (Unleash)
	@./scripts/validate-at-e3-006.sh --namespace $(NAMESPACE)

validate-at-e3-007: ## Run AT-E3-007 acceptance test validation for Event Tracking Infrastructure
	@./scripts/validate-at-e3-007.sh --namespace $(NAMESPACE)

validate-at-e3-008: ## Run AT-E3-008 acceptance test validation for Continuous Discovery Process
	@./scripts/validate-at-e3-008.sh --namespace $(NAMESPACE)

validate-at-e3-010: ## Run AT-E3-010 acceptance test validation for Usability Testing Infrastructure
	@./scripts/validate-at-e3-010.sh --namespace $(NAMESPACE)

validate-at-e3-011: ## Run AT-E3-011 acceptance test validation for Product Analytics Platform
	@./scripts/validate-product-analytics.sh --namespace $(NAMESPACE)

validate-at-e3-012: ## Run AT-E3-012 acceptance test validation for Complete Epic 3 Documentation
	@./scripts/validate-at-e3-012.sh --namespace $(NAMESPACE)

validate-epic-3-final: ## Run comprehensive Epic 3 final validation (AT-E3-008, 010, 011, 012)
	@./scripts/validate-epic-3-final.sh --namespace $(NAMESPACE)

validate-discovery-metrics: ## Run validation for Discovery Metrics Dashboard (Issue #105)
	@./scripts/validate-discovery-metrics.sh $(NAMESPACE)

clean-local: ## Clean up local K8s deployments
	@kubectl delete namespace $(NAMESPACE) --ignore-not-found=true

setup-vscode: ## Configure VS Code for vibe coding
	@./scripts/helpers/setup-vscode-extensions.sh
	@echo "✅ VS Code configured for Fawkes vibe coding"

# Docker Desktop K8s helpers
k8s-status: ## Check local K8s cluster status
	@kubectl cluster-info
	@kubectl get nodes
	@kubectl get namespaces

k8s-logs: ## Tail logs for component (COMPONENT=backstage)
	@kubectl logs -f -n $(NAMESPACE) -l app=$(COMPONENT) --tail=100

k8s-describe: ## Describe component resources (COMPONENT=backstage)
	@kubectl describe deployment/$(COMPONENT) -n $(NAMESPACE)
	@kubectl describe service/$(COMPONENT) -n $(NAMESPACE)

# ArgoCD helpers
argocd-status: ## Show ArgoCD application status
	@argocd app list
	@argocd app get fawkes-$(ENVIRONMENT)

argocd-sync: ## Force ArgoCD sync
	@argocd app sync fawkes-$(ENVIRONMENT)

argocd-diff: ## Show diff between Git and cluster
	@argocd app diff fawkes-$(ENVIRONMENT)

# Documentation
docs-serve: ## Serve documentation locally
	@mkdocs serve -a localhost:8000

docs-build: ## Build documentation
	@mkdocs build

# Development workflow
dev-loop: deploy-local test-bdd ## Quick development loop: deploy + test

vibe-start: ## Start vibe coding session
	@echo "🚀 Starting Fawkes vibe coding session..."
	@echo "1. Write BDD feature: vim tests/bdd/features/my-feature.feature"
	@echo "2. Generate code: Open Copilot Chat (Ctrl+Shift+I)"
	@echo "3. Deploy local: make deploy-local COMPONENT=my-component"
	@echo "4. Test: make test-bdd"
	@echo "5. Iterate: Edit → Deploy → Test"
	@echo "6. Sync: make sync ENVIRONMENT=dev"

validate-jcasc: ## Validate Jenkins Configuration as Code (JCasC) files
	@echo "🔍 Validating Jenkins Configuration as Code..."
	@python scripts/validate-jcasc.py

validate-jenkins: validate-jcasc ## Alias for validate-jcasc

validate-issue-109: ## Validate Code Quality Standards implementation (Issue #109)
	@./scripts/validate-issue-109.sh

validate-issue-112: ## Validate Code Quality Standards Documentation (Issue #112)
	@./scripts/validate-issue-112.sh

## Azure Infrastructure Management
.PHONY: azure-init azure-plan azure-apply azure-destroy azure-refresh-kubeconfig azure-clean-rebuild azure-access

azure-init: ## Initialize Terraform for Azure
	@echo "🔧 Initializing Terraform for Azure..."
	@cd infra/azure && terraform init -upgrade

azure-plan: ## Plan Azure infrastructure changes
	@echo "📋 Planning Azure infrastructure changes..."
	@echo "🔐 Setting Azure credentials from az CLI..."
	@cd infra/azure && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		export ARM_TENANT_ID=$$(az account show --query tenantId -o tsv) && \
		echo "✅ Using subscription: $$ARM_SUBSCRIPTION_ID" && \
		terraform plan -out=tfplan

azure-apply: ## Apply Azure infrastructure changes
	@echo "🚀 Applying Azure infrastructure changes..."
	@cd infra/azure && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		export ARM_TENANT_ID=$$(az account show --query tenantId -o tsv) && \
		terraform apply tfplan
	@echo "✅ Changes applied. Refreshing kubeconfig..."
	@sleep 5
	@$(MAKE) azure-refresh-kubeconfig

azure-refresh-kubeconfig: ## Refresh AKS kubeconfig and test connectivity
	@echo "🔑 Refreshing AKS credentials..."
	@az aks get-credentials -g fawkes-rg -n fawkes-dev --overwrite-existing
	@echo "🔐 Converting kubeconfig to azurecli auth..."
	@kubelogin convert-kubeconfig -l azurecli
	@echo "✅ Testing connectivity..."
	@kubectl get nodes -o wide || echo "⚠️  Cluster unreachable - see troubleshooting guide"

azure-destroy: ## Destroy Azure infrastructure (use with caution!)
	@echo "⚠️  WARNING: This will destroy all Azure infrastructure!"
	@echo "⚠️  Press Ctrl+C within 10 seconds to cancel..."
	@sleep 10
	@echo "💥 Destroying infrastructure..."
	@cd infra/azure && \
		export ARM_SUBSCRIPTION_ID=$$(az account show --query id -o tsv) && \
		export ARM_TENANT_ID=$$(az account show --query tenantId -o tsv) && \
		terraform destroy -auto-approve

azure-clean-rebuild: ## Clean rebuild of Azure infrastructure (destroy + recreate)
	@echo "🔄 Starting clean rebuild of Azure infrastructure"
	@echo "⚠️  This will:"
	@echo "   1. Destroy existing cluster"
	@echo "   2. Clean Terraform state"
	@echo "   3. Reinitialize providers"
	@echo "   4. Create new public cluster with IPv4 access"
	@echo "   5. Test connectivity"
	@echo ""
	@echo "⚠️  Press Ctrl+C within 10 seconds to cancel..."
	@sleep 10
	@echo ""
	@echo "Step 1/5: Destroying existing infrastructure..."
	@$(MAKE) azure-destroy || echo "Destroy failed or nothing to destroy"
	@echo ""
	@echo "Step 2/5: Cleaning Terraform state..."
	@cd infra/azure && rm -rf .terraform .terraform.lock.hcl terraform.tfstate.backup
	@echo "✅ State cleaned"
	@echo ""
	@echo "Step 3/5: Reinitializing Terraform..."
	@$(MAKE) azure-init
	@echo ""
	@echo "Step 4/5: Planning new infrastructure..."
	@$(MAKE) azure-plan
	@echo ""
	@echo "Step 5/5: Applying new infrastructure (this takes ~15-20 minutes)..."
	@$(MAKE) azure-apply
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "✅ Clean rebuild complete!"
	@echo "════════════════════════════════════════════════════════════════"
	@kubectl get nodes -o wide

azure-access: ## Show access information for Azure cluster and services
	@./scripts/access-summary.sh azure

## Platform Access Management
.PHONY: access access-argocd access-jenkins access-backstage access-grafana

access: ## Show access information for all platform services
	@./scripts/access-summary.sh

access-argocd: ## Show ArgoCD access information and open port-forward
	@./scripts/access-summary.sh argocd

access-jenkins: ## Show Jenkins access information and open port-forward
	@./scripts/access-summary.sh jenkins

access-backstage: ## Show Backstage access information and open port-forward
	@./scripts/access-summary.sh backstage

access-grafana: ## Show Grafana access information and open port-forward
	@./scripts/access-summary.sh grafana
