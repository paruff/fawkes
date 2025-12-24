"""
Prometheus metrics for Feedback service.

This module provides enhanced metrics for feedback analytics including:
- NPS score calculation based on feedback ratings
- Feedback submission tracking by category and rating
- Response rate metrics
- Sentiment analysis metrics (when available)
"""
import logging
from prometheus_client import Counter, Gauge, Histogram
from typing import Optional
import asyncpg

logger = logging.getLogger(__name__)

# Basic feedback metrics
feedback_submissions_total = Counter(
    'feedback_submissions_total',
    'Total number of feedback submissions',
    ['category', 'rating']
)

feedback_request_duration = Histogram(
    'feedback_request_duration_seconds',
    'Time spent processing feedback requests',
    ['endpoint']
)

# NPS-related metrics
nps_score = Gauge(
    'nps_score',
    'Current NPS score (-100 to 100) calculated from feedback ratings',
    ['period']  # overall, last_30d, last_90d
)

nps_promoters_percentage = Gauge(
    'nps_promoters_percentage',
    'Percentage of promoters (ratings 5)',
    ['period']
)

nps_detractors_percentage = Gauge(
    'nps_detractors_percentage',
    'Percentage of detractors (ratings 1-3)',
    ['period']
)

nps_passives_percentage = Gauge(
    'nps_passives_percentage',
    'Percentage of passives (rating 4)',
    ['period']
)

# Response and engagement metrics
feedback_response_rate = Gauge(
    'feedback_response_rate',
    'Rate of feedback responses that have been addressed',
    ['status']
)

# Sentiment metrics
feedback_sentiment_score = Gauge(
    'feedback_sentiment_score',
    'Average sentiment score of feedback comments',
    ['category', 'sentiment']  # positive, neutral, negative
)

# Category metrics
feedback_by_category_total = Gauge(
    'feedback_by_category_total',
    'Total feedback count by category',
    ['category']
)

# Time-to-action metrics
feedback_time_to_action_seconds = Histogram(
    'feedback_time_to_action_seconds',
    'Time from feedback submission to first action (status change from open)',
    ['category'],
    buckets=[60, 300, 900, 1800, 3600, 7200, 14400, 28800, 86400, 172800, 604800, float("inf")]
)

feedback_avg_time_to_action_hours = Gauge(
    'feedback_avg_time_to_action_hours',
    'Average time to action in hours',
    ['status', 'category']
)


def calculate_nps_from_ratings(promoters: int, passives: int, detractors: int) -> float:
    """
    Calculate NPS score from feedback ratings.
    
    NPS Mapping for 1-5 star ratings:
    - Promoters: 5 stars (would recommend)
    - Passives: 4 stars (satisfied but not enthusiastic)
    - Detractors: 1-3 stars (unhappy customers)
    
    NPS = (% Promoters - % Detractors) * 100
    
    Args:
        promoters: Count of 5-star ratings
        passives: Count of 4-star ratings
        detractors: Count of 1-3 star ratings
    
    Returns:
        NPS score from -100 to 100
    """
    total = promoters + passives + detractors
    if total == 0:
        return 0.0
    
    promoter_pct = promoters / total
    detractor_pct = detractors / total
    
    return round((promoter_pct - detractor_pct) * 100, 2)


async def update_nps_metrics(conn: asyncpg.Connection, period: str = "overall"):
    """
    Update NPS metrics from database.
    
    Args:
        conn: Database connection
        period: Time period to calculate (overall, last_30d, last_90d)
    """
    try:
        # Build time filter based on period
        time_filter = ""
        if period == "last_30d":
            time_filter = "WHERE created_at >= NOW() - INTERVAL '30 days'"
        elif period == "last_90d":
            time_filter = "WHERE created_at >= NOW() - INTERVAL '90 days'"
        
        # Get rating distribution (1-5 stars mapped to NPS categories)
        query = f"""
            SELECT 
                COUNT(*) FILTER (WHERE rating = 5) as promoters,
                COUNT(*) FILTER (WHERE rating = 4) as passives,
                COUNT(*) FILTER (WHERE rating IN (1, 2, 3)) as detractors,
                COUNT(*) as total
            FROM feedback
            {time_filter}
        """
        
        stats = await conn.fetchrow(query)
        
        promoters = stats['promoters'] or 0
        passives = stats['passives'] or 0
        detractors = stats['detractors'] or 0
        total = stats['total'] or 0
        
        # Calculate NPS score
        nps = calculate_nps_from_ratings(promoters, passives, detractors)
        
        # Update Prometheus metrics
        nps_score.labels(period=period).set(nps)
        
        if total > 0:
            nps_promoters_percentage.labels(period=period).set(
                round((promoters / total) * 100, 2)
            )
            nps_passives_percentage.labels(period=period).set(
                round((passives / total) * 100, 2)
            )
            nps_detractors_percentage.labels(period=period).set(
                round((detractors / total) * 100, 2)
            )
        else:
            nps_promoters_percentage.labels(period=period).set(0)
            nps_passives_percentage.labels(period=period).set(0)
            nps_detractors_percentage.labels(period=period).set(0)
        
        logger.info(
            f"Updated NPS metrics for {period}: "
            f"score={nps}, promoters={promoters}, passives={passives}, detractors={detractors}"
        )
        
    except Exception as e:
        logger.error(f"Error updating NPS metrics: {e}")


