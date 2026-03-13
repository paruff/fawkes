# Fawkes Friction Bot

Slack/Mattermost bot for logging developer friction points in real-time.

## Features

- 🤖 **Slack Integration**: `/friction` slash command for Slack
- 💬 **Mattermost Integration**: `/friction` slash command for Mattermost
- 🔗 **Insights API Integration**: Direct logging to Fawkes Insights database
- 📊 **Prometheus Metrics**: Tracking of friction logs and command usage
- 🏥 **Health Checks**: Kubernetes-ready health endpoints
- 🔐 **Token Authentication**: Optional token validation for slash commands
- 📝 **Rich Responses**: Formatted messages with success/error feedback

## Quick Start

### Using Slack

```
/friction Slow CI builds | Maven builds taking 20+ minutes | CI/CD | high
```

### Using Mattermost

```
/friction Missing documentation | No setup guide for new developers | Documentation | medium
```

### Format

```
/friction <title> | <description> | [category] | [priority]
```

- **Title** (required): Brief description of the friction point
- **Description** (required): Detailed explanation
- **Category** (optional): Default is "Developer Experience"
- **Priority** (optional): `low`, `medium` (default), `high`, `critical`

## Installation

### Prerequisites

- Kubernetes cluster
- Insights service deployed
- Slack workspace or Mattermost instance

### Deploy to Kubernetes

```bash
# Apply Kubernetes manifests
kubectl apply -k platform/apps/friction-bot/

# Check deployment status
kubectl get pods -n fawkes -l app=friction-bot

# View logs
kubectl logs -n fawkes -l app=friction-bot -f
```

### Configuration

Set environment variables:

```yaml
env:
  - name: INSIGHTS_API_URL
    value: "http://insights-service.fawkes.svc.cluster.local:8000"
  - name: BOT_TOKEN
    valueFrom:
      secretKeyRef:
        name: friction-bot-secret
        key: bot-token
  - name: MATTERMOST_URL
    value: "http://mattermost.fawkes.svc.cluster.local:8065"
```

## Slack Setup

### 1. Create Slack App

1. Go to https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. Name: "Fawkes Friction Bot"
4. Select your workspace

### 2. Create Slash Command

1. Go to "Slash Commands" → "Create New Command"
2. Command: `/friction`
3. Request URL: `https://friction-bot.your-domain.com/slack/slash/friction`
4. Short Description: "Log a friction point"
5. Usage Hint: `title | description | [category] | [priority]`

### 3. Install App

1. Go to "Install App"
2. Click "Install to Workspace"
3. Authorize the app

### 4. Get Verification Token (Optional)

1. Go to "Basic Information"
2. Copy "Verification Token"
3. Set as `BOT_TOKEN` environment variable

## Mattermost Setup

### 1. Create Slash Command

1. Go to **Main Menu** → **Integrations** → **Slash Commands**
2. Click "Add Slash Command"
3. Title: "Friction Logger"
4. Command Trigger Word: `friction`
5. Request URL: `http://friction-bot.fawkes.svc.cluster.local:8000/mattermost/slash/friction`
6. Request Method: `POST`
7. Response Username: `friction-bot`
8. Autocomplete: Enable
9. Autocomplete Hint: `title | description | [category] | [priority]`

### 2. Get Token

1. After creating the command, copy the Token
2. Set as `BOT_TOKEN` environment variable (optional, for validation)

## API Usage

### Log Friction via API

```bash
curl -X POST http://friction-bot.fawkes.svc.cluster.local:8000/api/v1/friction \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Slow deployments",
    "description": "Deployments take 15+ minutes",
    "category": "CI/CD",
    "priority": "high",
    "tags": ["deployment", "performance"],
    "author": "developer@example.com"
  }'
```

### Health Check

```bash
curl http://friction-bot.fawkes.svc.cluster.local:8000/health
```

### Metrics

```bash
curl http://friction-bot.fawkes.svc.cluster.local:8000/metrics
```

## Examples

### Example 1: CI/CD Issue

```
/friction Jenkins pipeline timeout | Pipeline times out after 60 minutes | CI/CD | high
```

Response:

```
✅ Friction point logged!

Title: Jenkins pipeline timeout
Category: CI/CD
Priority: high
ID: 123

Thanks for helping us improve the platform! 🎯
```

### Example 2: Documentation Gap

```
/friction Missing API docs | No documentation for GraphQL API | Documentation | medium
```

### Example 3: Quick Log (Minimum)

```
/friction Kubectl constantly breaks
```

Uses defaults:

- Description: Same as title
- Category: Developer Experience
- Priority: medium

## Help Command

Get usage instructions:

```
/friction
```

## Prometheus Metrics

