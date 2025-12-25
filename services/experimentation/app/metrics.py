"""Prometheus metrics collection"""
from prometheus_client import Counter, Histogram, Gauge, Info


class MetricsCollector:
    """Collects and exposes Prometheus metrics for experimentation service"""

    def __init__(self):
        # Experiment metrics
        self.experiments_total = Counter(
            "experimentation_experiments_total", "Total number of experiments created", ["status"]
        )

        self.experiments_active = Gauge("experimentation_experiments_active", "Number of currently active experiments")

        # Variant assignment metrics
        self.variant_assignments_total = Counter(
            "experimentation_variant_assignments_total", "Total variant assignments", ["experiment_id", "variant"]
        )

        # Event tracking metrics
        self.events_total = Counter(
            "experimentation_events_total", "Total events tracked", ["experiment_id", "variant", "event_name"]
        )

        self.event_values = Histogram(
            "experimentation_event_values",
            "Distribution of event values",
            ["experiment_id", "variant", "event_name"],
            buckets=[0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 25.0, 50.0, 100.0, 250.0, 500.0, 1000.0],
        )

        # Request metrics
        self.request_duration = Histogram(
            "experimentation_request_duration_seconds",
            "Request duration in seconds",
            ["endpoint", "method"],
            buckets=[0.001, 0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
        )

        # Statistical analysis metrics
        self.analysis_duration = Histogram(
            "experimentation_analysis_duration_seconds", "Statistical analysis duration", ["experiment_id"]
        )

        self.significant_results_total = Counter(
            "experimentation_significant_results_total",
            "Number of statistically significant results found",
            ["experiment_id"],
        )

    def increment_experiments_total(self, status: str):
        """Increment total experiments counter"""
        self.experiments_total.labels(status=status).inc()

    def set_experiments_active(self, count: int):
        """Set number of active experiments"""
        self.experiments_active.set(count)

    def increment_variant_assignments(self, experiment_id: str, variant: str):
        """Increment variant assignment counter"""
        self.variant_assignments_total.labels(experiment_id=experiment_id, variant=variant).inc()

    def increment_event_total(self, experiment_id: str, variant: str, event_name: str):
        """Increment event counter"""
        self.events_total.labels(experiment_id=experiment_id, variant=variant, event_name=event_name).inc()

    def observe_event_value(self, experiment_id: str, variant: str, event_name: str, value: float):
        """Record event value"""
        self.event_values.labels(experiment_id=experiment_id, variant=variant, event_name=event_name).observe(value)

    def observe_request_duration(self, endpoint: str, method: str, duration: float):
        """Record request duration"""
        self.request_duration.labels(endpoint=endpoint, method=method).observe(duration)

    def observe_analysis_duration(self, experiment_id: str, duration: float):
        """Record analysis duration"""
        self.analysis_duration.labels(experiment_id=experiment_id).observe(duration)

    def increment_significant_results(self, experiment_id: str):
        """Increment significant results counter"""
        self.significant_results_total.labels(experiment_id=experiment_id).inc()
