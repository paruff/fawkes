# Feedback Widget Plugin

This plugin provides feedback collection functionality for Backstage.

## Features

- Feedback button in Backstage UI (conceptual - requires frontend implementation)
- Modal form with:
  - Rating (1-5 stars)
  - Category dropdown
  - Comment text area
  - Optional email field
- Submit feedback to backend API via proxy
- Admin page to view and manage feedback

## Configuration

The feedback widget is configured in `feedback-widget.yaml` and uses the Backstage proxy endpoint `/feedback/api` to communicate with the feedback service.

### Proxy Configuration

Added to `app-config.yaml`:

```yaml
proxy:
  endpoints:
    '/feedback/api':
      target: http://feedback-service.fawkes.svc:8000/
      changeOrigin: true
      secure: false
```

## Usage

### For Users

1. Click the feedback button in the Backstage header or sidebar
2. Fill out the feedback form:
   - Select a rating (1-5)
   - Choose a category
   - Enter your feedback comment
   - Optionally provide email for follow-up
3. Submit the feedback

### For Admins

1. Navigate to the feedback admin page
2. View all submitted feedback
3. Filter by status, category, or date
4. Update feedback status (open, in_progress, resolved, dismissed)
5. View aggregated statistics

## API Integration

The plugin communicates with the feedback service via these endpoints:

- `POST /api/v1/feedback` - Submit feedback
- `GET /api/v1/feedback` - List feedback (admin)
- `PUT /api/v1/feedback/{id}/status` - Update status (admin)
- `GET /api/v1/feedback/stats` - Get statistics (admin)

All admin endpoints require Bearer token authentication.

## Frontend Implementation Note

This configuration provides the backend infrastructure and API integration. The actual Backstage frontend plugin implementation (React components, UI elements) would require:

1. A custom Backstage plugin package (e.g., `@internal/plugin-feedback`)
2. React components for the feedback modal and admin page
3. Integration with Backstage's plugin architecture
4. Registration in Backstage's `packages/app/src/App.tsx`

For a full implementation, follow the [Backstage plugin development guide](https://backstage.io/docs/plugins/create-a-plugin).

## Development

For local testing:

```bash
# Submit test feedback
curl -X POST http://feedback.127.0.0.1.nip.io/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "UI/UX",
    "comment": "Great interface!",
    "email": "user@example.com"
  }'

# List feedback (requires admin token)
curl http://feedback.127.0.0.1.nip.io/api/v1/feedback \
  -H "Authorization: Bearer your-admin-token"
```
