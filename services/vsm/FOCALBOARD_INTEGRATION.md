# Focalboard Integration Quick Start Guide

## Overview

This guide provides quick instructions for using the VSM-Focalboard integration.

## Setting Up Webhooks

### 1. Configure Focalboard Webhook

In Focalboard/Mattermost settings, create a webhook:

```
Webhook URL: http://vsm-service.fawkes.svc:8000/api/v1/focalboard/webhook
Events: 
  - card.created
  - card.moved
  - card.updated
  - card.deleted
```

### 2. Test Webhook

Send a test webhook:

```bash
curl -X POST http://vsm-service.fawkes.svc:8000/api/v1/focalboard/webhook \
  -H "Content-Type: application/json" \
  -d '{
    "action": "card.created",
    "card": {
      "id": "card-123",
      "title": "My New Feature",
      "boardId": "board-1",
      "status": "Backlog",
      "createAt": 1640000000000,
      "updateAt": 1640000000000
    },
    "boardId": "board-1",
    "workspaceId": "workspace-1"
  }'
```

## Column-to-Stage Mapping

Default mappings:

| Focalboard Column | VSM Stage |
|-------------------|-----------|
| Backlog, To Do | Backlog |
| Design | Design |
| Development, In Progress | Development |
| Code Review, In Review | Code Review |
| Testing | Testing |
| Deployment Approval | Deployment Approval |
| Deploy | Deploy |
| Production, Done | Production |

### View Mappings

```bash
curl http://vsm-service.fawkes.svc:8000/api/v1/focalboard/stages/mapping
```

## Manual Board Sync

Sync entire Focalboard board:

```bash
curl -X POST http://vsm-service.fawkes.svc:8000/api/v1/focalboard/sync \
  -H "Content-Type: application/json" \
  -d '{"board_id": "your-board-id"}'
```

## Installing the VSM Metrics Widget

### 1. Build Widget

```bash
cd services/vsm/focalboard-widget
npm install
npm run build
```

### 2. Deploy to Focalboard

```bash
# Copy files to Focalboard plugins directory
sudo cp manifest.json /opt/focalboard/plugins/vsm-metrics-widget/
sudo cp dist/main.js /opt/focalboard/plugins/vsm-metrics-widget/

# Restart Focalboard
sudo systemctl restart focalboard
```

### 3. Configure Widget

In Focalboard:
1. Add new widget to board
2. Select "VSM Flow Metrics"
3. Configure:
   - **VSM API URL**: `http://vsm-service.fawkes.svc:8000/api/v1`
   - **Refresh Interval**: `30` (seconds)
   - **Show Bottleneck Warnings**: `true`

## Verifying Integration

### Check Integration Status

```bash
curl http://vsm-service.fawkes.svc:8000/ | jq '.integrations.focalboard'
```

Should return `true`.

### Verify Work Items

After creating cards in Focalboard:

```bash
curl http://vsm-service.fawkes.svc:8000/api/v1/work-items | jq
```

Look for work items with titles matching your Focalboard cards.

### Check Flow Metrics

```bash
curl http://vsm-service.fawkes.svc:8000/api/v1/metrics?days=7 | jq
```

## Troubleshooting

### Webhooks Not Working

1. Check VSM service logs:
   ```bash
   kubectl logs -n fawkes deployment/vsm-service -f
   ```

2. Verify webhook endpoint is accessible:
   ```bash
   curl http://vsm-service.fawkes.svc:8000/api/v1/health
   ```

3. Check Focalboard webhook configuration

### Widget Not Loading

1. Check browser console for errors
2. Verify VSM API URL is correct in widget settings
3. Check CORS settings if needed
4. Verify widget files are deployed correctly

### Cards Not Syncing

1. Check column name matches mapping (case-insensitive)
2. Verify webhook is configured correctly
3. Check VSM service logs for errors
4. Ensure database is accessible

## API Reference

### Webhook Endpoint

**POST** `/api/v1/focalboard/webhook`

Receives Focalboard webhook events.

**Request Body**:
```json
{
  "action": "card.created|card.moved|card.updated|card.deleted",
  "card": {
    "id": "string",
    "title": "string",
    "boardId": "string",
    "status": "string",
    "createAt": 0,
    "updateAt": 0
  },
  "boardId": "string",
  "workspaceId": "string"
}
```

**Response**: `200 OK`

### Manual Sync Endpoint

**POST** `/api/v1/focalboard/sync`

Manually sync a Focalboard board.

**Request Body**:
```json
{
  "board_id": "string"
}
```

**Response**:
```json
{
  "status": "completed",
  "synced_count": 10,
  "failed_count": 0,
  "details": ["..."]
}
```

### Sync Work Item to Focalboard

**GET** `/api/v1/focalboard/work-items/{work_item_id}/sync-to-focalboard`

Push a VSM work item to Focalboard.

**Response**:
```json
{
  "status": "success",
  "work_item_id": 123,
  "focalboard_column": "Development",
  "message": "..."
}
```

### Get Stage Mapping

**GET** `/api/v1/focalboard/stages/mapping`

Get column-to-stage mapping.

**Response**:
```json
{
  "column_to_stage": {
    "backlog": "Backlog",
    "development": "Development",
    ...
  }
}
```

## Best Practices

1. **Column Names**: Use standard column names for automatic mapping
2. **Board Setup**: Keep column order matching VSM stage flow
3. **WIP Limits**: Set WIP limits in VSM to enable bottleneck detection
4. **Widget Placement**: Add widget to all active boards for visibility
5. **Refresh Rate**: Balance between real-time updates and API load

## Support

- Documentation: `/services/vsm/README.md`
- Widget Guide: `/services/vsm/focalboard-widget/README.md`
- Issues: https://github.com/paruff/fawkes/issues
