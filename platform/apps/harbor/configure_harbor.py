#!/usr/bin/env python3
"""
Harbor Post-Deployment Configuration Script

This script configures Harbor after initial deployment:
- Creates projects (fawkes, apps, library)
- Creates robot accounts for CI/CD
- Configures vulnerability scanning policies
- Sets up webhooks (optional)

Usage:
    python3 configure_harbor.py --harbor-url http://harbor.127.0.0.1.nip.io \
                                --admin-password Harbor12345

Requirements:
    pip install requests
"""

import argparse
import json
import logging
import sys
import time
from typing import Dict, List, Optional

import requests
from requests.auth import HTTPBasicAuth

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class HarborConfigurer:
    """Harbor configuration manager"""

    def __init__(self, base_url: str, username: str, password: str):
        """
        Initialize Harbor configurer.

        Args:
            base_url: Harbor base URL (e.g., http://harbor.127.0.0.1.nip.io)
            username: Admin username
            password: Admin password
        """
        self.base_url = base_url.rstrip('/')
        self.api_base = f"{self.base_url}/api/v2.0"
        self.auth = HTTPBasicAuth(username, password)
        self.session = requests.Session()
        self.session.auth = self.auth

    def wait_for_harbor(self, timeout: int = 300) -> bool:
        """
        Wait for Harbor to be ready.

        Args:
            timeout: Maximum time to wait in seconds

        Returns:
            True if Harbor is ready, False otherwise
        """
        logger.info("Waiting for Harbor to be ready...")
        start_time = time.time()
        while time.time() - start_time < timeout:
            try:
                response = self.session.get(
                    f"{self.api_base}/systeminfo",
                    timeout=5
                )
                if response.status_code == 200:
                    logger.info("Harbor is ready!")
                    return True
            except requests.exceptions.RequestException:
                pass
            time.sleep(5)
        logger.error(f"Harbor not ready after {timeout} seconds")
        return False

    def create_project(
        self,
        name: str,
        public: bool = False,
        storage_limit: int = -1
    ) -> Optional[Dict]:
        """
        Create a Harbor project.

        Args:
            name: Project name
            public: Whether project is public
            storage_limit: Storage quota in GB (-1 for unlimited)

        Returns:
            Project details if successful, None otherwise
        """
        logger.info(f"Creating project: {name}")

        # Check if project exists
        response = self.session.get(f"{self.api_base}/projects?name={name}")
        if response.status_code == 200 and response.json():
            logger.info(f"Project '{name}' already exists")
            return response.json()[0]

        # Create project
        project_data = {
            "project_name": name,
            "public": public,
            "metadata": {
                "public": "true" if public else "false",
                "enable_content_trust": "false",
                "prevent_vul": "false",
                "severity": "low",
                "auto_scan": "true"
            }
        }

        if storage_limit > 0:
            project_data["storage_limit"] = storage_limit * 1024 * 1024 * 1024

        response = self.session.post(
            f"{self.api_base}/projects",
            json=project_data
        )

        if response.status_code == 201:
            logger.info(f"Project '{name}' created successfully")
            # Get project details
            time.sleep(2)
            response = self.session.get(f"{self.api_base}/projects?name={name}")
            if response.status_code == 200 and response.json():
                return response.json()[0]
        else:
            logger.error(
                f"Failed to create project '{name}': "
                f"{response.status_code} - {response.text}"
            )
        return None

    def create_robot_account(
        self,
        project_name: str,
        robot_name: str,
        description: str,
        permissions: List[str]
    ) -> Optional[Dict]:
        """
        Create a robot account for CI/CD.

        Args:
            project_name: Project name
            robot_name: Robot account name (without robot$ prefix)
            description: Robot account description
            permissions: List of permissions (e.g., ['push', 'pull'])

        Returns:
            Robot account details including token, None otherwise
        """
        logger.info(f"Creating robot account: {robot_name} for project {project_name}")

        # Get project
        response = self.session.get(f"{self.api_base}/projects?name={project_name}")
        if response.status_code != 200 or not response.json():
            logger.error(f"Project '{project_name}' not found")
            return None

        project = response.json()[0]
        project_id = project['project_id']

        # Build permissions
        access = []
        if 'pull' in permissions:
            access.append({
                "resource": f"/project/{project_id}/repository",
                "action": "pull"
            })
        if 'push' in permissions:
            access.append({
                "resource": f"/project/{project_id}/repository",
                "action": "push"
            })

        robot_data = {
            "name": robot_name,
            "description": description,
            "duration": -1,  # Never expires
            "level": "project",
            "permissions": [{
                "kind": "project",
                "namespace": project_name,
                "access": access
            }]
        }

        response = self.session.post(
            f"{self.api_base}/robots",
            json=robot_data
        )

        if response.status_code == 201:
            robot_info = response.json()
            logger.info(f"Robot account created: {robot_info['name']}")
            # Note: Token is returned in robot_info['secret'] but not logged for security
            logger.info("Robot token generated successfully (returned in response)")
            return robot_info
        else:
            logger.error(
                f"Failed to create robot account: "
                f"{response.status_code} - {response.text}"
            )
        return None

    def configure_scan_policy(self, project_name: str) -> bool:
        """
        Configure automatic vulnerability scanning for a project.

        Args:
            project_name: Project name

        Returns:
            True if successful, False otherwise
        """
        logger.info(f"Configuring scan policy for project: {project_name}")

        # Get project
        response = self.session.get(f"{self.api_base}/projects?name={project_name}")
        if response.status_code != 200 or not response.json():
            logger.error(f"Project '{project_name}' not found")
            return False

        project = response.json()[0]
        project_id = project['project_id']

        # Update project metadata for auto-scan
        metadata = {
            "auto_scan": "true",
            "severity": "low",
            "prevent_vul": "false"
        }

        response = self.session.put(
            f"{self.api_base}/projects/{project_id}",
            json={"metadata": metadata}
        )

        if response.status_code == 200:
            logger.info(f"Scan policy configured for '{project_name}'")
            return True
        else:
            logger.error(
                f"Failed to configure scan policy: "
                f"{response.status_code} - {response.text}"
            )
        return False


