"""Test module wiring Argo CD bootstrap feature scenarios.

Pytest-BDD requires a Python test module to register the .feature file
scenarios for execution. This module imports all scenarios from the
feature describing the expected GitOps bootstrap state.
"""
from pytest_bdd import scenarios
try:
	from .step_definitions import argocd_steps  # noqa: F401  Ensure step definitions are registered
except Exception:  # pragma: no cover
	from tests.bdd.step_definitions import argocd_steps  # noqa: F401

# Provide the feature filename only; pytest-bdd will resolve it relative to the
# default feature base directory to avoid duplicating 'features/features'.
scenarios("argocd_bootstrap.feature")
