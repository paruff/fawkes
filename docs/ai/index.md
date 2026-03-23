# AI & Machine Learning Documentation

This section covers AI-powered features, machine learning integrations, and AI usage policies for the Fawkes platform.

## AI Usage Policy

- [AI Usage Policy](usage-policy.md) - Guidelines for using AI tools in development
- [Training Quiz](training-quiz.md) - Test your understanding of AI policies
- [DORA 2025 AI Capabilities — Fawkes Alignment](dora-2025-alignment.md) - How the seven DORA 2025 AI foundations map to Fawkes practices
- [Foundation 7 Platform Quality Improvement Guide](foundation-7-platform-quality-guide.md) - Ranked actions to improve platform quality and AI effectiveness

## Agent Suggestions (review and apply to `.github/agents/`)

These files contain suggested `.github/agents/` content for manual review and application.
Copy the YAML block into the target file, remove the header comment, and commit.

| Agent | Model | Cost | Purpose | Status |
|---|---|---|---|---|
| [test-engineer](test-engineer-agent-suggestion.md) | GPT-4.1 | 0× | pytest, pytest-bdd, bats tests | ⏳ Pending review |
| [issue-writer](issue-writer-agent-suggestion.md) | Claude Sonnet 4.6 | 1× | Fully-specified GitHub issues | ⏳ Pending review |
| [code-reviewer](code-reviewer-agent-suggestion.md) | Claude Sonnet 4.6 | 1× | PR review across all layers | ⏳ Pending review |
| [infra-gitops](infra-gitops-agent-suggestion.md) | GPT-4.1 | 0× | Terraform, Helm, ArgoCD, K8s | ⏳ Pending review |
| [gpt41-default](gpt41-default-agent-suggestion.md) | GPT-4.1 | 0× | General fallback for any task | ⏳ Pending review |

## GitHub Copilot

- [GitHub Copilot Setup](copilot-setup.md) - Configure GitHub Copilot for Fawkes development
- 

## AI-Powered Features

### Vector Database & RAG

- [Vector Database](vector-database.md) - Vector database setup and usage
- [RAG Service Implementation](../implementation-notes/RAG_SERVICE_IMPLEMENTATION.md) - Retrieval-Augmented Generation service
- [Weaviate Deployment](../implementation-notes/WEAVIATE_DEPLOYMENT_SUMMARY.md) - Vector database deployment

### AI Observability

- [AI Observability Dashboard](../implementation-notes/AI_OBSERVABILITY_DASHBOARD_SUMMARY.md) - AI-powered observability insights
- [Anomaly Detection](../implementation-notes/ANOMALY_DETECTION_IMPLEMENTATION.md) - ML-based anomaly detection
- [Smart Alerting](../implementation-notes/SMART_ALERTING_IMPLEMENTATION.md) - Intelligent alerting system

## Related Documentation

- [Reference Documentation](../reference/index.md) - API references
- [How-To Guides](../how-to/index.md) - Step-by-step guides
- [Implementation Summaries](../implementation-notes/README.md) - Technical implementation details
