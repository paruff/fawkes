# Fawkes Mattermost Feedback Bot (@fawkes)

Conversational Mattermost bot for collecting feedback with natural language processing, sentiment analysis, and auto-categorization.

## Features

- 🤖 **Natural Language Interface**: Just describe your feedback naturally
- 😊 **Sentiment Analysis**: Automatically analyzes feedback sentiment using VADER
- 🏷️ **Auto-Categorization**: Intelligently categorizes feedback (UI, Performance, Documentation, etc.)
- ⭐ **Smart Rating**: Extracts or infers ratings from natural language
- 💬 **Mattermost Integration**: Simple `/feedback` slash command
- 📊 **Prometheus Metrics**: Tracks feedback submissions and sentiment
- 🔗 **Feedback API Integration**: Submits to centralized feedback service

## Quick Start

### Using the Bot in Mattermost

Simply type:

```
/feedback <your feedback here>
```

### Examples

**Positive feedback:**

```
/feedback The new UI is amazing! Love the dark mode feature.
```

Analysis: ⭐⭐⭐⭐⭐ (5/5), Sentiment: Positive 😊, Category: UI

**Performance feedback:**

```
/feedback Builds are taking 20+ minutes, way too slow
```

Analysis: ⭐⭐ (2/5), Sentiment: Negative 😞, Category: Performance

**Feature request:**

```
/feedback Would be great if we could export metrics to CSV
```

Analysis: ⭐⭐⭐⭐ (4/5), Sentiment: Neutral 😐, Category: Feature Request

**With explicit rating:**

```
/feedback Rate it 5 stars! Documentation is excellent and comprehensive.
```

Analysis: ⭐⭐⭐⭐⭐ (5/5), Sentiment: Positive 😊, Category: Documentation

## Installation

### Prerequisites

- Kubernetes cluster
- Feedback service deployed
- Mattermost instance

### Deploy to Kubernetes

```bash
# Apply Kubernetes manifests
kubectl apply -k platform/apps/feedback-bot/

# Check deployment status
kubectl get pods -n fawkes -l app=feedback-bot

# View logs
kubectl logs -n fawkes -l app=feedback-bot -f
```

### Configuration

Set environment variables:

```yaml
env:
  - name: FEEDBACK_API_URL
    value: "http://feedback-service.fawkes.svc.cluster.local:8000"
  - name: FEEDBACK_API_TOKEN
    valueFrom:
      secretKeyRef:
        name: feedback-bot-secret
        key: api-token
  - name: BOT_TOKEN
    valueFrom:
      secretKeyRef:
        name: feedback-bot-secret
        key: bot-token
  - name: MATTERMOST_URL
    value: "http://mattermost.fawkes.svc.cluster.local:8065"
  - name: EMAIL_DOMAIN
    value: "fawkes.local"
```

## Mattermost Setup

### 1. Create Slash Command

1. Go to **Main Menu** → **Integrations** → **Slash Commands**
2. Click "Add Slash Command"
3. Configure:
   - **Title:** Fawkes Feedback
   - **Command Trigger Word:** `feedback`
   - **Request URL:** `http://feedback-bot.fawkes.svc.cluster.local:8000/mattermost/slash/feedback`
   - **Request Method:** `POST`
   - **Response Username:** `@fawkes`
   - **Autocomplete:** Enable
   - **Autocomplete Hint:** `<your feedback here>`
   - **Autocomplete Description:** Submit feedback with natural language

### 2. Get Token

1. After creating the command, copy the Token
2. Set as `BOT_TOKEN` environment variable (optional for validation)

### 3. Create Bot Account (Optional)

For richer bot presence:

1. Go to **System Console** → **Integrations** → **Bot Accounts**
2. Create new bot:
   - **Username:** `fawkes`
   - **Display Name:** `Fawkes Feedback Bot`
   - **Description:** Collects feedback with NLP and sentiment analysis
   - **Icon:** Upload Fawkes logo

## Natural Language Processing

### Sentiment Analysis

The bot uses **VADER (Valence Aware Dictionary and sEntiment Reasoner)** to analyze sentiment:

- **Positive** (≥0.05): 😊 - Happy, satisfied feedback
- **Neutral** (-0.05 to 0.05): 😐 - Matter-of-fact feedback
- **Negative** (≤-0.05): 😞 - Unhappy, critical feedback

