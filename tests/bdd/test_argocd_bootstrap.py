"""Test module wiring Argo CD bootstrap feature scenarios.

Pytest-BDD requires a Python test module to register the .feature file
scenarios for execution. This module imports all scenarios from the
feature describing the expected GitOps bootstrap state.
"""

from pytest_bdd import scenarios

try:
    from .step_definitions import argocd_steps
except Exception:  # pragma: no cover
    from tests.bdd.step_definitions import argocd_steps

# bdd_features_base_dir in pytest.ini is already "features/" (resolved
# relative to tests/bdd/), and this module lives directly in tests/bdd/ —
# so the path here must NOT repeat "features/", or it resolves to the
# nonexistent tests/bdd/features/features/argocd_bootstrap.feature.
scenarios("argocd_bootstrap.feature")
