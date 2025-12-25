# Enhanced Feedback Widget Plugin

This plugin provides comprehensive feedback collection functionality for Backstage with screenshot capture, GitHub integration, and contextual awareness.

## Features

### ✨ Core Capabilities
- **Contextual Feedback**: Automatically captures page URL, browser info, and user agent
- **Screenshot Capture**: Users can include screenshots with their feedback
- **Multiple Feedback Types**: Support for general feedback, bug reports, and feature requests
- **GitHub Integration**: Automatically creates GitHub issues from feedback submissions
- **Sentiment Analysis**: Automatic sentiment classification of feedback comments
- **Admin Dashboard**: View and manage all feedback with filtering and statistics

### 🎯 Feedback Types

1. **General Feedback** - Share thoughts and suggestions
   - Does not create GitHub issues by default
   - Useful for general comments and praise

2. **Bug Report** - Report problems or errors
   - Automatically creates GitHub issue with `bug` label
   - Includes screenshot if provided
   - Captures browser and context information

3. **Feature Request** - Suggest new features or improvements
   - Automatically creates GitHub issue with `enhancement` label
   - Linked back to feedback database for tracking

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

### Environment Variables

The feedback service requires the following environment variables:

```yaml
# Required
DATABASE_URL: postgresql://user:pass@host:5432/feedback_db
ADMIN_TOKEN: your-admin-token

# Optional - for GitHub integration
GITHUB_TOKEN: ghp_your_github_token
GITHUB_OWNER: paruff
GITHUB_REPO: fawkes
```

## Usage

### For Users

1. **Submit Feedback**:
   - Click the feedback button in Backstage
   - Select feedback type (feedback, bug report, or feature request)
   - Choose a category
   - Enter your feedback comment
   - Optionally capture a screenshot
   - Optionally provide email for follow-up
   - Submit

2. **Feedback Form Fields**:
   - **Rating** (1-5 stars) - Required
   - **Category** - Required (UI/UX, Performance, Documentation, Features, Bug Report, Other)
   - **Type** - Required (feedback, bug_report, feature_request)
   - **Comment** - Required (up to 2000 characters)
   - **Email** - Optional (for follow-up)
   - **Screenshot** - Optional (auto-captured or manual upload)
   - **Create GitHub Issue** - Optional checkbox (pre-selected for bugs and features)

### For Admins

1. Navigate to the feedback admin page
2. View all submitted feedback with:
   - Filtering by status, category, or type
   - Pagination support
   - Screenshot preview (if available)
   - Linked GitHub issues
3. Update feedback status (open, in_progress, resolved, dismissed)
4. View aggregated statistics and metrics

## API Integration

The plugin communicates with the feedback service via these endpoints:

### Public Endpoints
- `POST /api/v1/feedback` - Submit feedback (with optional screenshot and GitHub issue creation)

### Admin Endpoints (require Bearer token)
- `GET /api/v1/feedback` - List feedback with filters and pagination
- `PUT /api/v1/feedback/{id}/status` - Update status (syncs to GitHub if linked)
- `GET /api/v1/feedback/{id}/screenshot` - Retrieve screenshot data
- `GET /api/v1/feedback/stats` - Get statistics

### Health & Metrics
- `GET /health` - Service health check
- `GET /metrics` - Prometheus metrics
- `POST /api/v1/metrics/refresh` - Refresh metrics (admin)

## Screenshot Capture

Screenshots are captured using HTML5 Canvas API and stored as base64-encoded PNG images:

- **Max size**: 5MB
- **Format**: PNG
- **Storage**: PostgreSQL BYTEA column
- **Retrieval**: Admin-only endpoint for privacy

## GitHub Integration

When feedback is submitted with `create_github_issue: true`:

1. A GitHub issue is created with:
   - Title based on feedback type and comment
   - Body including all feedback details
   - Labels: `feedback`, `automated`, type-specific labels
   - Category label (e.g., `category:ui-ux`)

