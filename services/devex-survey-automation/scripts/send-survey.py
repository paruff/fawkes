#!/usr/bin/env python3
"""
Script to manually distribute surveys for testing or ad-hoc use.

Usage:
    python send-survey.py --type pulse --test-mode
    python send-survey.py --type deep_dive --users user1@example.com user2@example.com
"""
import asyncio
import argparse
import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

import httpx


async def distribute_survey(
    type: str,
    test_mode: bool = True,
    test_users: list = None,
    base_url: str = "http://localhost:8000"
):
    """Distribute survey via API"""
    endpoint = f"{base_url}/api/v1/survey/distribute"

    payload = {
        "type": type,
        "test_mode": test_mode
    }

    if test_users:
        payload["test_users"] = test_users

    print(f"Distributing {type} survey...")
    print(f"Test mode: {test_mode}")
    if test_users:
        print(f"Test users: {', '.join(test_users)}")

    try:
        async with httpx.AsyncClient() as client:
            response = await client.post(
                endpoint,
                json=payload,
                timeout=30.0
            )

            if response.status_code == 200:
                data = response.json()
                print("\n✅ Survey distribution successful!")
                print(f"Campaign ID: {data.get('campaign_id')}")
                print(f"Period: {data.get('period')} {data.get('year')}")
                print(f"Total sent: {data.get('total_sent')}")
                return True
            else:
                print(f"\n❌ Error: {response.status_code}")
                print(response.text)
                return False

    except Exception as e:
        print(f"\n❌ Failed to distribute survey: {e}")
        return False


async def check_campaigns(base_url: str = "http://localhost:8000"):
    """Check recent campaigns"""
    endpoint = f"{base_url}/api/v1/survey/campaigns"

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(endpoint, timeout=10.0)

            if response.status_code == 200:
                campaigns = response.json()

                if not campaigns:
                    print("No campaigns found.")
                    return

                print("\nRecent Campaigns:")
                print("-" * 80)
                for campaign in campaigns:
                    print(f"ID: {campaign['id']}")
                    print(f"Type: {campaign['type']}")
                    print(f"Period: {campaign['period']} {campaign['year']}")
                    print(f"Sent: {campaign['total_sent']}, Responses: {campaign['total_responses']}")
                    print(f"Response Rate: {campaign['response_rate']:.1f}%")
                    print("-" * 80)
            else:
                print(f"❌ Error fetching campaigns: {response.status_code}")

    except Exception as e:
        print(f"❌ Failed to fetch campaigns: {e}")


async def check_health(base_url: str = "http://localhost:8000"):
    """Check service health"""
    endpoint = f"{base_url}/health"

    try:
        async with httpx.AsyncClient() as client:
            response = await client.get(endpoint, timeout=5.0)

            if response.status_code == 200:
                health = response.json()
                print(f"\nService: {health['service']} v{health['version']}")
                print(f"Status: {health['status']}")
                print(f"Database: {'✅' if health['database_connected'] else '❌'}")
                print("Integrations:")
                for name, status in health['integrations'].items():
                    print(f"  {name}: {'✅' if status else '❌'}")
                return True
            else:
                print(f"❌ Service unhealthy: {response.status_code}")
                return False

    except Exception as e:
        print(f"❌ Cannot reach service: {e}")
        return False


def main():
    parser = argparse.ArgumentParser(
        description="Manually distribute DevEx surveys"
    )

    parser.add_argument(
        "--type",
        choices=["pulse", "deep_dive"],
        default="pulse",
        help="Survey type to distribute"
    )

    parser.add_argument(
        "--test-mode",
        action="store_true",
        help="Run in test mode (limited distribution)"
    )

    parser.add_argument(
        "--users",
        nargs="+",
        help="Specific users to send to (test mode)"
    )

    parser.add_argument(
        "--check-campaigns",
        action="store_true",
        help="Check recent campaigns instead of distributing"
    )

    parser.add_argument(
        "--check-health",
        action="store_true",
        help="Check service health"
    )

    parser.add_argument(
        "--base-url",
        default="http://localhost:8000",
        help="Base URL of the service"
    )

    args = parser.parse_args()

    if args.check_health:
        asyncio.run(check_health(args.base_url))
    elif args.check_campaigns:
        asyncio.run(check_campaigns(args.base_url))
    else:
        asyncio.run(
            distribute_survey(
                type=args.type,
                test_mode=args.test_mode,
                test_users=args.users,
                base_url=args.base_url
            )
        )


if __name__ == "__main__":
    main()
