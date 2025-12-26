"""
Prometheus metrics exporter and DevEx health score calculator
"""

import logging
from datetime import datetime, timedelta
from typing import Optional

from .schemas import (
    SatisfactionMetrics,
    PerformanceMetrics,
    ActivityMetrics,
    CommunicationMetrics,
    EfficiencyMetrics,
)
from .database import get_db_session
from .collectors import (
    collect_satisfaction_metrics,
    collect_performance_metrics,
    collect_activity_metrics,
    collect_communication_metrics,
    collect_efficiency_metrics,
)

logger = logging.getLogger(__name__)


def calculate_devex_health_score(
    satisfaction: SatisfactionMetrics,
    performance: PerformanceMetrics,
    activity: ActivityMetrics,
    communication: CommunicationMetrics,
    efficiency: EfficiencyMetrics,
) -> float:
    """
    Calculate overall DevEx health score (0-100)

    Weights each SPACE dimension equally and normalizes to 0-100 scale.
    """
    scores = []

    # Satisfaction score (0-100)
    if satisfaction.nps_score is not None:
        # NPS ranges from -100 to 100, normalize to 0-100
        satisfaction_score = (satisfaction.nps_score + 100) / 2
        scores.append(satisfaction_score)
    elif satisfaction.satisfaction_rating is not None:
        # Satisfaction rating 1-5, normalize to 0-100
        satisfaction_score = (satisfaction.satisfaction_rating - 1) * 25
        scores.append(satisfaction_score)

    # Performance score (0-100)
    perf_components = []
    if performance.deployment_frequency is not None:
        # >2/day = 100, 1/day = 75, <0.5/day = 50
        perf_components.append(min(100, (performance.deployment_frequency / 2) * 100))
    if performance.change_failure_rate is not None:
        # <10% = 100, 15% = 75, >20% = 50
        perf_components.append(max(0, 100 - (performance.change_failure_rate * 5)))
    if performance.build_success_rate is not None:
        perf_components.append(performance.build_success_rate)
    if perf_components:
        scores.append(sum(perf_components) / len(perf_components))

    # Activity score (0-100)
    # Based on active developers and AI adoption
    activity_components = []
    if activity.active_developers_count > 0:
        activity_components.append(min(100, activity.active_developers_count * 10))
    if activity.ai_tool_adoption_rate is not None:
        activity_components.append(activity.ai_tool_adoption_rate)
    if activity_components:
        scores.append(sum(activity_components) / len(activity_components))

    # Communication score (0-100)
    comm_components = []
    if communication.avg_review_time_hours is not None:
        # <4 hours = 100, 12 hours = 75, >24 hours = 50
        comm_components.append(max(50, 100 - (communication.avg_review_time_hours * 2)))
    if communication.constructive_feedback_rate is not None:
        comm_components.append(communication.constructive_feedback_rate)
    if comm_components:
        scores.append(sum(comm_components) / len(comm_components))

    # Efficiency score (0-100)
    eff_components = []
    if efficiency.valuable_work_percentage is not None:
        eff_components.append(efficiency.valuable_work_percentage)
    if efficiency.flow_state_days is not None:
        # 5 days/week = 100, 3 days = 60, 1 day = 20
        eff_components.append((efficiency.flow_state_days / 5) * 100)
    if efficiency.cognitive_load_avg is not None:
        # 1-2 = 100, 3 = 60, 4-5 = 20
        eff_components.append(max(20, 120 - (efficiency.cognitive_load_avg * 20)))
    if eff_components:
        scores.append(sum(eff_components) / len(eff_components))

    # Calculate weighted average
    if not scores:
        return 0.0

    health_score = sum(scores) / len(scores)
    return round(health_score, 1)