2. If a screenshot is included:
   - A comment is added noting screenshot availability
   - Screenshot remains in feedback database for privacy

3. Status synchronization:
   - When feedback status is updated, linked GitHub issue is updated
   - `resolved` → closes issue with `resolution:completed` label
   - `dismissed` → closes issue with `resolution:wont-fix` label
   - `in_progress` → adds `status:in-progress` label

## Contextual Information

The widget automatically captures:

- **Page URL**: Current page where feedback was submitted
- **Browser Info**: Browser name and version
- **User Agent**: Full user agent string
- **Timestamp**: Submission time
- **Sentiment**: Automatic sentiment analysis (positive/neutral/negative)

## Frontend Implementation Note

This configuration provides the backend infrastructure and API integration. The actual Backstage frontend plugin implementation (React components, UI elements) would require:

1. A custom Backstage plugin package (e.g., `@internal/plugin-feedback`)
2. React components for:
   - Feedback button/trigger
   - Feedback modal with form
   - Screenshot capture functionality
   - Admin dashboard
3. Integration with Backstage's plugin architecture
4. Registration in Backstage's `packages/app/src/App.tsx`

### Example Frontend Integration

```typescript
// Example screenshot capture logic
const captureScreenshot = async () => {
  const canvas = await html2canvas(document.body);
  return canvas.toDataURL('image/png');
};

// Example feedback submission
const submitFeedback = async (data) => {
  const response = await fetch('/feedback/api/api/v1/feedback', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      rating: data.rating,
      category: data.category,
      feedback_type: data.type,
      comment: data.comment,
      email: data.email,
      page_url: window.location.href,
      browser_info: navigator.userAgent,
      screenshot: data.screenshot, // base64 string
      create_github_issue: data.createIssue
    })
  });
  return response.json();
};
```

For a full implementation, follow the [Backstage plugin development guide](https://backstage.io/docs/plugins/create-a-plugin).

## Development

For local testing:

```bash
# Submit feedback with screenshot
curl -X POST http://feedback.127.0.0.1.nip.io/api/v1/feedback \
  -H "Content-Type: application/json" \
  -d '{
    "rating": 5,
    "category": "Bug Report",
    "feedback_type": "bug_report",
    "comment": "Found an issue with the deployment page",
    "email": "user@example.com",
    "page_url": "https://backstage.fawkes.idp/catalog",
    "browser_info": "Chrome 120.0",
    "user_agent": "Mozilla/5.0...",
    "screenshot": "data:image/png;base64,iVBORw0KGg...",
    "create_github_issue": true
  }'

# List feedback (requires admin token)
curl http://feedback.127.0.0.1.nip.io/api/v1/feedback \
  -H "Authorization: Bearer your-admin-token"

# Get screenshot (requires admin token)
curl http://feedback.127.0.0.1.nip.io/api/v1/feedback/1/screenshot \
  -H "Authorization: Bearer your-admin-token"
```

## Security Considerations

- **Screenshots**: Stored in database, only accessible by admins
- **PII**: Email addresses are optional and stored encrypted
- **GitHub Integration**: Uses personal access token with limited scope
- **Admin Endpoints**: Require Bearer token authentication
- **CORS**: Configured for Backstage origin only (production)
- **Rate Limiting**: Recommended for production deployment

## Monitoring

### Prometheus Metrics

- `feedback_submissions_total` - Counter by category, rating, and type
- `feedback_request_duration_seconds` - Histogram by endpoint
- `feedback_github_issues_created_total` - Counter of GitHub issues created
- `feedback_github_sync_errors_total` - Counter of GitHub sync errors

### Suggested Alerts

- High error rate (>5% of requests)
- GitHub integration failures
- Database connection issues
- Screenshot storage approaching limits

## References

- **Issue**: https://github.com/paruff/fawkes/issues/85
- **Backstage Plugin Guide**: https://backstage.io/docs/plugins/create-a-plugin
- **GitHub API**: https://docs.github.com/en/rest
- **FastAPI Documentation**: https://fastapi.tiangolo.com/
