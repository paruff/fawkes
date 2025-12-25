# Fawkes Feedback CLI

Command-line tool for submitting feedback to the Fawkes platform without leaving your terminal.

## Features

- 🚀 **Quick Submission**: Submit feedback with a single command
- 💬 **Interactive Mode**: User-friendly prompts for guided feedback submission
- 📦 **Offline Queue**: Automatically queues feedback when the service is unavailable
- 🔄 **Auto-sync**: Syncs queued feedback when connection is restored
- 🎨 **Rich Interface**: Beautiful terminal UI with colors and tables
- ⚙️ **Configurable**: Flexible configuration via file or environment variables

## Installation

### From Source

```bash
cd services/feedback-cli
pip install -e .
```

### Via pip (when published)

```bash
pip install fawkes-feedback
```

## Quick Start

### 1. Initialize Configuration

```bash
fawkes-feedback config init
```

This will prompt you for:

- Feedback API URL (default: `http://feedback-service.fawkes.svc.cluster.local:8000`)
- Your name (pulled from git config if available)
- API key (optional)

### 2. Submit Feedback

**Quick submit:**

```bash
fawkes-feedback submit -r 5 -c "UI/UX" -m "Love the new dashboard!"
```

**Interactive mode:**

```bash
fawkes-feedback submit -i
```

**Bug report:**

```bash
fawkes-feedback submit -t bug_report -r 2 -c "Jenkins" -m "Build failing on main branch"
```

## Commands

### `submit` - Submit Feedback

Submit new feedback about the platform.

**Options:**

- `-r, --rating INTEGER` - Rating from 1-5 (required)
- `-c, --category TEXT` - Feedback category (required)
- `-m, --comment TEXT` - Feedback comment (required)
- `-e, --email TEXT` - Your email for follow-up (optional)
- `-u, --page-url TEXT` - Page URL where feedback is about
- `-t, --type [feedback|bug_report|feature_request]` - Type of feedback
- `-i, --interactive` - Use interactive mode

**Examples:**

```bash
# Quick feedback
fawkes-feedback submit -r 5 -c "Performance" -m "Builds are super fast now!"

# Feature request
fawkes-feedback submit -t feature_request -r 4 -c "Features" -m "Would love dark mode"

# Interactive mode with all prompts
fawkes-feedback submit -i
```

### `list` - List Feedback

List recent feedback submissions.

**Options:**

- `-c, --category TEXT` - Filter by category
- `-s, --status TEXT` - Filter by status
- `-l, --limit INTEGER` - Number of results (default: 10)

**Examples:**

```bash
# List last 10 feedback items
fawkes-feedback list

# Filter by category
fawkes-feedback list -c "UI/UX"

# Show more results
fawkes-feedback list -l 20
```

### `show` - Show Feedback Details

Show details of a specific feedback item.

**Examples:**

```bash
fawkes-feedback show 123
```

### `sync` - Sync Offline Queue

Sync queued feedback to the service when online.

**Examples:**

```bash
fawkes-feedback sync
```

### `queue` - Show Queue Status

Display all feedback items waiting to be submitted.

**Examples:**

```bash
fawkes-feedback queue
```

### Configuration Commands

#### `config show` - Show Configuration

```bash
fawkes-feedback config show
```

#### `config init` - Initialize Configuration

```bash
fawkes-feedback config init
```

#### `config set-offline` - Enable/Disable Offline Mode

```bash
fawkes-feedback config set-offline true
fawkes-feedback config set-offline false
```

## Configuration

Configuration can be set via:

1. Config file: `~/.fawkes-feedback/config.yaml`
2. Environment variables
3. Command-line options (for `config init`)

### Configuration File Format

```yaml
api_url: http://feedback-service.fawkes.svc.cluster.local:8000
api_key: null # Optional
default_category: General
author: Your Name
offline_mode: true
queue_path: /home/user/.fawkes-feedback/queue.json
```

### Environment Variables