async def expose_prometheus_metrics() -> str:
    """
    Generate Prometheus metrics in text format
    """
    try:
        now = datetime.utcnow()
        start_time = now - timedelta(hours=1)  # Last hour for current metrics

        async with get_db_session() as session:
            satisfaction = await collect_satisfaction_metrics(session, start_time, now)
            performance = await collect_performance_metrics(session, start_time, now)
            activity = await collect_activity_metrics(session, start_time, now)
            communication = await collect_communication_metrics(session, start_time, now)
            efficiency = await collect_efficiency_metrics(session, start_time, now)

            health_score = calculate_devex_health_score(satisfaction, performance, activity, communication, efficiency)

        metrics = []

        # Add HELP and TYPE comments
        metrics.append("# HELP space_nps_score Current NPS score")
        metrics.append("# TYPE space_nps_score gauge")
        if satisfaction.nps_score is not None:
            metrics.append(f"space_nps_score {satisfaction.nps_score}")

        metrics.append("# HELP space_satisfaction_rating Average satisfaction rating (1-5)")
        metrics.append("# TYPE space_satisfaction_rating gauge")
        if satisfaction.satisfaction_rating is not None:
            metrics.append(f"space_satisfaction_rating {satisfaction.satisfaction_rating}")

        metrics.append("# HELP space_burnout_percentage Percentage reporting burnout")
        metrics.append("# TYPE space_burnout_percentage gauge")
        if satisfaction.burnout_percentage is not None:
            metrics.append(f"space_burnout_percentage {satisfaction.burnout_percentage}")

        metrics.append("# HELP space_deployment_frequency Deployments per day")
        metrics.append("# TYPE space_deployment_frequency gauge")
        if performance.deployment_frequency is not None:
            metrics.append(f"space_deployment_frequency {performance.deployment_frequency}")

        metrics.append("# HELP space_lead_time_hours Average lead time in hours")
        metrics.append("# TYPE space_lead_time_hours gauge")
        if performance.lead_time_hours is not None:
            metrics.append(f"space_lead_time_hours {performance.lead_time_hours}")

        metrics.append("# HELP space_change_failure_rate Change failure rate percentage")
        metrics.append("# TYPE space_change_failure_rate gauge")
        if performance.change_failure_rate is not None:
            metrics.append(f"space_change_failure_rate {performance.change_failure_rate}")

        metrics.append("# HELP space_mttr_minutes Mean time to recovery in minutes")
        metrics.append("# TYPE space_mttr_minutes gauge")
        if performance.mttr_minutes is not None:
            metrics.append(f"space_mttr_minutes {performance.mttr_minutes}")

        metrics.append("# HELP space_commits_total Total commits")
        metrics.append("# TYPE space_commits_total counter")
        metrics.append(f"space_commits_total {activity.commits_count}")

        metrics.append("# HELP space_pull_requests_total Total pull requests")
        metrics.append("# TYPE space_pull_requests_total counter")
        metrics.append(f"space_pull_requests_total {activity.pull_requests_count}")

        metrics.append("# HELP space_active_developers Number of active developers")
        metrics.append("# TYPE space_active_developers gauge")
        metrics.append(f"space_active_developers {activity.active_developers_count}")

        metrics.append("# HELP space_ai_adoption_rate AI tool adoption percentage")
        metrics.append("# TYPE space_ai_adoption_rate gauge")
        if activity.ai_tool_adoption_rate is not None:
            metrics.append(f"space_ai_adoption_rate {activity.ai_tool_adoption_rate}")

        metrics.append("# HELP space_review_time_hours Average review time in hours")
        metrics.append("# TYPE space_review_time_hours gauge")
        if communication.avg_review_time_hours is not None:
            metrics.append(f"space_review_time_hours {communication.avg_review_time_hours}")

        metrics.append("# HELP space_pr_comments_avg Average PR comments")
        metrics.append("# TYPE space_pr_comments_avg gauge")
        if communication.pr_comments_avg is not None:
            metrics.append(f"space_pr_comments_avg {communication.pr_comments_avg}")

        metrics.append("# HELP space_cross_team_collaboration Cross-team PR count")
        metrics.append("# TYPE space_cross_team_collaboration counter")
        metrics.append(f"space_cross_team_collaboration {communication.cross_team_prs}")

        metrics.append("# HELP space_flow_state_days Days per week in flow state")
        metrics.append("# TYPE space_flow_state_days gauge")
        if efficiency.flow_state_days is not None:
            metrics.append(f"space_flow_state_days {efficiency.flow_state_days}")

        metrics.append("# HELP space_valuable_work_percentage Percentage time on valuable work")
        metrics.append("# TYPE space_valuable_work_percentage gauge")
        if efficiency.valuable_work_percentage is not None:
            metrics.append(f"space_valuable_work_percentage {efficiency.valuable_work_percentage}")

        metrics.append("# HELP space_friction_incidents Number of friction incidents")
        metrics.append("# TYPE space_friction_incidents counter")
        metrics.append(f"space_friction_incidents {efficiency.friction_incidents}")

        metrics.append("# HELP space_cognitive_load Average cognitive load (1-5)")
        metrics.append("# TYPE space_cognitive_load gauge")
        if efficiency.cognitive_load_avg is not None:
            metrics.append(f"space_cognitive_load {efficiency.cognitive_load_avg}")

        metrics.append("# HELP space_devex_health_score Overall DevEx health score (0-100)")
        metrics.append("# TYPE space_devex_health_score gauge")
        metrics.append(f"space_devex_health_score {health_score}")

        return "\n".join(metrics) + "\n"

    except Exception as e:
        logger.error(f"Error generating Prometheus metrics: {e}")
        return "# Error generating metrics\n"
