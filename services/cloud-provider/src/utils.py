"""Utility functions for cloud provider operations."""

import logging
import time
from functools import wraps
from typing import Callable, TypeVar, Optional
import random

from .exceptions import RateLimitError

logger = logging.getLogger(__name__)

T = TypeVar("T")


def retry_with_backoff(
    max_retries: int = 3,
    initial_delay: float = 1.0,
    max_delay: float = 60.0,
    exponential_base: float = 2.0,
    jitter: bool = True,
    retriable_exceptions: tuple = (Exception,),
):
    """
    Decorator for retrying operations with exponential backoff.

    Args:
        max_retries: Maximum number of retry attempts
        initial_delay: Initial delay in seconds
        max_delay: Maximum delay in seconds
        exponential_base: Base for exponential backoff calculation
        jitter: Whether to add random jitter to delay
        retriable_exceptions: Tuple of exceptions that should trigger a retry

    Returns:
        Decorated function with retry logic
    """

    def decorator(func: Callable[..., T]) -> Callable[..., T]:
        @wraps(func)
        def wrapper(*args, **kwargs) -> T:
            delay = initial_delay
            last_exception = None

            for attempt in range(max_retries + 1):
                try:
                    return func(*args, **kwargs)
                except retriable_exceptions as e:
                    last_exception = e

                    if attempt == max_retries:
                        logger.error(f"Max retries ({max_retries}) exceeded for {func.__name__}: {str(e)}")
                        raise

                    # Calculate delay with exponential backoff
                    delay = min(initial_delay * (exponential_base**attempt), max_delay)

                    # Add jitter if enabled
                    if jitter:
                        delay = delay * (0.5 + random.random())

                    logger.warning(
                        f"Retry {attempt + 1}/{max_retries} for {func.__name__} after {delay:.2f}s. Error: {str(e)}"
                    )
                    time.sleep(delay)

            # This should not be reached, but just in case
            if last_exception:
                raise last_exception

        return wrapper

    return decorator


class RateLimiter:
    """Token bucket rate limiter for API calls."""

    def __init__(self, max_calls: int, time_window: float):
        """
        Initialize rate limiter.

        Args:
            max_calls: Maximum number of calls allowed in the time window
            time_window: Time window in seconds
        """
        self.max_calls = max_calls
        self.time_window = time_window
        self.tokens = max_calls
        self.last_update = time.time()
        self.lock_count = 0

    def acquire(self, timeout: Optional[float] = None) -> bool:
        """
        Acquire permission to make an API call.

        Args:
            timeout: Maximum time to wait for a token (None = wait indefinitely)

        Returns:
            True if token was acquired, False if timeout exceeded

        Raises:
            RateLimitError: If timeout is exceeded
        """
        start_time = time.time()

        while True:
            # Refill tokens based on time passed
            now = time.time()
            time_passed = now - self.last_update
            tokens_to_add = time_passed * (self.max_calls / self.time_window)
            self.tokens = min(self.max_calls, self.tokens + tokens_to_add)
            self.last_update = now

            # Try to consume a token
            if self.tokens >= 1:
                self.tokens -= 1
                return True

            # Check timeout
            if timeout is not None:
                elapsed = time.time() - start_time
                if elapsed >= timeout:
                    raise RateLimitError(
                        f"Rate limit timeout exceeded after {elapsed:.2f}s", error_code="RATE_LIMIT_TIMEOUT"
                    )

            # Wait a bit before trying again
            wait_time = min(1.0, (1 - self.tokens) * (self.time_window / self.max_calls))
            time.sleep(wait_time)


def validate_region(region: str, valid_regions: list) -> None:
    """
    Validate that a region is valid.

    Args:
        region: Region to validate
        valid_regions: List of valid regions

    Raises:
        ValidationError: If region is invalid
    """
    from .exceptions import ValidationError

    if region not in valid_regions:
        raise ValidationError(f"Invalid region: {region}. Valid regions: {', '.join(valid_regions)}")


def validate_name(name: str, min_length: int = 1, max_length: int = 255, pattern: Optional[str] = None) -> None:
    """
    Validate resource name.

    Args:
        name: Name to validate
        min_length: Minimum length
        max_length: Maximum length
        pattern: Optional regex pattern to match

    Raises:
        ValidationError: If name is invalid
    """
    from .exceptions import ValidationError
    import re

    if not name or len(name) < min_length:
        raise ValidationError(f"Name must be at least {min_length} characters")

    if len(name) > max_length:
        raise ValidationError(f"Name must be at most {max_length} characters")

    if pattern and not re.match(pattern, name):
        raise ValidationError(f"Name does not match required pattern: {pattern}")
