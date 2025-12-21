#!/usr/bin/env python3
"""
Prometheus exporter for Great Expectations data quality metrics.

This exporter parses Great Expectations validation results and exposes
metrics in Prometheus format on port 9110.

Metrics exposed:
- validation_success: Success/failure of validation runs (gauge)
- validation_duration_seconds: Duration of validation runs (histogram)
- expectation_failures_total: Count of failed expectations (counter)
- data_freshness_seconds: Time since last validation per datasource (gauge)
- validation_runs_total: Total number of validation runs (counter)
"""
import os
import sys
import json
import time
import logging
import argparse
from pathlib import Path
from datetime import datetime
from typing import Dict, Any, List, Optional
from http.server import HTTPServer, BaseHTTPRequestHandler

from prometheus_client import (
    Counter,
    Gauge,
    Histogram,
    generate_latest,
    CollectorRegistry,
    CONTENT_TYPE_LATEST
)

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Prometheus metrics registry
registry = CollectorRegistry()

# Define metrics
validation_success = Gauge(
    'data_quality_validation_success',
    'Success status of last validation (1=success, 0=failure)',
    ['datasource', 'suite', 'checkpoint'],
    registry=registry
)

validation_duration = Histogram(
    'data_quality_validation_duration_seconds',
    'Duration of validation runs in seconds',
    ['datasource', 'suite', 'checkpoint'],
    registry=registry,
    buckets=(1, 5, 10, 30, 60, 120, 300, 600)
)

expectation_failures = Counter(
    'data_quality_expectation_failures_total',
    'Total count of failed expectations',
    ['datasource', 'suite', 'expectation_type', 'checkpoint'],
    registry=registry
)

data_freshness = Gauge(
    'data_quality_data_freshness_seconds',
    'Seconds since last validation per datasource',
    ['datasource', 'suite'],
    registry=registry
)

validation_runs = Counter(
    'data_quality_validation_runs_total',
    'Total number of validation runs',
    ['datasource', 'suite', 'checkpoint', 'status'],
    registry=registry
)

expectations_total = Gauge(
    'data_quality_expectations_total',
    'Total number of expectations evaluated',
    ['datasource', 'suite', 'checkpoint'],
    registry=registry
)

expectations_successful = Gauge(
    'data_quality_expectations_successful',
    'Number of successful expectations',
    ['datasource', 'suite', 'checkpoint'],
    registry=registry
)

success_rate = Gauge(
    'data_quality_success_rate_percent',
    'Percentage of successful expectations',
    ['datasource', 'suite', 'checkpoint'],
    registry=registry
)


class MetricsExporter:
    """Exports Great Expectations metrics to Prometheus."""
    
    def __init__(self, results_dir: str = "/app/gx/uncommitted/validations"):
        """
        Initialize the metrics exporter.
        
        Args:
            results_dir: Directory containing validation results
        """
        self.results_dir = Path(results_dir)
        self.last_update = {}
        logger.info(f"Initialized MetricsExporter with results_dir: {results_dir}")
    
    def parse_checkpoint_result(self, result_data: Dict[str, Any]) -> None:
        """
        Parse a checkpoint result and update metrics.
        
        Args:
            result_data: Checkpoint result data from Great Expectations
        """
        try:
            # Extract metadata
            checkpoint_name = result_data.get('checkpoint_name', 'unknown')
            success = result_data.get('success', False)
            statistics = result_data.get('statistics', {})
            run_time = result_data.get('run_time', time.time())
            
            # Extract suite name from checkpoint (e.g., "backstage_db_checkpoint" -> "backstage")
            datasource = checkpoint_name.replace('_checkpoint', '').replace('_db', '')
            suite_name = result_data.get('expectation_suite_name', checkpoint_name)
            
            # Update validation success metric
            validation_success.labels(
                datasource=datasource,
                suite=suite_name,
                checkpoint=checkpoint_name
            ).set(1 if success else 0)
            
            # Update expectations metrics
            evaluated = statistics.get('evaluated_expectations', 0)
            successful = statistics.get('successful_expectations', 0)
            unsuccessful = statistics.get('unsuccessful_expectations', 0)
            success_percent = statistics.get('success_percent', 0)
            
            expectations_total.labels(
                datasource=datasource,
                suite=suite_name,
                checkpoint=checkpoint_name
            ).set(evaluated)
            
            expectations_successful.labels(
                datasource=datasource,
                suite=suite_name,
                checkpoint=checkpoint_name
            ).set(successful)
            
            success_rate.labels(
                datasource=datasource,
                suite=suite_name,
                checkpoint=checkpoint_name
            ).set(success_percent)
            
            # Update validation runs counter
            status = 'success' if success else 'failure'
            validation_runs.labels(
                datasource=datasource,
                suite=suite_name,
                checkpoint=checkpoint_name,
                status=status
            ).inc()
            
            # Update expectation failures
            if unsuccessful > 0:
                expectation_failures.labels(
                    datasource=datasource,
                    suite=suite_name,
                    expectation_type='all',
                    checkpoint=checkpoint_name
                ).inc(unsuccessful)
            
            # Update data freshness
            current_time = time.time()
            seconds_since_validation = current_time - run_time
            data_freshness.labels(
                datasource=datasource,
                suite=suite_name
            ).set(seconds_since_validation)
            
            # Track last update time
            self.last_update[checkpoint_name] = current_time
            
            logger.info(
                f"Updated metrics for checkpoint={checkpoint_name}, "
                f"success={success}, evaluated={evaluated}, "
                f"successful={successful}, failed={unsuccessful}"
            )
            
        except Exception as e:
            logger.error(f"Error parsing checkpoint result: {e}", exc_info=True)
    
    def load_latest_results(self) -> None:
        """Load the latest validation results from disk."""
        if not self.results_dir.exists():
            logger.warning(f"Results directory does not exist: {self.results_dir}")
            return
        
        try:
            # Find all validation result files
            result_files = list(self.results_dir.glob("**/*.json"))
            
            if not result_files:
                logger.warning(f"No validation results found in {self.results_dir}")
                return
            
            # Sort by modification time and process recent ones
            result_files.sort(key=lambda f: f.stat().st_mtime, reverse=True)
            
            # Process up to 20 most recent results to avoid staleness
            processed = 0
            for result_file in result_files[:20]:
                try:
                    with open(result_file, 'r') as f:
                        result_data = json.load(f)
                        self.parse_checkpoint_result(result_data)
                        processed += 1
                except Exception as e:
                    logger.error(f"Error loading result file {result_file}: {e}")
            
            logger.info(f"Processed {processed} validation results")
            
        except Exception as e:
            logger.error(f"Error loading latest results: {e}", exc_info=True)
    
    def parse_inline_result(self, result_json: str) -> None:
        """
        Parse a JSON result string and update metrics.
        
        Args:
            result_json: JSON string with validation results
        """
        try:
            result_data = json.loads(result_json)
            self.parse_checkpoint_result(result_data)
        except json.JSONDecodeError as e:
            logger.error(f"Invalid JSON: {e}")
        except Exception as e:
            logger.error(f"Error parsing inline result: {e}", exc_info=True)


