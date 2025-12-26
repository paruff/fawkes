"""Prompt loader for AI code review."""
import os
from pathlib import Path
from typing import Dict


class PromptLoader:
    """Load and manage review prompts."""

    def __init__(self):
        """Initialize prompt loader."""
        self.prompts_dir = Path(__file__).parent.parent / "prompts"
        self._prompts_cache: Dict[str, str] = {}

    def get_prompt(self, category: str, rag_context: str = "") -> str:
        """Get prompt for a specific review category."""
        if category not in self._prompts_cache:
            prompt_file = self.prompts_dir / f"{category}.txt"
            if prompt_file.exists():
                with open(prompt_file, "r") as f:
                    self._prompts_cache[category] = f.read()
            else:
                # Return default prompt if file doesn't exist
                self._prompts_cache[category] = self._get_default_prompt(category)

        prompt = self._prompts_cache[category]

        # Add RAG context if available
        if rag_context:
            prompt = f"{prompt}\n\nRelevant standards and patterns from codebase:\n{rag_context}"

        return prompt

    def _get_default_prompt(self, category: str) -> str:
        """Get default prompt for a category."""
        defaults = {
            "security": """You are a security-focused code reviewer. Review the code changes for potential security vulnerabilities.
Focus on:
- SQL injection, XSS, CSRF vulnerabilities
- Authentication and authorization issues
- Secrets or credentials in code
- Input validation and sanitization
- Insecure cryptography or hashing
- Path traversal vulnerabilities
- Command injection risks

Provide specific, actionable feedback. Only report genuine security concerns.""",
            "performance": """You are a performance-focused code reviewer. Review the code changes for performance issues.
Focus on:
- N+1 query problems
- Inefficient loops or algorithms
- Memory leaks or excessive memory usage
- Blocking operations in async code
- Missing database indexes
- Redundant computations
- Inefficient data structures

Provide specific, actionable feedback. Only report significant performance concerns.""",
            "best_practices": """You are a code quality reviewer. Review the code changes for adherence to best practices.
Focus on:
- Code organization and structure
- Naming conventions
- DRY (Don't Repeat Yourself) violations
- SOLID principles
- Error handling patterns
- Logging and debugging aids
- Code readability and maintainability

Provide specific, actionable feedback. Focus on important issues.""",
            "test_coverage": """You are a testing-focused code reviewer. Review the code changes for testing gaps.
Focus on:
- Missing unit tests for new functions
- Missing edge case tests
- Insufficient error condition testing
- Missing integration tests
- Test quality and coverage
- Mock usage appropriateness

Provide specific, actionable feedback about testing needs.""",
            "documentation": """You are a documentation-focused code reviewer. Review the code changes for documentation quality.
Focus on:
- Missing or inadequate docstrings
- Unclear or missing API documentation
- Missing inline comments for complex logic
- Outdated documentation
- Missing README updates
- Unclear variable or function names

Provide specific, actionable feedback about documentation needs.""",
        }

        return defaults.get(category, "Review the code changes and provide feedback.")