### Auto-Categorization

The bot automatically categorizes feedback based on keywords:

| Category                 | Keywords                                                    |
| ------------------------ | ----------------------------------------------------------- |
| **UI**                   | interface, design, layout, visual, button, menu, navigation |
| **Performance**          | slow, fast, speed, lag, loading, responsive, timeout        |
| **Documentation**        | docs, guide, tutorial, help, readme, instructions           |
| **CI/CD**                | build, deploy, pipeline, jenkins, argocd                    |
| **Security**             | security, vulnerability, auth, permission, access           |
| **API**                  | api, endpoint, rest, graphql, request, response             |
| **Feature Request**      | want, wish, need, could, should, feature, add               |
| **Bug**                  | bug, error, issue, problem, broken, crash, fail             |
| **Observability**        | metrics, logs, traces, monitoring, grafana, prometheus      |
| **Developer Experience** | dx, experience, workflow, productivity, friction            |

### Smart Rating

The bot can:

1. **Extract explicit ratings:** "5 stars", "4/5", "rate it 3"
2. **Infer from sentiment:**
   - Very positive (≥0.6) → 5 stars
   - Positive (≥0.2) → 4 stars
   - Neutral (≥-0.2) → 3 stars
   - Negative (≥-0.6) → 2 stars
   - Very negative (<-0.6) → 1 star

## API Usage

### Submit Feedback via API

```bash
curl -X POST http://feedback-bot.fawkes.svc.cluster.local:8000/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "text": "The new dashboard is fantastic! Much easier to navigate.",
    "user_name": "john.doe",
    "user_email": "john.doe@example.com"
  }'
```

Response:

```json
{
  "status": "success",
  "feedback_id": 123,
  "analysis": {
    "sentiment": "positive",
    "category": "UI",
    "rating": 5
  }
}
```

### Health Check

```bash
curl http://feedback-bot.fawkes.svc.cluster.local:8000/health
```

### Prometheus Metrics

```bash
curl http://feedback-bot.fawkes.svc.cluster.local:8000/metrics
```

## Prometheus Metrics

The bot exports the following metrics:

- `feedback_bot_logs_total{platform,status,sentiment,category}` - Total feedback submissions
- `feedback_bot_slash_commands_total{command,platform}` - Total slash commands received
- `feedback_bot_request_duration_seconds{endpoint}` - Request processing duration

### Example Queries

```promql
# Feedback by sentiment
sum by (sentiment) (feedback_bot_logs_total{platform="mattermost"})

# Success rate
sum(feedback_bot_logs_total{status="success"}) / sum(feedback_bot_logs_total)

# Feedback by category
sum by (category) (feedback_bot_logs_total)

# Commands per minute
rate(feedback_bot_slash_commands_total[5m])
```

## Development

### Run Locally

```bash
cd services/feedback-bot

# Install dependencies
pip install -r requirements.txt

# Set environment variables
export FEEDBACK_API_URL="http://localhost:8001"
export BOT_TOKEN="your-token"

# Run the service
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Test with curl

```bash
# Test Mattermost slash command
curl -X POST http://localhost:8000/mattermost/slash/feedback \
  -F 'token=test-token' \
  -F 'user_name=testuser' \
  -F 'user_id=test-user-id' \
  -F 'channel_id=test-channel-id' \
  -F 'text=This is a test feedback message'

# Test API endpoint
curl -X POST http://localhost:8000/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Great platform!",
    "user_name": "testuser"
  }'
```

### Build Docker Image

```bash
docker build -t feedback-bot:latest .
docker run -p 8000:8000 \
  -e FEEDBACK_API_URL="http://host.docker.internal:8001" \
  feedback-bot:latest
```

## Integration with Fawkes

The feedback bot integrates with:

1. **Feedback Service**: Submits all feedback to centralized API
2. **Mattermost**: Provides conversational interface
3. **Prometheus**: Exports metrics for monitoring
4. **Kubernetes**: Deployed as a service with health checks

All feedback submitted via the bot:

- Is analyzed for sentiment automatically
- Is auto-categorized based on content
- Has ratings extracted or inferred
- Is stored in the feedback database
- Can be viewed in Backstage dashboards
- Feeds into NPS and sentiment analytics

## Examples

### Example 1: Simple Positive Feedback

Input:

```
/feedback Love the new design!
```

Response:

```
✅ Feedback submitted successfully!

