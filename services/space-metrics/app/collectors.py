"""
Metrics collectors for each SPACE dimension
"""

import os
import logging
from datetime import datetime
from typing import Optional
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from .models import (
    SpaceSatisfaction,
    SpacePerformance,
    SpaceActivity,
    SpaceCommunication,
    SpaceEfficiency,
)
from .schemas import (
    SatisfactionMetrics,
    PerformanceMetrics,
    ActivityMetrics,
    CommunicationMetrics,
    EfficiencyMetrics,
)

logger = logging.getLogger(__name__)

AGGREGATION_THRESHOLD = int(os.getenv("AGGREGATION_THRESHOLD", "5"))


async def collect_satisfaction_metrics(
    session: AsyncSession,
    start_time: datetime,
    end_time: datetime
) -> SatisfactionMetrics:
    """
    Collect satisfaction dimension metrics
    
    Aggregates NPS scores, satisfaction ratings, and burnout percentages
    from survey responses within the time range.
    """
    try:
        # Query satisfaction metrics
        result = await session.execute(
            select(
                func.avg(SpaceSatisfaction.nps_score).label("nps_score"),
                func.avg(SpaceSatisfaction.satisfaction_rating).label("satisfaction_rating"),
                func.avg(SpaceSatisfaction.burnout_percentage).label("burnout_percentage"),
                func.sum(SpaceSatisfaction.response_count).label("response_count"),
            ).where(
                SpaceSatisfaction.timestamp >= start_time,
                SpaceSatisfaction.timestamp <= end_time,
            )
        )
        
        row = result.first()
        
        return SatisfactionMetrics(
            nps_score=round(row.nps_score, 1) if row.nps_score else None,
            satisfaction_rating=round(row.satisfaction_rating, 2) if row.satisfaction_rating else None,
            burnout_percentage=round(row.burnout_percentage, 1) if row.burnout_percentage else None,
            response_count=int(row.response_count) if row.response_count else 0,
        )
    except Exception as e:
        logger.error(f"Error collecting satisfaction metrics: {e}")
        return SatisfactionMetrics(response_count=0)


async def collect_performance_metrics(
    session: AsyncSession,
    start_time: datetime,
    end_time: datetime
) -> PerformanceMetrics:
    """
    Collect performance dimension metrics
    
    Aggregates DORA metrics and build performance data.
    """
    try:
        result = await session.execute(
            select(
                func.avg(SpacePerformance.deployment_frequency).label("deployment_frequency"),
                func.avg(SpacePerformance.lead_time_hours).label("lead_time_hours"),
                func.avg(SpacePerformance.change_failure_rate).label("change_failure_rate"),
                func.avg(SpacePerformance.mttr_minutes).label("mttr_minutes"),
                func.avg(SpacePerformance.build_success_rate).label("build_success_rate"),
                func.avg(SpacePerformance.test_coverage).label("test_coverage"),
            ).where(
                SpacePerformance.timestamp >= start_time,
                SpacePerformance.timestamp <= end_time,
            )
        )
        
        row = result.first()
        
        return PerformanceMetrics(
            deployment_frequency=round(row.deployment_frequency, 2) if row.deployment_frequency else None,
            lead_time_hours=round(row.lead_time_hours, 1) if row.lead_time_hours else None,
            change_failure_rate=round(row.change_failure_rate, 1) if row.change_failure_rate else None,
            mttr_minutes=round(row.mttr_minutes, 1) if row.mttr_minutes else None,
            build_success_rate=round(row.build_success_rate, 1) if row.build_success_rate else None,
            test_coverage=round(row.test_coverage, 1) if row.test_coverage else None,
        )
    except Exception as e:
        logger.error(f"Error collecting performance metrics: {e}")
        return PerformanceMetrics()


