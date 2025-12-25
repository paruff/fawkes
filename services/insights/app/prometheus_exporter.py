"""Prometheus metrics exporter for Insights service."""
from prometheus_client import Gauge, Info
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta, timezone

from app.models import Insight, Tag, Category
from app.database import get_db


# Define Prometheus metrics
insights_total = Gauge('research_insights_total', 'Total number of research insights')
insights_by_status = Gauge('research_insights_by_status', 'Number of insights by status', ['status'])
insights_by_priority = Gauge('research_insights_by_priority', 'Number of insights by priority', ['priority'])
insights_by_category = Gauge('research_insights_by_category', 'Number of insights by category', ['category'])
tags_total = Gauge('research_tags_total', 'Total number of tags')
categories_total = Gauge('research_categories_total', 'Total number of categories')
insights_validated = Gauge('research_insights_validated', 'Number of validated (published) insights')
insights_validation_rate = Gauge('research_insights_validation_rate', 'Percentage of insights validated', ['category'])
insights_time_to_action = Gauge('research_insights_time_to_action_seconds', 'Time from creation to publication', ['category'])
insights_published_last_7d = Gauge('research_insights_published_last_7d', 'Insights published in last 7 days')
insights_published_last_30d = Gauge('research_insights_published_last_30d', 'Insights published in last 30 days')
tag_usage_count = Gauge('research_tag_usage_count', 'Usage count for tags', ['tag'])


def update_prometheus_metrics(db: Session):
    """Update Prometheus metrics with current insights data."""
    # Total insights
    total = db.query(Insight).count()
    insights_total.set(total)
    
    # Insights by status
    status_counts = db.query(
        Insight.status, func.count(Insight.id)
    ).group_by(Insight.status).all()
    
    for status, count in status_counts:
        insights_by_status.labels(status=status).set(count)
    
    # Insights by priority
    priority_counts = db.query(
        Insight.priority, func.count(Insight.id)
    ).group_by(Insight.priority).all()
    
    for priority, count in priority_counts:
        insights_by_priority.labels(priority=priority).set(count)
    
    # Insights by category
    category_counts = db.query(
        Category.name, func.count(Insight.id)
    ).join(Insight, Category.id == Insight.category_id, isouter=True
    ).group_by(Category.name).all()
    
    for name, count in category_counts:
        category_name = name if name else "Uncategorized"
        insights_by_category.labels(category=category_name).set(count)
    
    # Total tags and categories
    total_tags = db.query(Tag).count()
    total_categories = db.query(Category).count()
    tags_total.set(total_tags)
    categories_total.set(total_categories)
    
    # Validated insights (published)
    validated_count = db.query(Insight).filter(Insight.status == "published").count()
    insights_validated.set(validated_count)
    
    # Validation rate by category
    categories = db.query(Category).all()
    for category in categories:
        total_in_category = db.query(Insight).filter(Insight.category_id == category.id).count()
        if total_in_category > 0:
            published_in_category = db.query(Insight).filter(
                Insight.category_id == category.id,
                Insight.status == "published"
            ).count()
            validation_rate = (published_in_category / total_in_category) * 100
            insights_validation_rate.labels(category=category.name).set(validation_rate)
    
    # Time to action (creation to publication) by category
    categories_with_published = db.query(Category).join(
        Insight, Category.id == Insight.category_id
    ).filter(
        Insight.status == "published",
        Insight.published_at.isnot(None)
    ).distinct().all()
    
    for category in categories_with_published:
        # Get average time to publication for this category
        published_insights = db.query(Insight).filter(
            Insight.category_id == category.id,
            Insight.status == "published",
            Insight.published_at.isnot(None)
        ).all()
        
        if published_insights:
            time_deltas = []
            for insight in published_insights:
                if insight.published_at and insight.created_at:
                    delta = (insight.published_at - insight.created_at).total_seconds()
                    time_deltas.append(delta)
            
            if time_deltas:
                avg_time = sum(time_deltas) / len(time_deltas)
                insights_time_to_action.labels(category=category.name).set(avg_time)
    
    # Insights published in last 7 days
    seven_days_ago = datetime.now(timezone.utc) - timedelta(days=7)
    last_7d_count = db.query(Insight).filter(
        Insight.status == "published",
        Insight.published_at >= seven_days_ago
    ).count()
    insights_published_last_7d.set(last_7d_count)
    
    # Insights published in last 30 days
    thirty_days_ago = datetime.now(timezone.utc) - timedelta(days=30)
    last_30d_count = db.query(Insight).filter(
        Insight.status == "published",
        Insight.published_at >= thirty_days_ago
    ).count()
    insights_published_last_30d.set(last_30d_count)
    
    # Tag usage counts
    tags = db.query(Tag).all()
    for tag in tags:
        tag_usage_count.labels(tag=tag.name).set(tag.usage_count)
