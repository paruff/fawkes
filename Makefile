.PHONY: help deploy-local test-bdd validate sync pre-commit-setup validate-at-e1-001 validate-at-e1-002 validate-at-e1-003

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

validate-at-e1-001: ## Run AT-E1-001 acceptance test validation for AKS cluster
	@./scripts/validate-at-e1-001.sh --resource-group $(AZURE_RESOURCE_GROUP) --cluster-name $(AZURE_CLUSTER_NAME)

validate-at-e1-002: ## Run AT-E1-002 acceptance test validation for GitOps/ArgoCD
	@./scripts/validate-at-e1-002.sh --namespace $(ARGO_NAMESPACE)

validate-at-e1-003: ## Run AT-E1-003 acceptance test validation for Backstage Developer Portal
	@./scripts/validate-at-e1-003.sh --namespace $(ARGO_NAMESPACE)

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