async def collect_activity_metrics(
    session: AsyncSession,
    start_time: datetime,
    end_time: datetime
) -> ActivityMetrics:
    """
    Collect activity dimension metrics
    
    Aggregates developer activity from GitHub, Backstage, etc.
    """
    try:
        result = await session.execute(
            select(
                func.sum(SpaceActivity.commits_count).label("commits_count"),
                func.sum(SpaceActivity.pull_requests_count).label("pull_requests_count"),
                func.sum(SpaceActivity.code_reviews_count).label("code_reviews_count"),
                func.avg(SpaceActivity.active_developers_count).label("active_developers_count"),
                func.avg(SpaceActivity.ai_tool_adoption_rate).label("ai_tool_adoption_rate"),
                func.sum(SpaceActivity.platform_usage_count).label("platform_usage_count"),
            ).where(
                SpaceActivity.timestamp >= start_time,
                SpaceActivity.timestamp <= end_time,
            )
        )
        
        row = result.first()
        
        # Check aggregation threshold
        active_devs = int(row.active_developers_count) if row.active_developers_count else 0
        if active_devs < AGGREGATION_THRESHOLD:
            logger.warning(f"Active developers ({active_devs}) below threshold ({AGGREGATION_THRESHOLD})")
        
        return ActivityMetrics(
            commits_count=int(row.commits_count) if row.commits_count else 0,
            pull_requests_count=int(row.pull_requests_count) if row.pull_requests_count else 0,
            code_reviews_count=int(row.code_reviews_count) if row.code_reviews_count else 0,
            active_developers_count=active_devs,
            ai_tool_adoption_rate=round(row.ai_tool_adoption_rate, 1) if row.ai_tool_adoption_rate else None,
            platform_usage_count=int(row.platform_usage_count) if row.platform_usage_count else 0,
        )
    except Exception as e:
        logger.error(f"Error collecting activity metrics: {e}")
        return ActivityMetrics()


async def collect_communication_metrics(
    session: AsyncSession,
    start_time: datetime,
    end_time: datetime
) -> CommunicationMetrics:
    """
    Collect communication dimension metrics
    
    Aggregates collaboration quality metrics.
    """
    try:
        result = await session.execute(
            select(
                func.avg(SpaceCommunication.avg_review_time_hours).label("avg_review_time_hours"),
                func.avg(SpaceCommunication.pr_comments_avg).label("pr_comments_avg"),
                func.sum(SpaceCommunication.cross_team_prs).label("cross_team_prs"),
                func.sum(SpaceCommunication.mattermost_messages).label("mattermost_messages"),
                func.avg(SpaceCommunication.constructive_feedback_rate).label("constructive_feedback_rate"),
            ).where(
                SpaceCommunication.timestamp >= start_time,
                SpaceCommunication.timestamp <= end_time,
            )
        )
        
        row = result.first()
        
        return CommunicationMetrics(
            avg_review_time_hours=round(row.avg_review_time_hours, 1) if row.avg_review_time_hours else None,
            pr_comments_avg=round(row.pr_comments_avg, 1) if row.pr_comments_avg else None,
            cross_team_prs=int(row.cross_team_prs) if row.cross_team_prs else 0,
            mattermost_messages=int(row.mattermost_messages) if row.mattermost_messages else 0,
            constructive_feedback_rate=round(row.constructive_feedback_rate, 1) if row.constructive_feedback_rate else None,
        )
    except Exception as e:
        logger.error(f"Error collecting communication metrics: {e}")
        return CommunicationMetrics()


async def collect_efficiency_metrics(
    session: AsyncSession,
    start_time: datetime,
    end_time: datetime
) -> EfficiencyMetrics:
    """
    Collect efficiency dimension metrics
    
    Aggregates flow state, friction, and cognitive load data.
    """
    try:
        result = await session.execute(
            select(
                func.avg(SpaceEfficiency.flow_state_days).label("flow_state_days"),
                func.avg(SpaceEfficiency.valuable_work_percentage).label("valuable_work_percentage"),
                func.sum(SpaceEfficiency.friction_incidents).label("friction_incidents"),
                func.avg(SpaceEfficiency.context_switches).label("context_switches"),
                func.avg(SpaceEfficiency.cognitive_load_avg).label("cognitive_load_avg"),
            ).where(
                SpaceEfficiency.timestamp >= start_time,
                SpaceEfficiency.timestamp <= end_time,
            )
        )
        
        row = result.first()
        
        return EfficiencyMetrics(
            flow_state_days=round(row.flow_state_days, 1) if row.flow_state_days else None,
            valuable_work_percentage=round(row.valuable_work_percentage, 1) if row.valuable_work_percentage else None,
            friction_incidents=int(row.friction_incidents) if row.friction_incidents else 0,
            context_switches=round(row.context_switches, 1) if row.context_switches else None,
            cognitive_load_avg=round(row.cognitive_load_avg, 1) if row.cognitive_load_avg else None,
        )
    except Exception as e:
        logger.error(f"Error collecting efficiency metrics: {e}")
        return EfficiencyMetrics()