async def update_response_rate_metrics(conn: asyncpg.Connection):
    """
    Update feedback response rate metrics.
    
    Args:
        conn: Database connection
    """
    try:
        # Get feedback counts by status
        query = """
            SELECT status, COUNT(*) as count
            FROM feedback
            GROUP BY status
        """
        
        rows = await conn.fetch(query)
        status_counts = {row['status']: row['count'] for row in rows}
        
        # Calculate total and addressed count
        total = sum(status_counts.values())
        addressed = status_counts.get('resolved', 0) + status_counts.get('in_progress', 0)
        
        if total > 0:
            # Overall response rate (addressed / total)
            overall_rate = round((addressed / total) * 100, 2)
            feedback_response_rate.labels(status='overall').set(overall_rate)
            
            # Individual status rates
            for status, count in status_counts.items():
                rate = round((count / total) * 100, 2)
                feedback_response_rate.labels(status=status).set(rate)
        
        logger.info(f"Updated response rate metrics: total={total}, addressed={addressed}")
        
    except Exception as e:
        logger.error(f"Error updating response rate metrics: {e}")


async def update_category_metrics(conn: asyncpg.Connection):
    """
    Update feedback category distribution metrics.
    
    Args:
        conn: Database connection
    """
    try:
        query = """
            SELECT category, COUNT(*) as count
            FROM feedback
            GROUP BY category
        """
        
        rows = await conn.fetch(query)
        
        for row in rows:
            feedback_by_category_total.labels(
                category=row['category']
            ).set(row['count'])
        
        logger.info(f"Updated category metrics for {len(rows)} categories")
        
    except Exception as e:
        logger.error(f"Error updating category metrics: {e}")


async def update_sentiment_metrics(conn: asyncpg.Connection):
    """
    Update sentiment analysis metrics.
    
    Args:
        conn: Database connection
    """
    try:
        # Check if sentiment column exists
        has_sentiment = await conn.fetchval("""
            SELECT EXISTS (
                SELECT 1 
                FROM information_schema.columns 
                WHERE table_name='feedback' 
                AND column_name='sentiment'
            )
        """)
        
        if not has_sentiment:
            logger.debug("Sentiment column not available, skipping sentiment metrics")
            return
        
        # Get average sentiment by category and sentiment type
        query = """
            SELECT 
                category,
                sentiment,
                AVG(sentiment_score) as avg_score,
                COUNT(*) as count
            FROM feedback
            WHERE sentiment IS NOT NULL
            GROUP BY category, sentiment
        """
        
        rows = await conn.fetch(query)
        
        for row in rows:
            feedback_sentiment_score.labels(
                category=row['category'],
                sentiment=row['sentiment']
            ).set(round(row['avg_score'], 3))
        
        logger.info(f"Updated sentiment metrics for {len(rows)} category-sentiment combinations")
        
    except Exception as e:
        logger.error(f"Error updating sentiment metrics: {e}")


async def update_time_to_action_metrics(conn: asyncpg.Connection):
    """
    Update time-to-action metrics.
    
    Calculates the time from feedback submission (created_at) to first action
    (status_changed_at), for feedback that has been acted upon.
    
    Args:
        conn: Database connection
    """
    try:
        # Check if status_changed_at column exists
        has_status_changed_at = await conn.fetchval("""
            SELECT EXISTS (
                SELECT 1 
                FROM information_schema.columns 
                WHERE table_name='feedback' 
                AND column_name='status_changed_at'
            )
        """)
        
        if not has_status_changed_at:
            logger.debug("status_changed_at column not available, skipping time-to-action metrics")
            return
        
        # Get average time to action by status and category
        query = """
            SELECT 
                status,
                category,
                AVG(EXTRACT(EPOCH FROM (status_changed_at - created_at)) / 3600) as avg_hours,
                COUNT(*) as count
            FROM feedback
            WHERE status_changed_at IS NOT NULL
            AND status != 'open'
            GROUP BY status, category
        """
        
        rows = await conn.fetch(query)
        
        for row in rows:
            if row['avg_hours'] is not None:
                feedback_avg_time_to_action_hours.labels(
                    status=row['status'],
                    category=row['category']
                ).set(round(row['avg_hours'], 2))
        
        logger.info(f"Updated time-to-action metrics for {len(rows)} status-category combinations")
        
    except Exception as e:
        logger.error(f"Error updating time-to-action metrics: {e}")


async def update_all_metrics(conn: asyncpg.Connection):
    """
    Update all feedback metrics from database.
    
    This is the main function to refresh all Prometheus metrics.
    Should be called periodically (e.g., every 5 minutes).
    
    Args:
        conn: Database connection
    """
    logger.info("Updating all feedback metrics...")
    
    # Update NPS metrics for different periods
    await update_nps_metrics(conn, "overall")
    await update_nps_metrics(conn, "last_30d")
    await update_nps_metrics(conn, "last_90d")
    
    # Update other metrics
    await update_response_rate_metrics(conn)
    await update_category_metrics(conn)
    await update_sentiment_metrics(conn)
    await update_time_to_action_metrics(conn)
    
    logger.info("All feedback metrics updated successfully")
