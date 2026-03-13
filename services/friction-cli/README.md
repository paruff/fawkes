# Fawkes Friction Logger CLI

Command-line tool for logging developer friction points in real-time to the Fawkes Insights database.

## Features

- 🚀 **Quick Friction Logging**: Log friction points with a single command
- 💬 **Interactive Mode**: Guided prompts for comprehensive friction capture
- 📊 **List & Filter**: View recent friction points with filtering
- 🎨 **Rich Terminal UI**: Beautiful, colored output with tables and panels
- ⚙️ **Configurable**: Flexible configuration via file or environment variables
- 🔗 **API Integration**: Direct integration with Fawkes Insights API
- 🏷️ **Categorization**: Organize friction by categories, tags, and priority

## Installation

### From Source

```bash
cd services/friction-cli
pip install -e .
```

### Using pip (when published)

```bash
pip install fawkes-friction
```

## Quick Start

### 1. Initialize Configuration

```bash
friction config init
```

This will prompt you for:

- Insights API URL (default: http://insights-service.fawkes.svc.cluster.local:8000)
- Your name (optional, uses git config if not provided)
- API key (optional, if authentication is required)

### 2. Log Your First Friction Point

**Quick mode:**

```bash
friction log -t "Slow CI builds" -d "Maven builds taking 20+ minutes" -c "CI/CD" -p high
```

**Interactive mode:**

```bash
friction log -i
```

### 3. View Recent Friction Points

```bash
friction list
```

## Usage

### Log Friction

**Quick log:**

```bash
friction log -t "Title" -d "Description"
```

**With category and priority:**

```bash
friction log -t "Missing documentation" -d "No setup guide for new developers" -c Documentation -p medium
```

**With multiple tags:**

```bash
friction log -t "Deployment failure" -d "ArgoCD sync failed" -T deployment -T urgent -T infrastructure
```

**Interactive mode (recommended):**

```bash
friction log -i
```

### List Friction Points

**List recent:**

```bash
friction list
```

**Filter by category:**

```bash
friction list -c "CI/CD"
```

**Filter by priority:**

```bash
friction list -p high -l 20
```

### Show Friction Details

```bash
friction show 123
```

### Manage Categories

**List all categories:**

```bash
friction categories list
```

### Configuration

**Show current configuration:**

```bash
friction config show
```

**Initialize/update configuration:**

```bash
friction config init
```

**Manual configuration:**

Edit `~/.friction/config.yaml`:

```yaml
api_url: http://insights-service.fawkes.svc.cluster.local:8000
api_key: your-api-key # optional
default_category: Developer Experience
default_priority: medium
author: Your Name
```

**Environment variables:**

```bash
export FRICTION_API_URL="http://insights-service.fawkes.svc.cluster.local:8000"
export FRICTION_API_KEY="your-api-key"
export FRICTION_AUTHOR="Your Name"
```

## Examples

### Example 1: Log a CI/CD Issue

```bash
friction log \
  -t "Jenkins pipeline timeout" \
  -d "Pipeline times out after 60 minutes during integration tests" \
  -c "CI/CD" \
  -p high \
  -T jenkins \
  -T timeout \
  -T integration-tests
```

### Example 2: Log Documentation Gap

```bash
friction log \
  -t "Missing onboarding guide" \
  -d "New developers don't know how to set up local environment" \
  -c "Documentation" \
  -p medium \
  -T onboarding \
  -T documentation
```

### Example 3: Log Tooling Friction

```bash
friction log \
  -t "Kubectl config constantly breaks" \
  -d "Need to reconfigure kubectl context multiple times per day" \
  -c "Tooling" \
  -p medium \
  -T kubectl \
  -T kubernetes
```

### Example 4: Interactive Mode

```bash
$ friction log -i

╔═══════════════════════════════════════════════════════════╗
║ Friction Logger - Interactive Mode                        ║
║ Let's capture that friction point!                        ║
╚═══════════════════════════════════════════════════════════╝

What's the friction about? (brief title): Slow deployment process
Describe the friction (what happened, when, impact): Deployment to dev takes 15+ minutes

Available categories:
  1. Technical
  2. Process
  3. People
  4. Product
  5. Security
  6. Performance

Category [Developer Experience]: Process
Priority [low/medium/high/critical] [medium]: high
Tags (comma-separated, optional): deployment, performance

╔═══════════════════════════════════════════════════════════╗
║ ✓ Friction point logged successfully!                     ║
║                                                           ║
║ ID: 42                                                    ║
║ Title: Slow deployment process                           ║
║ Category: Process                                         ║
║ Priority: high                                            ║
╚═══════════════════════════════════════════════════════════╝
```

## Friction Categories

Common categories for friction points:

- **CI/CD**: Build, test, and deployment pipeline issues
- **Documentation**: Missing, outdated, or unclear documentation
- **Tooling**: Developer tools, IDE, CLI issues
- **Infrastructure**: Kubernetes, cloud, networking issues
- **Process**: Development workflow, approval processes
- **Testing**: Test execution, flakiness, coverage issues
- **Security**: Security scanning, vulnerabilities, compliance
- **Performance**: Slow systems, timeouts, resource issues

## Priority Levels

- **critical**: Blocking work, urgent attention needed
- **high**: Significant impact, should be addressed soon
- **medium**: Noticeable friction, address when possible
- **low**: Minor inconvenience, nice to fix

## Integration with Fawkes

The CLI integrates with the Fawkes Insights service to:

1. **Store friction logs** in the centralized insights database
2. **Categorize and tag** friction points for analysis
3. **Enable tracking** of friction over time
4. **Support dashboards** showing friction trends and hot spots
5. **Feed improvement processes** with real developer feedback

All friction logs are automatically tagged with `friction` and stored with metadata indicating they came from the CLI tool.

## Development

### Setup Development Environment

```bash
cd services/friction-cli
pip install -r requirements-dev.txt
pip install -e .
```

### Run Tests

```bash
pytest tests/ -v
```

### Code Style

The project uses:

- `black` for code formatting
- `isort` for import sorting
- `flake8` for linting
- `mypy` for type checking

## Troubleshooting

### Cannot connect to API

```bash
# Check configuration
friction config show

# Test API connectivity
curl http://insights-service.fawkes.svc.cluster.local:8000/health

# Update API URL
friction config init
```

### Command not found

```bash
# Reinstall CLI
pip install -e .

# Or use full path
python -m friction_cli.cli
```

### Permission denied

```bash
# Check config directory permissions
ls -la ~/.friction/

# Recreate config
rm -rf ~/.friction/
friction config init
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Friction CLI                             │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                │
│  │  Config  │  │  Client  │  │   CLI    │                │
│  │ Manager  │  │  (API)   │  │  (Click) │                │
│  └──────────┘  └──────────┘  └──────────┘                │
└─────────────────────────────────────────────────────────────┘
                         │
                         │ HTTP/REST
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              Insights Service API                           │
│                                                             │
│  POST   /insights     - Create friction log                │
│  GET    /insights     - List friction logs                 │
│  GET    /insights/:id - Get specific friction              │
│  GET    /categories   - List categories                    │
│  GET    /tags         - List tags                          │
└─────────────────────────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│              PostgreSQL Database                            │
│                                                             │
│  Tables: insights, categories, tags, insight_tags          │
└─────────────────────────────────────────────────────────────┘
```

## API Reference

See the [Insights Service Documentation](../insights/README.md) for complete API reference.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Run tests and linting
6. Submit a pull request

## License

Apache License 2.0

## Support

- **Documentation**: See `/docs` directory
- **Issues**: https://github.com/paruff/fawkes/issues
- **Slack**: #fawkes-support

## Version History

### 0.1.0 (2024-12-23)

- Initial release
- Basic friction logging
- Interactive mode
- Configuration management
- List and filter functionality
- Category management
- Rich terminal UI

## AI-Readiness Checklist

A module is "AI-ready" when agents can work on it reliably. Track any gaps as GitHub issues.
See [AGENTS.md §11](../../AGENTS.md) for full context.

- [ ] Type hints on all public functions
- [ ] Docstrings on all public classes and functions
- [ ] Tests exist and are green before AI adds to them
- [ ] Module is single-purpose (not a God class/file)
- [ ] Clear, contextual error messages (no bare `raise Exception`)
- [ ] Module is covered by BDD scenarios in `tests/bdd/`
