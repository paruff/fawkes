"""Prometheus metrics exporter for discovery metrics."""
from prometheus_client import Gauge
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
from app.models import (
    Interview,
    InterviewStatus,
    DiscoveryInsight,
    InsightStatus,
    Experiment,
    ExperimentStatus,
    FeatureValidation,
    FeatureStatus,
    TeamPerformance,
)

# Define Prometheus metrics
discovery_interviews_total = Gauge("discovery_interviews_total", "Total number of interviews conducted")

discovery_interviews_completed = Gauge("discovery_interviews_completed", "Number of completed interviews")

discovery_interviews_by_status = Gauge("discovery_interviews_by_status", "Interviews grouped by status", ["status"])

discovery_insights_total = Gauge("discovery_insights_total", "Total number of discovery insights captured")

discovery_insights_validated = Gauge("discovery_insights_validated", "Number of validated discovery insights")

discovery_insights_by_status = Gauge("discovery_insights_by_status", "Discovery insights grouped by status", ["status"])

discovery_insights_by_category = Gauge(
    "discovery_insights_by_category", "Discovery insights grouped by category", ["category"]
)

discovery_insights_by_source = Gauge("discovery_insights_by_source", "Discovery insights grouped by source", ["source"])

discovery_experiments_total = Gauge("discovery_experiments_total", "Total number of experiments run")

discovery_experiments_completed = Gauge("discovery_experiments_completed", "Number of completed experiments")

discovery_experiments_by_status = Gauge("discovery_experiments_by_status", "Experiments grouped by status", ["status"])

discovery_experiments_validated = Gauge("discovery_experiments_validated", "Number of validated experiments")

discovery_experiments_avg_roi = Gauge(
    "discovery_experiments_avg_roi_percentage", "Average ROI percentage of experiments"
)

discovery_features_total = Gauge("discovery_features_total", "Total number of features tracked")

discovery_features_validated = Gauge("discovery_features_validated", "Number of validated features")

discovery_features_shipped = Gauge("discovery_features_shipped", "Number of shipped features")

discovery_features_by_status = Gauge("discovery_features_by_status", "Features grouped by status", ["status"])

discovery_avg_time_to_validation_days = Gauge(
    "discovery_avg_time_to_validation_days", "Average time from insight capture to validation (days)"
)

discovery_avg_time_to_ship_days = Gauge(
    "discovery_avg_time_to_ship_days", "Average time from feature proposal to ship (days)"
)

discovery_validation_rate = Gauge("discovery_validation_rate", "Percentage of insights that get validated")

discovery_feature_adoption_rate = Gauge("discovery_feature_adoption_rate", "Average feature adoption rate percentage")

discovery_interviews_last_7d = Gauge("discovery_interviews_last_7d", "Number of interviews conducted in last 7 days")

discovery_interviews_last_30d = Gauge("discovery_interviews_last_30d", "Number of interviews conducted in last 30 days")

discovery_insights_last_7d = Gauge("discovery_insights_last_7d", "Number of insights captured in last 7 days")

discovery_insights_last_30d = Gauge("discovery_insights_last_30d", "Number of insights captured in last 30 days")

discovery_team_performance = Gauge("discovery_team_performance", "Team performance metrics", ["team", "metric"])


