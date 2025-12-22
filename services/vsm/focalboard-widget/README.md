# VSM Flow Metrics Widget for Focalboard

A custom Focalboard widget that displays real-time Value Stream Mapping (VSM) flow metrics directly in your boards.

## Features

- **Flow Metrics Display**: Shows throughput, WIP, and cycle time percentiles (P50, P85, P95)
- **Stage-level Metrics**: Displays WIP count for each VSM stage
- **Bottleneck Detection**: Highlights stages approaching or exceeding WIP limits
- **WIP Limit Warnings**: Visual indicators when stages are at risk of being blocked
- **Auto-refresh**: Configurable automatic metric refresh
- **Grafana Integration**: Quick link to full VSM dashboard in Grafana

## Installation

### Prerequisites

- Focalboard/Mattermost server (v7.0.0+)
- VSM service running and accessible
- Node.js 16+ and npm (for building)

### Build the Widget

```bash
cd services/vsm/focalboard-widget
npm install
npm run build
```

This generates `dist/main.js` which is the compiled widget bundle.

### Deploy to Focalboard

1. Copy the built widget and manifest to your Focalboard plugins directory:

```bash
cp manifest.json /path/to/focalboard/plugins/vsm-metrics-widget/
cp dist/main.js /path/to/focalboard/plugins/vsm-metrics-widget/
```

2. Restart Focalboard/Mattermost server

3. Enable the widget in Focalboard settings:
   - Go to System Console → Plugins
   - Find "VSM Flow Metrics"
   - Click "Enable"

### Configure the Widget

1. Open a Focalboard board
2. Add a new widget
3. Select "VSM Flow Metrics"
4. Configure settings:
   - **VSM Service API URL**: URL of your VSM service (default: `http://vsm-service.fawkes.svc:8000/api/v1`)
   - **Refresh Interval**: How often to refresh metrics in seconds (default: 30)
   - **Show Bottleneck Warnings**: Enable/disable bottleneck detection (default: true)

## Development

### Local Development

```bash
npm run dev
```

This starts webpack in watch mode, rebuilding on file changes.

### Testing

The widget connects to the VSM service API. Ensure your VSM service is running:

```bash
# Check VSM service health
curl http://vsm-service.fawkes.svc:8000/api/v1/health

# Test metrics endpoint
curl http://vsm-service.fawkes.svc:8000/api/v1/metrics?days=7
```

## Widget Display

The widget shows:

### Overall Metrics (7-day period)
- **Throughput**: Number of items completed
- **WIP**: Current work in progress
- **Cycle Time P50**: Median cycle time
- **Cycle Time P85**: 85th percentile cycle time

### Stage Metrics
- Each VSM stage with current WIP count
- WIP limit for each stage (if configured)
- Bottleneck warning (⚠️) when stage is at 80%+ of WIP limit

### Bottleneck Warnings
When enabled, shows alert if any stages are approaching/exceeding WIP limits.

## Configuration

Widget settings can be configured per board:

- **vsm_api_url**: VSM service API endpoint
- **refresh_interval**: Auto-refresh interval (seconds)
- **show_bottlenecks**: Enable bottleneck detection

## Metrics Explained

- **Throughput**: Number of work items that reached "Production" stage in the period
- **WIP (Work in Progress)**: Count of work items currently in any non-production stage
- **Cycle Time**: Time from first stage entry to production deployment
  - **P50**: 50% of items complete faster than this
  - **P85**: 85% of items complete faster than this
  - **P95**: 95% of items complete faster than this

## Integration with VSM Service

The widget communicates with the VSM service REST API:

- `GET /api/v1/metrics?days=7` - Fetch flow metrics
- `GET /api/v1/stages` - Fetch stage definitions
- `GET /metrics` - Prometheus metrics endpoint (for real-time WIP)

## Grafana Dashboard Link

The widget includes a link to the full VSM flow metrics Grafana dashboard:
- Default URL: `http://grafana.fawkes.svc/d/vsm-flow-metrics`
- Shows detailed cumulative flow diagrams, cycle time trends, and bottleneck analysis

## Troubleshooting

### Widget Shows Error

1. Check VSM service is accessible:
   ```bash
   curl http://vsm-service.fawkes.svc:8000/api/v1/health
   ```

2. Verify API URL in widget settings

3. Check browser console for error messages

### Metrics Not Updating

1. Verify refresh interval is set (> 0 seconds)
2. Check network tab for failed API calls
3. Ensure VSM service has data (create some work items and transitions)

### Bottleneck Detection Not Working

1. Ensure stages have WIP limits configured in VSM
2. Enable "Show Bottleneck Warnings" in widget settings
3. WIP must be at 80%+ of limit to trigger warning

## Architecture

```
Focalboard Widget (React/TypeScript)
    ↓
    ├─→ VSM Service API (/api/v1/metrics)
    │   └─→ PostgreSQL (flow metrics data)
    │
    └─→ Grafana Dashboard (external link)
```

## Future Enhancements

- [ ] Real-time WebSocket updates
- [ ] Click-through to work item details
- [ ] Configurable bottleneck threshold
- [ ] Historical trend sparklines
- [ ] Custom metric selection
- [ ] Multi-board aggregation

## License

MIT

## Support

For issues or questions:
- GitHub Issues: https://github.com/paruff/fawkes/issues
- Documentation: https://github.com/paruff/fawkes/docs
