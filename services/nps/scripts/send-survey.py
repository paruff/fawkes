#!/usr/bin/env python3
"""
Script to manually trigger NPS survey distribution.

Usage:
    python send-survey.py --test-users
    python send-survey.py --all-users
    python send-survey.py --send-reminders
"""
import os
import sys
import asyncio
import argparse
import logging
from datetime import datetime

import asyncpg

# NOTE: sys.path modification is a temporary solution for script execution
# In production, install as package: pip install -e .
# Add parent directory to path for imports
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from integrations.mattermost import send_surveys_to_users, send_reminders

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://nps:nps@db-nps-dev-rw.fawkes.svc.cluster.local:5432/nps_db"
)
BASE_SURVEY_URL = os.getenv("BASE_SURVEY_URL", "http://nps.local/survey")
MATTERMOST_BOT_USER_ID = os.getenv("MATTERMOST_BOT_USER_ID", "")


# Test users for validation
TEST_USERS = [
    {"user_id": "test_user_1", "email": "test1@example.com"},
    {"user_id": "test_user_2", "email": "test2@example.com"},
    {"user_id": "test_user_3", "email": "test3@example.com"},
]


async def get_all_users_from_backstage() -> list:
    """
    Get all active users from Backstage catalog.
    
    In production, this would query the Backstage API or database
    to get the list of active platform users.
    """
    # TODO: Implement actual Backstage integration
    logger.warning("Using mock user list. Implement Backstage integration for production.")
    
    # Mock users for now
    return [
        {"user_id": "user1", "email": "user1@example.com"},
        {"user_id": "user2", "email": "user2@example.com"},
    ]


async def create_campaign(conn: asyncpg.Connection, quarter: str, year: int) -> int:
    """Create a new survey campaign."""
    try:
        campaign_id = await conn.fetchval("""
            INSERT INTO survey_campaigns (quarter, year)
            VALUES ($1, $2)
            ON CONFLICT (quarter, year) DO UPDATE
            SET started_at = CURRENT_TIMESTAMP
            RETURNING id
        """, quarter, year)
        
        logger.info(f"Created/updated campaign: Q{quarter} {year} (ID: {campaign_id})")
        return campaign_id
    except Exception as e:
        logger.error(f"Error creating campaign: {e}")
        raise


async def update_campaign_stats(
    conn: asyncpg.Connection,
    campaign_id: int,
    sent_count: int
):
    """Update campaign statistics."""
    try:
        await conn.execute("""
            UPDATE survey_campaigns
            SET total_sent = total_sent + $2
            WHERE id = $1
        """, campaign_id, sent_count)
        
        logger.info(f"Updated campaign {campaign_id}: +{sent_count} sent")
    except Exception as e:
        logger.error(f"Error updating campaign stats: {e}")


async def send_test_surveys(db_pool: asyncpg.Pool):
    """Send surveys to test users."""
    logger.info("Sending surveys to test users...")
    
    if not MATTERMOST_BOT_USER_ID:
        logger.error("MATTERMOST_BOT_USER_ID not set. Cannot send surveys.")
        return
    
    results = await send_surveys_to_users(
        db_pool,
        TEST_USERS,
        BASE_SURVEY_URL,
        MATTERMOST_BOT_USER_ID
    )
    
    logger.info(f"Test survey distribution complete: {results}")


async def send_all_surveys(db_pool: asyncpg.Pool):
    """Send surveys to all platform users."""
    logger.info("Sending surveys to all platform users...")
    
    if not MATTERMOST_BOT_USER_ID:
        logger.error("MATTERMOST_BOT_USER_ID not set. Cannot send surveys.")
        return
    
    # Get current quarter
    now = datetime.now()
    quarter = (now.month - 1) // 3 + 1
    year = now.year
    
    # Get all users
    users = await get_all_users_from_backstage()
    logger.info(f"Found {len(users)} users to survey")
    
    # Create campaign
    async with db_pool.acquire() as conn:
        campaign_id = await create_campaign(conn, f"Q{quarter}", year)
    
    # Send surveys
    results = await send_surveys_to_users(
        db_pool,
        users,
        BASE_SURVEY_URL,
        MATTERMOST_BOT_USER_ID,
        campaign_id
    )
    
    # Update campaign stats
    async with db_pool.acquire() as conn:
        await update_campaign_stats(conn, campaign_id, results['sent'])
    
    logger.info(f"Survey distribution complete: {results}")


async def send_reminder_surveys(db_pool: asyncpg.Pool):
    """Send reminder surveys to non-respondents."""
    logger.info("Sending reminder surveys...")
    
    if not MATTERMOST_BOT_USER_ID:
        logger.error("MATTERMOST_BOT_USER_ID not set. Cannot send reminders.")
        return
    
    results = await send_reminders(
        db_pool,
        BASE_SURVEY_URL,
        MATTERMOST_BOT_USER_ID
    )
    
    logger.info(f"Reminder distribution complete: {results}")


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(description="Send NPS surveys")
    parser.add_argument(
        "--test-users",
        action="store_true",
        help="Send surveys to test users only"
    )
    parser.add_argument(
        "--all-users",
        action="store_true",
        help="Send surveys to all platform users"
    )
    parser.add_argument(
        "--send-reminders",
        action="store_true",
        help="Send reminder surveys to non-respondents"
    )
    
    args = parser.parse_args()
    
    if not any([args.test_users, args.all_users, args.send_reminders]):
        parser.print_help()
        sys.exit(1)
    
    # Connect to database
    try:
        db_pool = await asyncpg.create_pool(DATABASE_URL, min_size=1, max_size=5)
        logger.info("Connected to database")
    except Exception as e:
        logger.error(f"Failed to connect to database: {e}")
        sys.exit(1)
    
    try:
        if args.test_users:
            await send_test_surveys(db_pool)
        elif args.all_users:
            await send_all_surveys(db_pool)
        elif args.send_reminders:
            await send_reminder_surveys(db_pool)
    finally:
        await db_pool.close()
        logger.info("Database connection closed")


if __name__ == "__main__":
    asyncio.run(main())
