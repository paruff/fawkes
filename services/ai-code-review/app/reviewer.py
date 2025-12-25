"""
Review engine for analyzing code and generating review comments.
"""
import os
import logging
from typing import Dict, List, Optional
import httpx
import json

from .main import ReviewComment, ReviewResult

logger = logging.getLogger(__name__)

# Configuration constants for review processing
MAX_FILES_TO_QUERY_RAG = 10  # Maximum files to include in RAG query
MAX_FILES_TO_REVIEW = 20  # Maximum files to review per PR
MAX_PATCH_SIZE = 2000  # Maximum patch size to send to LLM (chars)
MAX_COMMENTS_PER_REVIEW = 50  # Maximum comments to post in single review


class ReviewEngine:
    """Engine for performing AI-powered code reviews."""

    def __init__(
        self,
        rag_service_url: str,
        llm_api_key: str,
        llm_api_url: str,
        llm_model: str,
        github_token: str,
        sonarqube_url: str,
        sonarqube_token: str,
        http_client: httpx.AsyncClient
    ):
        """Initialize review engine."""
        self.rag_service_url = rag_service_url
        self.llm_api_key = llm_api_key
        self.llm_api_url = llm_api_url
        self.llm_model = llm_model
        self.github_token = github_token
        self.sonarqube_url = sonarqube_url
        self.sonarqube_token = sonarqube_token
        self.http_client = http_client

    async def review_pull_request(
        self,
        pr_data: Dict,
        repo_data: Dict
    ) -> ReviewResult:
        """Review a pull request and post comments."""
        import time
        start_time = time.time()

        pr_number = pr_data.get('number')
        repo_full_name = repo_data.get('full_name')

        # Fetch PR diff
        diff = await self._fetch_pr_diff(pr_data.get('diff_url'))

        # Fetch PR files
        files = await self._fetch_pr_files(repo_full_name, pr_number)

        # Query RAG for relevant patterns/standards
        rag_context = await self._query_rag_for_context(files)

        # Get SonarQube findings if available
        sonarqube_findings = await self._fetch_sonarqube_findings(repo_full_name, pr_number)

        # Generate review comments using LLM
        comments = await self._generate_review_comments(
            diff, files, rag_context, sonarqube_findings
        )

        # Filter out low-confidence comments
        filtered_comments = self._filter_comments(comments)

        # Post comments to GitHub
        await self._post_review_to_github(repo_full_name, pr_number, filtered_comments)

        # Calculate false positive rate estimate
        fp_rate = self._estimate_false_positive_rate(filtered_comments)

        duration_ms = (time.time() - start_time) * 1000

        return ReviewResult(
            pr_number=pr_number,
            repository=repo_full_name,
            comments=filtered_comments,
            review_time_ms=duration_ms,
            total_issues=len(filtered_comments),
            false_positive_rate=fp_rate
        )

    async def _fetch_pr_diff(self, diff_url: str) -> str:
        """Fetch PR diff from GitHub."""
        try:
            headers = {
                "Authorization": f"Bearer {self.github_token}",
                "Accept": "application/vnd.github.v3.diff"
            }
            response = await self.http_client.get(diff_url, headers=headers)
            response.raise_for_status()
            return response.text
        except Exception as e:
            logger.error(f"Failed to fetch PR diff: {e}")
            return ""

    async def _fetch_pr_files(self, repo: str, pr_number: int) -> List[Dict]:
        """Fetch list of files changed in PR."""
        try:
            url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}/files"
            headers = {
                "Authorization": f"Bearer {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }
            response = await self.http_client.get(url, headers=headers)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            logger.error(f"Failed to fetch PR files: {e}")
            return []

    async def _query_rag_for_context(self, files: List[Dict]) -> str:
        """Query RAG service for relevant patterns and standards."""
        try:
            # Build query from changed files
            file_extensions = set()
            for file in files[:MAX_FILES_TO_QUERY_RAG]:
                filename = file.get('filename', '')
                if '.' in filename:
                    file_extensions.add(filename.split('.')[-1])

            query = f"code review standards and best practices for {', '.join(file_extensions)} files"

            response = await self.http_client.post(
                f"{self.rag_service_url}/api/v1/query",
                json={"query": query, "top_k": 5},
                timeout=10.0
            )

            if response.status_code == 200:
                data = response.json()
                results = data.get('results', [])
                context = "\n\n".join([r.get('content', '') for r in results[:3]])
                logger.info(f"Retrieved RAG context: {len(context)} chars")
                return context
            else:
                logger.warning(f"RAG service returned status {response.status_code}")
                return ""
        except Exception as e:
            logger.error(f"Failed to query RAG service: {e}")
            return ""

    async def _fetch_sonarqube_findings(
        self,
        repo: str,
        pr_number: int
    ) -> List[Dict]:
        """Fetch SonarQube analysis findings."""
        try:
            # Lazy import to avoid loading unless needed
            from ..integrations.sonarqube import SonarQubeIntegration

            integration = SonarQubeIntegration(
                sonarqube_url=self.sonarqube_url,
                sonarqube_token=self.sonarqube_token,
                http_client=self.http_client
            )

            return await integration.get_pr_findings(repo, pr_number)
        except Exception as e:
            logger.error(f"Failed to fetch SonarQube findings: {e}")
            return []

    async def _generate_review_comments(
        self,
        diff: str,
        files: List[Dict],
        rag_context: str,
        sonarqube_findings: List[Dict]
    ) -> List[ReviewComment]:
        """Generate review comments using LLM."""
        comments = []

        # Load prompts (lazy import to avoid circular dependency)
        from ..prompts.loader import PromptLoader
        prompt_loader = PromptLoader()

        # Analyze each file
        for file_data in files[:MAX_FILES_TO_REVIEW]:
            filename = file_data.get('filename', '')
            patch = file_data.get('patch', '')

            if not patch:
                continue

            # Skip binary files and large files
            if file_data.get('status') == 'removed' or len(patch) > 10000:
                continue

            # Generate comments for different categories
            categories = ['security', 'performance', 'best_practices', 'documentation']

            for category in categories:
                try:
                    file_comments = await self._analyze_file_with_llm(
                        filename,
                        patch,
                        category,
                        rag_context,
                        prompt_loader
                    )
                    comments.extend(file_comments)
                except Exception as e:
                    logger.error(f"Failed to analyze {filename} for {category}: {e}")

        # Merge with SonarQube findings
        comments = self._merge_with_sonarqube(comments, sonarqube_findings)

        return comments

    async def _analyze_file_with_llm(
        self,
        filename: str,
        patch: str,
        category: str,
        rag_context: str,
        prompt_loader
    ) -> List[ReviewComment]:
        """Analyze a file using LLM for specific category."""
        try:
            # Get prompt for category
            system_prompt = prompt_loader.get_prompt(category, rag_context)

            # Build user message
            user_message = f"""Review the following code changes in file: {filename}

Code changes:
```
{patch[:MAX_PATCH_SIZE]}
```

Provide review comments in JSON format:
[
  {{
    "line": <line_number>,
    "comment": "<review comment>",
    "severity": "<critical|high|medium|low>",
    "confidence": <0.0-1.0>
  }}
]
"""

            # Call LLM API
            headers = {
                "Authorization": f"Bearer {self.llm_api_key}",
                "Content-Type": "application/json"
            }

            payload = {
                "model": self.llm_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message}
                ],
                "temperature": 0.3,
                "max_tokens": 1000
            }

            response = await self.http_client.post(
                self.llm_api_url,
                headers=headers,
                json=payload,
                timeout=30.0
            )

            if response.status_code != 200:
                logger.warning(f"LLM API returned status {response.status_code}")
                return []

            # Parse response
            result = response.json()
            content = result.get('choices', [{}])[0].get('message', {}).get('content', '')

            # Extract JSON from response
            comments = self._parse_llm_response(content, filename, category)
            return comments

        except Exception as e:
            logger.error(f"Failed to analyze file with LLM: {e}")
            return []

    def _parse_llm_response(
        self,
        content: str,
        filename: str,
        category: str
    ) -> List[ReviewComment]:
        """Parse LLM response into ReviewComment objects."""
        comments = []

        try:
            # Try to extract JSON from markdown code blocks
            if "```json" in content:
                json_start = content.index("```json") + 7
                json_end = content.index("```", json_start)
                content = content[json_start:json_end].strip()
            elif "```" in content:
                json_start = content.index("```") + 3
                json_end = content.index("```", json_start)
                content = content[json_start:json_end].strip()

            data = json.loads(content)

            if isinstance(data, list):
                for item in data:
                    if isinstance(item, dict):
                        comments.append(ReviewComment(
                            path=filename,
                            line=item.get('line', 1),
                            body=item.get('comment', ''),
                            category=category,
                            severity=item.get('severity', 'medium'),
                            confidence=item.get('confidence', 0.7)
                        ))
        except Exception as e:
            logger.warning(f"Failed to parse LLM response: {e}")

        return comments

    def _merge_with_sonarqube(
        self,
        ai_comments: List[ReviewComment],
        sonarqube_findings: List[Dict]
    ) -> List[ReviewComment]:
        """Merge AI comments with SonarQube findings, deduplicating."""
        # For now, just add both (deduplication logic can be added later)
        merged = list(ai_comments)

        for finding in sonarqube_findings:
            # Convert SonarQube finding to ReviewComment
            comment = ReviewComment(
                path=finding.get('file', ''),
                line=finding.get('line', 1),
                body=f"[SonarQube] {finding.get('message', '')}",
                category=finding.get('category', 'quality'),
                severity=finding.get('severity', 'medium').lower(),
                confidence=0.95  # SonarQube findings have high confidence
            )
            merged.append(comment)

        return merged

    def _filter_comments(self, comments: List[ReviewComment]) -> List[ReviewComment]:
        """Filter out low-confidence comments."""
        # Keep comments with confidence >= 0.6
        return [c for c in comments if c.confidence >= 0.6]

    def _estimate_false_positive_rate(self, comments: List[ReviewComment]) -> float:
        """Estimate false positive rate based on confidence scores."""
        if not comments:
            return 0.0

        # False positive rate is inverse of average confidence
        avg_confidence = sum(c.confidence for c in comments) / len(comments)
        return max(0.0, 1.0 - avg_confidence)

    async def _post_review_to_github(
        self,
        repo: str,
        pr_number: int,
        comments: List[ReviewComment]
    ):
        """Post review comments to GitHub PR."""
        try:
            # Prepare review comments (limit to avoid API rate limits)
            review_comments = []
            for comment in comments[:MAX_COMMENTS_PER_REVIEW]:
                review_comments.append({
                    "path": comment.path,
                    "line": comment.line,
                    "body": f"**[{comment.category.upper()}]** [{comment.severity.upper()}]\n\n{comment.body}\n\n*Confidence: {comment.confidence:.0%}*"
                })

            # Post review
            url = f"https://api.github.com/repos/{repo}/pulls/{pr_number}/reviews"
            headers = {
                "Authorization": f"Bearer {self.github_token}",
                "Accept": "application/vnd.github.v3+json"
            }

            payload = {
                "event": "COMMENT",
                "body": f"AI Code Review completed. Found {len(comments)} potential issues.",
                "comments": review_comments
            }

            response = await self.http_client.post(url, headers=headers, json=payload)

            if response.status_code == 200:
                logger.info(f"Successfully posted {len(review_comments)} review comments")
            else:
                logger.warning(f"Failed to post review: {response.status_code} - {response.text}")

        except Exception as e:
            logger.error(f"Failed to post review to GitHub: {e}")