The bot exports the following metrics:

- `friction_bot_logs_total{platform,status}` - Total friction logs (by platform and success/error)
- `friction_bot_slash_commands_total{command,platform}` - Total slash commands received
- `friction_bot_request_duration_seconds{endpoint}` - Request processing time

Query examples:

```promql
# Friction logs per platform
sum by (platform) (friction_bot_logs_total)

# Success rate
sum(friction_bot_logs_total{status="success"}) / sum(friction_bot_logs_total)

# Commands per minute
rate(friction_bot_slash_commands_total[5m])
```

## Development

### Run Locally

```bash
cd services/friction-bot

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export INSIGHTS_API_URL="http://localhost:8000"
export BOT_TOKEN="your-token"

# Run the service
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Test with curl

```bash
# Test Mattermost slash command
curl -X POST http://localhost:8000/mattermost/slash/friction \
  -F 'token=test-token' \
  -F 'user_name=testuser' \
  -F 'text=Test friction | This is a test | CI/CD | high' \
  -F 'team_id=test-team' \
  -F 'channel_id=test-channel' \
  -F 'user_id=test-user'
```

### Build Docker Image

```bash
docker build -t friction-bot:latest .
docker run -p 8000:8000 \
  -e INSIGHTS_API_URL="http://host.docker.internal:8000" \
  friction-bot:latest
```

## Integration with Fawkes

The friction bot integrates with:

1. **Insights Service**: Stores all friction logs in the insights database
2. **Prometheus**: Exports metrics for monitoring and analytics
3. **Slack/Mattermost**: Provides convenient interface for developers
4. **Kubernetes**: Deployed as a service with health checks and auto-scaling

All friction points logged via the bot:

- Are tagged with `friction` and the platform name (slack/mattermost)
- Include author information from the chat platform
- Are categorized and prioritized
- Can be viewed in Backstage dashboards
- Feed into platform improvement metrics

## Troubleshooting

### Slash Command Not Working

1. **Check bot deployment:**

   ```bash
   kubectl get pods -n fawkes -l app=friction-bot
   kubectl logs -n fawkes -l app=friction-bot
   ```

2. **Verify endpoint URL** in Slack/Mattermost settings

3. **Test API directly:**
   ```bash
   curl http://friction-bot.fawkes.svc.cluster.local:8000/health
   ```

### Token Validation Errors

1. Set correct token in Kubernetes secret
2. Match token in Slack/Mattermost slash command settings
3. Or remove token validation by not setting `BOT_TOKEN`

### Connection to Insights API Fails

1. Check Insights service is running:

   ```bash
   kubectl get svc -n fawkes insights-service
   ```

2. Verify `INSIGHTS_API_URL` environment variable

3. Test connectivity from bot pod:
   ```bash
   kubectl exec -it -n fawkes <friction-bot-pod> -- \
     curl http://insights-service.fawkes.svc.cluster.local:8000/health
   ```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Slack / Mattermost                       │
│                                                             │
│  User: /friction Slow builds | CI takes too long | CI/CD   │
└────────────────────────┬────────────────────────────────────┘
                         │ POST /slack/slash/friction
                         │ POST /mattermost/slash/friction
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Friction Bot Service                      │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Slash Cmd    │  │  Parser      │  │  Prometheus  │    │
│  │ Handler      │  │              │  │  Metrics     │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└────────────────────────┬────────────────────────────────────┘
                         │ POST /insights
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Insights Service                          │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                       │
│  │  REST API    │  │  PostgreSQL  │                       │
│  │              │  │  Database    │                       │
│  └──────────────┘  └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

## Security Considerations

- ✅ Non-root container user (UID 10001)
- ✅ Optional token validation for slash commands
- ✅ Input validation and sanitization
- ✅ Health checks for Kubernetes
- ✅ Prometheus metrics for monitoring
- ⚠️ Use HTTPS for production slash command URLs
- ⚠️ Store tokens in Kubernetes secrets, not environment variables
- ⚠️ Implement rate limiting for production use

## License

Apache License 2.0

## Support

- **Documentation**: See `/docs` directory
- **Issues**: https://github.com/paruff/fawkes/issues
- **Slack**: #fawkes-support

## AI-Readiness Checklist

A module is "AI-ready" when agents can work on it reliably. Track any gaps as GitHub issues.
See [AGENTS.md §11](../../AGENTS.md) for full context.

- [ ] Type hints on all public functions
- [ ] Docstrings on all public classes and functions
- [ ] Tests exist and are green before AI adds to them
- [ ] Module is single-purpose (not a God class/file)
- [ ] Clear, contextual error messages (no bare `raise Exception`)
- [ ] Module is covered by BDD scenarios in `tests/bdd/`
