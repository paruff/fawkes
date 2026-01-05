"""Unit tests for utility functions."""

import pytest
import time
from unittest.mock import Mock

from src.utils import retry_with_backoff, RateLimiter, validate_region, validate_name
from src.exceptions import RateLimitError, ValidationError


class TestRetryWithBackoff:
    """Test retry with exponential backoff decorator."""

    def test_successful_call(self):
        """Test that successful call returns immediately."""
        mock_func = Mock(return_value="success")
        decorated = retry_with_backoff(max_retries=3)(mock_func)

        result = decorated()

        assert result == "success"
        assert mock_func.call_count == 1

    def test_retry_on_exception(self):
        """Test that function retries on exception."""
        call_count = [0]

        def test_func():
            call_count[0] += 1
            if call_count[0] < 3:
                raise Exception(f"error {call_count[0]}")
            return "success"

        decorated = retry_with_backoff(max_retries=3, initial_delay=0.01)(test_func)

        result = decorated()

        assert result == "success"
        assert call_count[0] == 3

    def test_max_retries_exceeded(self):
        """Test that function raises after max retries."""
        call_count = [0]

        def test_func():
            call_count[0] += 1
            raise Exception("persistent error")

        decorated = retry_with_backoff(max_retries=2, initial_delay=0.01)(test_func)

        with pytest.raises(Exception) as exc_info:
            decorated()

        assert "persistent error" in str(exc_info.value)
        assert call_count[0] == 3  # Initial + 2 retries

    def test_exponential_backoff(self):
        """Test that delay increases exponentially."""
        call_times = []

        def track_time():
            call_times.append(time.time())
            if len(call_times) < 3:
                raise Exception("retry")
            return "success"

        decorated = retry_with_backoff(max_retries=3, initial_delay=0.1, jitter=False)(track_time)

        result = decorated()

        assert result == "success"
        assert len(call_times) == 3

        # Check that delays are increasing
        delay1 = call_times[1] - call_times[0]
        delay2 = call_times[2] - call_times[1]
        assert delay2 > delay1

    def test_specific_exception_retry(self):
        """Test that only specific exceptions trigger retry."""

        class RetriableError(Exception):
            pass

        class NonRetriableError(Exception):
            pass

        call_count = [0]

        def test_func():
            call_count[0] += 1
            raise NonRetriableError("non-retriable")

        decorated = retry_with_backoff(max_retries=3, initial_delay=0.01, retriable_exceptions=(RetriableError,))(
            test_func
        )

        with pytest.raises(NonRetriableError):
            decorated()

        # Should fail immediately without retries
        assert call_count[0] == 1


class TestRateLimiter:
    """Test rate limiter."""

    def test_acquire_within_limit(self):
        """Test that requests within limit are allowed."""
        limiter = RateLimiter(max_calls=10, time_window=1.0)

        # Should be able to acquire 10 tokens immediately
        for _ in range(10):
            assert limiter.acquire(timeout=0.1) is True

    def test_acquire_exceeds_limit(self):
        """Test that requests exceeding limit are throttled."""
        # Use smaller time window and timeout to make test reliable
        limiter = RateLimiter(max_calls=2, time_window=10.0)  # 10 second window

        # First 2 should succeed
        assert limiter.acquire(timeout=0.01) is True
        assert limiter.acquire(timeout=0.01) is True

        # Third should timeout immediately since refill is slow
        with pytest.raises(RateLimitError):
            limiter.acquire(timeout=0.001)

    def test_token_refill(self):
        """Test that tokens are refilled over time."""
        limiter = RateLimiter(max_calls=2, time_window=0.5)

        # Exhaust tokens
        limiter.acquire(timeout=0.1)
        limiter.acquire(timeout=0.1)

        # Wait for refill
        time.sleep(0.6)

        # Should be able to acquire again
        assert limiter.acquire(timeout=0.1) is True

    def test_acquire_no_timeout(self):
        """Test that acquire waits indefinitely without timeout."""
        limiter = RateLimiter(max_calls=1, time_window=0.5)

        # Exhaust token
        limiter.acquire()

        # This should wait and succeed
        start = time.time()
        limiter.acquire(timeout=None)
        elapsed = time.time() - start

        # Should have waited for token refill
        assert elapsed >= 0.3  # Some time should have passed


class TestValidateRegion:
    """Test region validation."""

    def test_valid_region(self):
        """Test that valid region passes."""
        valid_regions = ["us-east-1", "us-west-2", "eu-west-1"]

        # Should not raise
        validate_region("us-east-1", valid_regions)
        validate_region("us-west-2", valid_regions)

    def test_invalid_region(self):
        """Test that invalid region raises error."""
        valid_regions = ["us-east-1", "us-west-2"]

        with pytest.raises(ValidationError) as exc_info:
            validate_region("invalid-region", valid_regions)

        assert "Invalid region" in str(exc_info.value)
        assert "invalid-region" in str(exc_info.value)


class TestValidateName:
    """Test name validation."""

    def test_valid_name(self):
        """Test that valid name passes."""
        # Should not raise
        validate_name("my-resource")
        validate_name("resource123")
        validate_name("a" * 255)  # Max length

    def test_empty_name(self):
        """Test that empty name fails."""
        with pytest.raises(ValidationError) as exc_info:
            validate_name("")

        assert "at least" in str(exc_info.value)

    def test_name_too_short(self):
        """Test that name below minimum length fails."""
        with pytest.raises(ValidationError) as exc_info:
            validate_name("ab", min_length=3)

        assert "at least 3 characters" in str(exc_info.value)

    def test_name_too_long(self):
        """Test that name exceeding maximum length fails."""
        with pytest.raises(ValidationError) as exc_info:
            validate_name("a" * 256, max_length=255)

        assert "at most 255 characters" in str(exc_info.value)

    def test_name_pattern_match(self):
        """Test that name matching pattern passes."""
        pattern = r"^[a-z0-9-]+$"

        # Should not raise
        validate_name("my-resource-123", pattern=pattern)

    def test_name_pattern_no_match(self):
        """Test that name not matching pattern fails."""
        pattern = r"^[a-z0-9-]+$"

        with pytest.raises(ValidationError) as exc_info:
            validate_name("MyResource_123", pattern=pattern)

        assert "does not match required pattern" in str(exc_info.value)
