"""Test module wiring Argo CD bootstrap feature scenarios.

Pytest-BDD requires a Python test module to register the .feature file
scenarios for execution. This module imports all scenarios from the
feature describing the expected GitOps bootstrap state.
"""
from pytest_bdd import scenarios
import tests.bdd.step_definitions.argocd_steps  # noqa: F401  Ensure step definitions are registered

# Provide the feature filename only; pytest-bdd will resolve it relative to the
# default feature base directory to avoid duplicating 'features/features'.
scenarios("argocd_bootstrap.feature")