Your feedback:
> Love the new design!

My analysis:
• Sentiment: Positive 😊
• Category: UI
• Rating: ⭐⭐⭐⭐⭐ (5/5)
• ID: #42

Thank you for helping us improve Fawkes! 🎯
```

### Example 2: Detailed Performance Issue

Input:

```
/feedback The Jenkins builds are extremely slow, taking over 25 minutes to complete. This is blocking our deployments.
```

Response:

```
✅ Feedback submitted successfully!

Your feedback:
> The Jenkins builds are extremely slow, taking over 25 minutes...

My analysis:
• Sentiment: Negative 😞
• Category: CI/CD
• Rating: ⭐⭐ (2/5)
• ID: #43

Thank you for helping us improve Fawkes! 🎯
```

### Example 3: Feature Request

Input:

```
/feedback Would be awesome if we could integrate with Slack as well as Mattermost
```

Response:

```
✅ Feedback submitted successfully!

Your feedback:
> Would be awesome if we could integrate with Slack...

My analysis:
• Sentiment: Positive 😊
• Category: Feature Request
• Rating: ⭐⭐⭐⭐ (4/5)
• ID: #44

Thank you for helping us improve Fawkes! 🎯
```

## Troubleshooting

### Slash Command Not Working

1. **Check bot deployment:**

   ```bash
   kubectl get pods -n fawkes -l app=feedback-bot
   kubectl logs -n fawkes -l app=feedback-bot
   ```

2. **Verify endpoint URL** in Mattermost slash command settings

3. **Test API directly:**
   ```bash
   curl http://feedback-bot.fawkes.svc.cluster.local:8000/health
   ```

### Token Validation Errors

1. Set correct token in Kubernetes secret
2. Match token in Mattermost slash command settings
3. Or remove token validation by not setting `BOT_TOKEN`

### Connection to Feedback API Fails

1. Check feedback service is running:

   ```bash
   kubectl get svc -n fawkes feedback-service
   ```

2. Verify `FEEDBACK_API_URL` environment variable

3. Test connectivity from bot pod:
   ```bash
   kubectl exec -it -n fawkes <feedback-bot-pod> -- \
     curl http://feedback-service.fawkes.svc.cluster.local:8000/health
   ```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        Mattermost                            │
│                                                             │
│  User: /feedback The UI is great!                          │
└────────────────────────┬────────────────────────────────────┘
                         │ POST /mattermost/slash/feedback
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                  Feedback Bot Service                        │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │ Slash Cmd    │  │  NLP Parser  │  │  Sentiment   │    │
│  │ Handler      │  │  + Auto-Cat  │  │  Analyzer    │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐                       │
│  │  Rating      │  │  Prometheus  │                       │
│  │  Extractor   │  │  Metrics     │                       │
│  └──────────────┘  └──────────────┘                       │
└────────────────────────┬────────────────────────────────────┘
                         │ POST /api/v1/feedback
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                    Feedback Service                          │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │  REST API    │  │  PostgreSQL  │  │  Analytics   │    │
│  │              │  │  Database    │  │  Dashboard   │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Security Considerations

- ✅ Non-root container user (UID 10001)
- ✅ Optional token validation for slash commands
- ✅ Input validation and sanitization
- ✅ Health checks for Kubernetes
- ✅ Prometheus metrics for monitoring
- ⚠️ Use HTTPS for production slash command URLs
- ⚠️ Store tokens in Kubernetes secrets
- ⚠️ Implement rate limiting for production

## License

Apache License 2.0

## Support

- **Documentation**: See `/docs` directory
- **Issues**: https://github.com/paruff/fawkes/issues
- **Mattermost**: #fawkes-support

## AI-Readiness Checklist

A module is "AI-ready" when agents can work on it reliably. Track any gaps as GitHub issues.
See [AGENTS.md §11](../../AGENTS.md) for full context.

- [ ] Type hints on all public functions
- [ ] Docstrings on all public classes and functions
- [ ] Tests exist and are green before AI adds to them
- [ ] Module is single-purpose (not a God class/file)
- [ ] Clear, contextual error messages (no bare `raise Exception`)
- [ ] Module is covered by BDD scenarios in `tests/bdd/`