class MetricsHandler(BaseHTTPRequestHandler):
    """HTTP handler for Prometheus metrics endpoint."""
    
    exporter: MetricsExporter = None
    
    def do_GET(self):
        """Handle GET requests."""
        if self.path == '/metrics':
            # Refresh metrics before serving
            if self.exporter:
                self.exporter.load_latest_results()
            
            # Generate and send metrics
            metrics = generate_latest(registry)
            self.send_response(200)
            self.send_header('Content-Type', CONTENT_TYPE_LATEST)
            self.end_headers()
            self.write_output(metrics)
        
        elif self.path == '/health' or self.path == '/healthz':
            # Health check endpoint
            self.send_response(200)
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            health_data = {
                'status': 'healthy',
                'service': 'data-quality-prometheus-exporter',
                'timestamp': datetime.utcnow().isoformat()
            }
            self.write_output(json.dumps(health_data).encode())
        
        else:
            # 404 for other paths
            self.send_response(404)
            self.end_headers()
            self.write_output(b'Not Found')
    
    def write_output(self, output: bytes):
        """Write output to response."""
        self.wfile.write(output)
    
    def log_message(self, format, *args):
        """Override to use our logger."""
        logger.info(f"{self.address_string()} - {format % args}")


def run_server(port: int = 9110, results_dir: str = "/app/gx/uncommitted/validations"):
    """
    Run the Prometheus metrics HTTP server.
    
    Args:
        port: Port to listen on
        results_dir: Directory containing validation results
    """
    # Create exporter
    exporter = MetricsExporter(results_dir=results_dir)
    
    # Set exporter on handler class
    MetricsHandler.exporter = exporter
    
    # Load initial results
    exporter.load_latest_results()
    
    # Start HTTP server
    server = HTTPServer(('', port), MetricsHandler)
    logger.info(f"Starting Prometheus exporter on port {port}")
    logger.info(f"Metrics available at http://localhost:{port}/metrics")
    
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        logger.info("Shutting down server")
        server.shutdown()


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Prometheus exporter for Great Expectations data quality metrics"
    )
    parser.add_argument(
        '--port',
        type=int,
        default=int(os.getenv('METRICS_PORT', '9110')),
        help='Port to listen on (default: 9110)'
    )
    parser.add_argument(
        '--results-dir',
        type=str,
        default=os.getenv('GX_RESULTS_DIR', '/app/gx/uncommitted/validations'),
        help='Directory containing validation results'
    )
    parser.add_argument(
        '--oneshot',
        action='store_true',
        help='Parse results once and exit (for testing)'
    )
    parser.add_argument(
        '--json',
        type=str,
        help='Parse a JSON result string and exit (for testing)'
    )
    
    args = parser.parse_args()
    
    # One-shot mode for testing
    if args.oneshot:
        exporter = MetricsExporter(results_dir=args.results_dir)
        exporter.load_latest_results()
        print(generate_latest(registry).decode())
        return
    
    # JSON mode for testing
    if args.json:
        exporter = MetricsExporter(results_dir=args.results_dir)
        exporter.parse_inline_result(args.json)
        print(generate_latest(registry).decode())
        return
    
    # Normal server mode
    run_server(port=args.port, results_dir=args.results_dir)


if __name__ == '__main__':
    main()
