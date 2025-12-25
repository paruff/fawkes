"""SonarQube integration for AI code review service."""
import logging
from typing import Dict, List, Optional
import httpx

logger = logging.getLogger(__name__)


class SonarQubeIntegration:
    """Integration with SonarQube for static analysis results."""

    def __init__(
        self,
        sonarqube_url: str,
        sonarqube_token: str,
        http_client: httpx.AsyncClient
    ):
        """Initialize SonarQube integration."""
        self.sonarqube_url = sonarqube_url.rstrip('/')
        self.sonarqube_token = sonarqube_token
        self.http_client = http_client

    async def get_pr_findings(self, repo: str, pr_number: int) -> List[Dict]:
        """
        Fetch SonarQube analysis results for a pull request.

        Args:
            repo: Repository full name (e.g., "owner/repo")
            pr_number: Pull request number

        Returns:
            List of findings with file, line, message, severity, category
        """
        if not self.sonarqube_token:
            logger.info("SonarQube token not configured, skipping integration")
            return []

        try:
            # Get project key from repo name
            project_key = repo.replace('/', ':')

            # Fetch issues for the pull request
            findings = await self._fetch_issues(project_key, pr_number)

            # Transform to standard format
            standardized = self._standardize_findings(findings)

            # Prioritize by severity
            prioritized = self._prioritize_findings(standardized)

            logger.info(f"Retrieved {len(prioritized)} findings from SonarQube")
            return prioritized

        except Exception as e:
            logger.error(f"Failed to fetch SonarQube findings: {e}")
            return []

    async def _fetch_issues(self, project_key: str, pr_number: int) -> List[Dict]:
        """Fetch issues from SonarQube API."""
        try:
            # SonarQube API endpoint for issues
            url = f"{self.sonarqube_url}/api/issues/search"

            # Parameters for pull request branch
            params = {
                "componentKeys": project_key,
                "pullRequest": str(pr_number),
                "resolved": "false",
                "ps": 100,  # Page size
                "statuses": "OPEN,CONFIRMED,REOPENED"
            }

            headers = {
                "Authorization": f"Bearer {self.sonarqube_token}"
            }

            response = await self.http_client.get(
                url,
                params=params,
                headers=headers,
                timeout=15.0
            )

            if response.status_code == 200:
                data = response.json()
                return data.get('issues', [])
            elif response.status_code == 404:
                # PR not analyzed yet or project doesn't exist
                logger.info(f"SonarQube project {project_key} or PR {pr_number} not found")
                return []
            else:
                logger.warning(f"SonarQube API returned status {response.status_code}")
                return []

        except Exception as e:
            logger.error(f"Failed to fetch issues from SonarQube: {e}")
            return []

    def _standardize_findings(self, sonarqube_issues: List[Dict]) -> List[Dict]:
        """
        Convert SonarQube issues to standardized finding format.

        Args:
            sonarqube_issues: Raw issues from SonarQube API

        Returns:
            Standardized findings
        """
        standardized = []

        for issue in sonarqube_issues:
            # Map SonarQube severity to our severity levels
            sq_severity = issue.get('severity', 'INFO')
            severity_map = {
                'BLOCKER': 'critical',
                'CRITICAL': 'critical',
                'MAJOR': 'high',
                'MINOR': 'medium',
                'INFO': 'low'
            }
            severity = severity_map.get(sq_severity, 'medium')

            # Map SonarQube type to our categories
            sq_type = issue.get('type', 'CODE_SMELL')
            category_map = {
                'BUG': 'quality',
                'VULNERABILITY': 'security',
                'SECURITY_HOTSPOT': 'security',
                'CODE_SMELL': 'best_practices'
            }
            category = category_map.get(sq_type, 'quality')

            # Extract file path (component relative to project)
            component = issue.get('component', '')
            file_path = component.split(':')[-1] if ':' in component else component

            finding = {
                'file': file_path,
                'line': issue.get('line', 1),
                'message': issue.get('message', 'No description'),
                'severity': severity,
                'category': category,
                'rule': issue.get('rule', ''),
                'effort': issue.get('effort', ''),
                'sonarqube_key': issue.get('key', '')
            }

            standardized.append(finding)

        return standardized

    def _prioritize_findings(self, findings: List[Dict]) -> List[Dict]:
        """
        Prioritize findings by severity and category.

        Args:
            findings: List of standardized findings

        Returns:
            Prioritized and sorted findings
        """
        # Define priority order
        severity_priority = {
            'critical': 0,
            'high': 1,
            'medium': 2,
            'low': 3
        }

        category_priority = {
            'security': 0,
            'quality': 1,
            'performance': 2,
            'best_practices': 3,
            'documentation': 4
        }

        # Sort by severity first, then category
        sorted_findings = sorted(
            findings,
            key=lambda f: (
                severity_priority.get(f['severity'], 99),
                category_priority.get(f['category'], 99)
            )
        )

        return sorted_findings

    def deduplicate_with_ai_findings(
        self,
        ai_findings: List[Dict],
        sonarqube_findings: List[Dict]
    ) -> List[Dict]:
        """
        Deduplicate findings between AI and SonarQube.

        Removes SonarQube findings that are likely duplicates of AI findings
        based on file path, line number, and similarity of messages.

        Args:
            ai_findings: Findings from AI review
            sonarqube_findings: Findings from SonarQube

        Returns:
            Deduplicated combined findings
        """
        deduplicated = list(ai_findings)

        for sq_finding in sonarqube_findings:
            is_duplicate = False

            for ai_finding in ai_findings:
                # Check if same file and line
                if (sq_finding['file'] == ai_finding.get('path') and
                    abs(sq_finding['line'] - ai_finding.get('line', 0)) <= 2):

                    # Check if similar category
                    if sq_finding['category'] == ai_finding.get('category'):
                        is_duplicate = True
                        logger.debug(
                            f"Deduplicating: SQ finding at {sq_finding['file']}:{sq_finding['line']} "
                            f"matches AI finding"
                        )
                        break

            if not is_duplicate:
                deduplicated.append(sq_finding)

        logger.info(
            f"Deduplicated findings: {len(ai_findings)} AI + "
            f"{len(sonarqube_findings)} SonarQube = "
            f"{len(deduplicated)} total (removed {len(ai_findings) + len(sonarqube_findings) - len(deduplicated)} duplicates)"
        )

        return deduplicated

    async def get_project_metrics(self, project_key: str) -> Optional[Dict]:
        """
        Get quality metrics for a project.

        Args:
            project_key: SonarQube project key

        Returns:
            Dictionary of metrics or None if unavailable
        """
        if not self.sonarqube_token:
            return None

        try:
            url = f"{self.sonarqube_url}/api/measures/component"

            params = {
                "component": project_key,
                "metricKeys": "bugs,vulnerabilities,code_smells,coverage,duplicated_lines_density"
            }

            headers = {
                "Authorization": f"Bearer {self.sonarqube_token}"
            }

            response = await self.http_client.get(
                url,
                params=params,
                headers=headers,
                timeout=10.0
            )

            if response.status_code == 200:
                data = response.json()
                component = data.get('component', {})
                measures = component.get('measures', [])

                metrics = {}
                for measure in measures:
                    metrics[measure['metric']] = measure.get('value', '0')

                return metrics
            else:
                return None

        except Exception as e:
            logger.error(f"Failed to fetch project metrics: {e}")
            return None