def main():
    """Main function"""
    parser = argparse.ArgumentParser(
        description='Configure Harbor after deployment'
    )
    parser.add_argument(
        '--harbor-url',
        default='http://harbor.127.0.0.1.nip.io',
        help='Harbor base URL'
    )
    parser.add_argument(
        '--admin-username',
        default='admin',
        help='Harbor admin username'
    )
    parser.add_argument(
        '--admin-password',
        default='Harbor12345',
        help='Harbor admin password'
    )
    parser.add_argument(
        '--wait-timeout',
        type=int,
        default=300,
        help='Timeout for waiting Harbor to be ready (seconds)'
    )

    args = parser.parse_args()

    # Initialize configurer
    configurer = HarborConfigurer(
        args.harbor_url,
        args.admin_username,
        args.admin_password
    )

    # Wait for Harbor to be ready
    if not configurer.wait_for_harbor(args.wait_timeout):
        logger.error("Harbor is not ready. Exiting.")
        sys.exit(1)

    # Create projects
    projects = [
        {"name": "fawkes", "public": False, "storage_limit": 100},
        {"name": "apps", "public": False, "storage_limit": 200},
        {"name": "library", "public": True, "storage_limit": 50}
    ]

    for project_config in projects:
        project = configurer.create_project(**project_config)
        if project:
            # Configure scan policy
            configurer.configure_scan_policy(project_config["name"])

    # Create robot accounts for CI/CD
    robot_accounts = [
        {
            "project_name": "fawkes",
            "robot_name": "cicd-platform",
            "description": "Robot account for platform CI/CD pipelines",
            "permissions": ["push", "pull"]
        },
        {
            "project_name": "apps",
            "robot_name": "cicd-apps",
            "description": "Robot account for application CI/CD pipelines",
            "permissions": ["push", "pull"]
        }
    ]

    # Create robot accounts
    # Note: Robot tokens are returned by the API but not displayed for security
    # Administrators should retrieve tokens via Harbor UI or API after creation
    import sys
    robot_count = 0
    robot_names = []

    for robot_config in robot_accounts:
        robot = configurer.create_robot_account(**robot_config)
        if robot:
            robot_name = robot.get('name', 'unknown')
            robot_names.append(robot_name)
            logger.info(f"\n{'='*60}")
            logger.info(f"Robot Account: {robot_name}")
            logger.info(f"Robot account created successfully")
            logger.info(f"⚠️  Token generated but not displayed for security reasons")
            logger.info(f"To retrieve the token:")
            logger.info(f"  1. Login to Harbor UI at harbor.127.0.0.1.nip.io")
            logger.info(f"  2. Navigate to Projects > Robot Accounts")
            logger.info(f"  3. Recreate the robot account to get a new token")
            logger.info(f"OR use Harbor API to retrieve/regenerate the token")
            logger.info(f"Use this token in Jenkins credentials or GitLab CI/CD variables")
            logger.info(f"{'='*60}\n")

            robot_count += 1

    if robot_count > 0:
        logger.info(f"Created {robot_count} robot account(s): {', '.join(robot_names)}")
        logger.info("⚠️  For security, tokens are not displayed.")
        logger.info("⚠️  Retrieve tokens via Harbor UI or recreate robot accounts.")

    logger.info("Harbor configuration completed successfully!")


if __name__ == '__main__':
    main()
