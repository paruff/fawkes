# Mattermost - Team Collaboration Platform

## Purpose

Mattermost provides secure team messaging and collaboration for the Fawkes platform. It integrates with CI/CD pipelines, monitoring alerts, and supports ChatOps workflows.

## Key Features

- **Channels**: Team and project-based communication
- **Direct Messages**: Private conversations
- **File Sharing**: Document and image sharing
- **Webhooks**: Incoming/outgoing webhook integrations
- **Slash Commands**: ChatOps integration
- **Bots**: Automated notifications and workflows
- **Threads**: Organized discussion threads

## Quick Start

### Accessing Mattermost

Local development:

```bash
# Access UI
http://mattermost.127.0.0.1.nip.io
```

Default admin:

- Email: `admin@fawkes.local`
- Password: Set during first login

## Integration Points

### Jenkins Notifications

Send build notifications to Mattermost channels:

```groovy
stage('Notify') {
    steps {
        mattermostSend(
            endpoint: 'http://mattermost.127.0.0.1.nip.io/hooks/xxx',
            channel: 'ci-cd',
            color: currentBuild.result == 'SUCCESS' ? 'good' : 'danger',
            message: "Build ${env.JOB_NAME} #${env.BUILD_NUMBER}: ${currentBuild.result}"
        )
    }
}
```

### Alertmanager Integration

Configure Prometheus alerts to Mattermost:

```yaml
receivers:
  - name: mattermost
    webhook_configs:
      - url: "http://mattermost.127.0.0.1.nip.io/hooks/alerts"
        send_resolved: true
```

### ArgoCD Notifications

Notify on deployment events:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
data:
  service.webhook.mattermost: |
    url: http://mattermost.127.0.0.1.nip.io/hooks/argocd
    headers:
    - name: Content-Type
      value: application/json
```

## ChatOps Commands

Create custom slash commands for platform operations:

| Command     | Action               | Example                    |
| ----------- | -------------------- | -------------------------- |
| `/deploy`   | Trigger deployment   | `/deploy myapp production` |
| `/rollback` | Rollback deployment  | `/rollback myapp`          |
| `/status`   | Check service status | `/status jenkins`          |
| `/logs`     | View recent logs     | `/logs myapp --tail 50`    |

## Channels Structure

| Channel          | Purpose                            | Members      |
| ---------------- | ---------------------------------- | ------------ |
| `#general`       | Platform announcements             | All users    |
| `#ci-cd`         | Build and deployment notifications | Dev team     |
| `#alerts`        | Monitoring alerts                  | On-call team |
| `#incidents`     | Incident response                  | SRE team     |
| `#platform-help` | Platform support                   | All users    |

## Bot Configuration

Mattermost bot for automated workflows:

```bash
# Create bot account
curl -X POST http://mattermost.127.0.0.1.nip.io/api/v4/bots \
  -H 'Authorization: Bearer <token>' \
  -d '{"username": "fawkes-bot", "display_name": "Fawkes Platform Bot"}'
```

## Troubleshooting

### Connection Issues

```bash
# Check Mattermost pod status
kubectl get pods -n mattermost

# View logs
kubectl logs -n mattermost deployment/mattermost -f
```

### Webhook Not Working

1. Verify webhook URL is correct
2. Check incoming webhook is enabled in channel
3. Test with curl:

```bash
curl -X POST http://mattermost.127.0.0.1.nip.io/hooks/xxx \
  -H 'Content-Type: application/json' \
  -d '{"text": "Test message"}'
```

## Related Documentation

- [Mattermost Documentation](https://docs.mattermost.com/)
- [Webhooks Guide](https://developers.mattermost.com/integrate/webhooks/)