- `FEEDBACK_API_URL` - Override API URL
- `FEEDBACK_API_KEY` - Set API key
- `FEEDBACK_AUTHOR` - Set author name
- `FEEDBACK_OFFLINE_MODE` - Enable/disable offline mode (`true`/`false`)

## Offline Queue

When the feedback service is unavailable, feedback is automatically queued locally.

**Queue location:** `~/.fawkes-feedback/queue.json`

**Check queue status:**

```bash
fawkes-feedback queue
```

**Sync when online:**

```bash
fawkes-feedback sync
```

The queue will automatically retry failed submissions and track attempt counts.

## Usage Examples

### Daily Workflow

```bash
# Quick positive feedback
fawkes-feedback submit -r 5 -c "CI/CD" -m "Deployment was lightning fast today!"

# Report an issue
fawkes-feedback submit -t bug_report -r 2 -c "Documentation" -m "Getting 404 on the API docs page" -u "https://docs.fawkes.io/api"

# Feature request with email for follow-up
fawkes-feedback submit -t feature_request -r 4 -c "Features" -m "Would be great to have Slack integration" -e "dev@company.com"

# Check what feedback I've submitted
fawkes-feedback list -l 5
```

### Working Offline

```bash
# Submit feedback while offline (automatically queued)
fawkes-feedback submit -r 4 -c "Backstage" -m "Love the new catalog view"
# Output: ⏳ Feedback queued for later submission

# Check queue
fawkes-feedback queue
# Shows: 1 item in queue

# When back online
fawkes-feedback sync
# Output: ✓ Successfully submitted: 1
```

## Feedback Categories

Common categories you can use:

- `UI/UX` - User interface and experience
- `Performance` - Speed and responsiveness
- `Documentation` - Docs quality and completeness
- `Features` - Feature requests or suggestions
- `CI/CD` - Continuous integration and deployment
- `Backstage` - Developer portal feedback
- `Jenkins` - CI/CD pipeline feedback
- `Security` - Security-related feedback
- `Bug Report` - Bug reports
- `Other` - General feedback

## Feedback Types

- `feedback` - General feedback (default)
- `bug_report` - Bug or issue report
- `feature_request` - Feature request or enhancement

## Integration with Feedback Service

This CLI integrates with the Fawkes Feedback Service API:

**Endpoints used:**

- `POST /api/v1/feedback` - Submit feedback
- `GET /api/v1/feedback` - List feedback (requires auth)
- `GET /api/v1/feedback/{id}` - Get feedback details
- `GET /health` - Health check

**Authentication:**
Admin endpoints (list, show) require an API key via the `Authorization: Bearer <token>` header.

## Development

### Setup Development Environment

```bash
cd services/feedback-cli

# Install in development mode
pip install -e .

# Install dev dependencies
pip install -r requirements-dev.txt
```

### Run Tests

```bash
pytest tests/ -v
```

### Run with Coverage

```bash
pytest tests/ --cov=feedback_cli --cov-report=term-missing
```

## Troubleshooting

### Cannot connect to API

```bash
# Check configuration
fawkes-feedback config show

# Test health check manually
curl http://feedback-service.fawkes.svc.cluster.local:8000/health

# Update API URL
fawkes-feedback config init
```

### Queue not syncing

```bash
# Check queue status
fawkes-feedback queue

# Verify API is reachable
fawkes-feedback config show

# Try manual sync
fawkes-feedback sync
```

### Command not found

```bash
# Reinstall CLI
pip install -e .

# Verify installation
which fawkes-feedback

# Check entry point
pip show fawkes-feedback
```

## Contributing

Contributions are welcome! Please follow the [Fawkes contribution guidelines](../../CONTRIBUTING.md).

## License

Apache License 2.0 - See [LICENSE](../../LICENSE) for details.

## Support

- **Issues**: https://github.com/paruff/fawkes/issues
- **Discussions**: https://github.com/paruff/fawkes/discussions
- **Documentation**: https://fawkes.io/docs

## Related

- [Feedback Service](../feedback/) - Backend API service
- [Friction CLI](../friction-cli/) - CLI for logging friction points
- [Fawkes Platform](../../README.md) - Main platform documentation