def update_prometheus_metrics(db: Session):
    """Update all Prometheus metrics from database."""

    # Interview metrics
    total_interviews = db.query(Interview).count()
    discovery_interviews_total.set(total_interviews)

    completed_interviews = db.query(Interview).filter(Interview.status == InterviewStatus.COMPLETED).count()
    discovery_interviews_completed.set(completed_interviews)

    # Interviews by status
    for status in InterviewStatus:
        count = db.query(Interview).filter(Interview.status == status).count()
        discovery_interviews_by_status.labels(status=status.value).set(count)

    # Recent interviews
    now = datetime.utcnow()
    seven_days_ago = now - timedelta(days=7)
    thirty_days_ago = now - timedelta(days=30)

    interviews_7d = db.query(Interview).filter(Interview.completed_date >= seven_days_ago).count()
    discovery_interviews_last_7d.set(interviews_7d)

    interviews_30d = db.query(Interview).filter(Interview.completed_date >= thirty_days_ago).count()
    discovery_interviews_last_30d.set(interviews_30d)

    # Insight metrics
    total_insights = db.query(DiscoveryInsight).count()
    discovery_insights_total.set(total_insights)

    validated_insights = (
        db.query(DiscoveryInsight)
        .filter(DiscoveryInsight.status.in_([InsightStatus.VALIDATED, InsightStatus.IMPLEMENTED]))
        .count()
    )
    discovery_insights_validated.set(validated_insights)

    # Insights by status
    for status in InsightStatus:
        count = db.query(DiscoveryInsight).filter(DiscoveryInsight.status == status).count()
        discovery_insights_by_status.labels(status=status.value).set(count)

    # Insights by category
    categories = (
        db.query(DiscoveryInsight.category, func.count(DiscoveryInsight.id)).group_by(DiscoveryInsight.category).all()
    )

    for category, count in categories:
        discovery_insights_by_category.labels(category=category).set(count)

    # Insights by source
    sources = db.query(DiscoveryInsight.source, func.count(DiscoveryInsight.id)).group_by(DiscoveryInsight.source).all()

    for source, count in sources:
        discovery_insights_by_source.labels(source=source).set(count)

    # Recent insights
    insights_7d = db.query(DiscoveryInsight).filter(DiscoveryInsight.captured_date >= seven_days_ago).count()
    discovery_insights_last_7d.set(insights_7d)

    insights_30d = db.query(DiscoveryInsight).filter(DiscoveryInsight.captured_date >= thirty_days_ago).count()
    discovery_insights_last_30d.set(insights_30d)

    # Validation rate
    if total_insights > 0:
        validation_rate = (validated_insights / total_insights) * 100
        discovery_validation_rate.set(validation_rate)
    else:
        discovery_validation_rate.set(0)

    # Average time to validation
    avg_validation_time = (
        db.query(func.avg(DiscoveryInsight.time_to_validation_days))
        .filter(DiscoveryInsight.time_to_validation_days.isnot(None))
        .scalar()
    )

    if avg_validation_time:
        discovery_avg_time_to_validation_days.set(float(avg_validation_time))
    else:
        discovery_avg_time_to_validation_days.set(0)

    # Experiment metrics
    total_experiments = db.query(Experiment).count()
    discovery_experiments_total.set(total_experiments)

    completed_experiments = db.query(Experiment).filter(Experiment.status == ExperimentStatus.COMPLETED).count()
    discovery_experiments_completed.set(completed_experiments)

    # Experiments by status
    for status in ExperimentStatus:
        count = db.query(Experiment).filter(Experiment.status == status).count()
        discovery_experiments_by_status.labels(status=status.value).set(count)

    # Validated experiments
    validated_experiments = db.query(Experiment).filter(Experiment.validated == True).count()
    discovery_experiments_validated.set(validated_experiments)

    # Average ROI
    avg_roi = db.query(func.avg(Experiment.roi_percentage)).filter(Experiment.roi_percentage.isnot(None)).scalar()

    if avg_roi:
        discovery_experiments_avg_roi.set(float(avg_roi))
    else:
        discovery_experiments_avg_roi.set(0)

    # Feature metrics
    total_features = db.query(FeatureValidation).count()
    discovery_features_total.set(total_features)

    validated_features = (
        db.query(FeatureValidation)
        .filter(FeatureValidation.status.in_([FeatureStatus.VALIDATED, FeatureStatus.BUILDING, FeatureStatus.SHIPPED]))
        .count()
    )
    discovery_features_validated.set(validated_features)

    shipped_features = db.query(FeatureValidation).filter(FeatureValidation.status == FeatureStatus.SHIPPED).count()
    discovery_features_shipped.set(shipped_features)

    # Features by status
    for status in FeatureStatus:
        count = db.query(FeatureValidation).filter(FeatureValidation.status == status).count()
        discovery_features_by_status.labels(status=status.value).set(count)

    # Average time to ship
    avg_ship_time = (
        db.query(func.avg(FeatureValidation.time_to_ship_days))
        .filter(FeatureValidation.time_to_ship_days.isnot(None))
        .scalar()
    )

    if avg_ship_time:
        discovery_avg_time_to_ship_days.set(float(avg_ship_time))
    else:
        discovery_avg_time_to_ship_days.set(0)

    # Feature adoption rate
    avg_adoption = (
        db.query(func.avg(FeatureValidation.adoption_rate)).filter(FeatureValidation.adoption_rate.isnot(None)).scalar()
    )

    if avg_adoption:
        discovery_feature_adoption_rate.set(float(avg_adoption))
    else:
        discovery_feature_adoption_rate.set(0)

    # Team performance metrics
    teams = db.query(TeamPerformance).all()
    for team in teams:
        discovery_team_performance.labels(team=team.team_name, metric="interviews").set(team.interviews_conducted)
        discovery_team_performance.labels(team=team.team_name, metric="insights").set(team.insights_generated)
        discovery_team_performance.labels(team=team.team_name, metric="experiments").set(team.experiments_run)
        discovery_team_performance.labels(team=team.team_name, metric="features_validated").set(team.features_validated)
        discovery_team_performance.labels(team=team.team_name, metric="features_shipped").set(team.features_shipped)
