"""
Example of integrating OpenFeature with Unleash in Python services.
"""

import os
from openfeature import api
from openfeature.contrib.provider.unleash import UnleashProvider
from openfeature.evaluation_context import EvaluationContext


def initialize_feature_flags():
    """Initialize OpenFeature with Unleash provider."""
    api.set_provider(
        UnleashProvider(
            url=os.getenv("UNLEASH_API_URL", "https://unleash.fawkes.idp/api"),
            app_name="python-service",
            api_token=os.getenv("UNLEASH_API_TOKEN"),
            refresh_interval=30,
        )
    )


def check_feature_enabled(feature_name: str, user_id: str = None) -> bool:
    """Check if a feature flag is enabled."""
    client = api.get_client()

    context = EvaluationContext(
        targeting_key=user_id or "anonymous",
        attributes={
            "environment": os.getenv("ENVIRONMENT", "production"),
            "team": "data-platform",
        },
    )

    return client.get_boolean_value(flag_key=feature_name, default_value=False, evaluation_context=context)
