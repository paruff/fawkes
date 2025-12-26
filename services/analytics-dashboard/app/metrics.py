"""Prometheus metrics collection for Analytics Dashboard"""
from prometheus_client import Counter, Gauge, Histogram, Info
from typing import Dict


class MetricsCollector:
    """Collect and expose Prometheus metrics for analytics dashboard"""

    def __init__(self):
        # Usage metrics
        self.total_users = Gauge("analytics_total_users", "Total number of unique users")

        self.active_users = Gauge("analytics_active_users", "Number of active users in time range")

        self.page_views = Gauge("analytics_page_views_total", "Total page views")

        self.unique_visitors = Gauge("analytics_unique_visitors", "Number of unique visitors")

        self.avg_session_duration = Gauge(
            "analytics_avg_session_duration_seconds", "Average session duration in seconds"
        )

        self.bounce_rate = Gauge("analytics_bounce_rate_percentage", "Bounce rate percentage")

        # Feature adoption metrics
        self.feature_adoption_rate = Gauge(
            "analytics_feature_adoption_rate", "Feature adoption rate percentage", ["feature_name"]
        )

        self.feature_usage_count = Counter(
            "analytics_feature_usage_total", "Total feature usage count", ["feature_name"]
        )

        self.feature_unique_users = Gauge(
            "analytics_feature_unique_users", "Number of unique users per feature", ["feature_name"]
        )

        # Experiment metrics
        self.active_experiments = Gauge("analytics_active_experiments", "Number of active experiments")

        self.experiment_conversions = Gauge(
            "analytics_experiment_conversions",
            "Number of conversions per experiment variant",
            ["experiment_id", "variant"],
        )

        self.experiment_conversion_rate = Gauge(
            "analytics_experiment_conversion_rate",
            "Conversion rate per experiment variant",
            ["experiment_id", "variant"],
        )

        self.significant_results = Counter(
            "analytics_significant_results_total", "Number of statistically significant experiment results"
        )

        # User segment metrics
        self.segment_size = Gauge("analytics_segment_size", "Number of users in segment", ["segment_name"])

        self.segment_engagement = Gauge(
            "analytics_segment_engagement", "Average engagement score per segment", ["segment_name"]
        )

        # Funnel metrics
        self.funnel_conversion_rate = Gauge(
            "analytics_funnel_conversion_rate", "Overall funnel conversion rate", ["funnel_name"]
        )

        self.funnel_step_completion = Gauge(
            "analytics_funnel_step_completion_rate", "Completion rate per funnel step", ["funnel_name", "step"]
        )

        self.funnel_drop_off = Gauge(
            "analytics_funnel_drop_off_rate", "Drop-off rate per funnel step", ["funnel_name", "step"]
        )

        # System metrics
        self.data_refresh_duration = Histogram(
            "analytics_data_refresh_duration_seconds", "Time taken to refresh analytics data"
        )

        self.api_requests = Counter(
            "analytics_api_requests_total", "Total API requests", ["endpoint", "method", "status"]
        )

        self.dashboard_info = Info("analytics_dashboard", "Analytics dashboard information")

        # Set dashboard info
        self.dashboard_info.info({"version": "1.0.0", "service": "analytics-dashboard"})

    def update_usage_metrics(self, data: Dict):
        """Update usage-related metrics"""
        self.total_users.set(data.get("total_users", 0))
        self.active_users.set(data.get("active_users", 0))
        self.page_views.set(data.get("page_views", 0))
        self.unique_visitors.set(data.get("unique_visitors", 0))
        self.avg_session_duration.set(data.get("avg_session_duration", 0))
        self.bounce_rate.set(data.get("bounce_rate", 0))

    def update_feature_metrics(self, features: list):
        """Update feature adoption metrics"""
        for feature in features:
            feature_name = feature.get("feature_name", "unknown")
            self.feature_adoption_rate.labels(feature_name=feature_name).set(feature.get("adoption_rate", 0))
            self.feature_unique_users.labels(feature_name=feature_name).set(feature.get("unique_users", 0))

    def update_experiment_metrics(self, experiments: list):
        """Update experiment metrics"""
        active_count = sum(1 for exp in experiments if exp.get("status") == "running")
        self.active_experiments.set(active_count)

        for exp in experiments:
            exp_id = exp.get("experiment_id", "unknown")
            for variant in exp.get("variants", []):
                variant_id = variant.get("variant_id", "unknown")
                self.experiment_conversions.labels(experiment_id=exp_id, variant=variant_id).set(
                    variant.get("conversions", 0)
                )
                self.experiment_conversion_rate.labels(experiment_id=exp_id, variant=variant_id).set(
                    variant.get("conversion_rate", 0)
                )

    def update_segment_metrics(self, segments: list):
        """Update user segment metrics"""
        for segment in segments:
            segment_name = segment.get("segment_name", "unknown")
            self.segment_size.labels(segment_name=segment_name).set(segment.get("user_count", 0))
            self.segment_engagement.labels(segment_name=segment_name).set(segment.get("avg_engagement", 0))

    def update_funnel_metrics(self, funnels: Dict):
        """Update funnel metrics"""
        for funnel_name, funnel_data in funnels.items():
            self.funnel_conversion_rate.labels(funnel_name=funnel_name).set(
                funnel_data.get("overall_conversion_rate", 0)
            )
            for step in funnel_data.get("steps", []):
                step_name = step.get("step_name", "unknown")
                self.funnel_step_completion.labels(funnel_name=funnel_name, step=step_name).set(
                    step.get("completion_rate", 0)
                )
                self.funnel_drop_off.labels(funnel_name=funnel_name, step=step_name).set(step.get("drop_off_rate", 0))

    def record_api_request(self, endpoint: str, method: str, status: int):
        """Record API request"""
        self.api_requests.labels(endpoint=endpoint, method=method, status=str(status)).inc()
