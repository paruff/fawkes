"""Common exceptions for cloud provider operations."""


class CloudProviderError(Exception):
    """Base exception for cloud provider errors."""

    def __init__(self, message: str, provider: str = None, error_code: str = None):
        super().__init__(message)
        self.provider = provider
        self.error_code = error_code


class AuthenticationError(CloudProviderError):
    """Raised when authentication fails."""


class ResourceNotFoundError(CloudProviderError):
    """Raised when a requested resource is not found."""


class ResourceAlreadyExistsError(CloudProviderError):
    """Raised when attempting to create a resource that already exists."""


class QuotaExceededError(CloudProviderError):
    """Raised when a quota or limit is exceeded."""


class RateLimitError(CloudProviderError):
    """Raised when API rate limit is exceeded."""


class ValidationError(CloudProviderError):
    """Raised when input validation fails."""


class OperationTimeoutError(CloudProviderError):
    """Raised when an operation times out."""
