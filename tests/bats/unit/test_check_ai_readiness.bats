#!/usr/bin/env bats
# =============================================================================
# BATS tests for scripts/check-ai-readiness.sh
# =============================================================================

setup() {
  load ../helpers/test_helper
  setup_test_env

  SCRIPT="${PROJECT_ROOT}/scripts/check-ai-readiness.sh"

  # Create a minimal fixture with two Python services
  FIXTURE_DIR="${TEST_TEMP_DIR}/fixture"
  mkdir -p "${FIXTURE_DIR}/services/typed-service/app"
  mkdir -p "${FIXTURE_DIR}/services/untyped-service/app"
  mkdir -p "${FIXTURE_DIR}/tests/unit"
  mkdir -p "${FIXTURE_DIR}/tests/bdd/features"
  mkdir -p "${FIXTURE_DIR}/docs"

  # typed-service: 2 public functions, both typed and with docstrings
  cat > "${FIXTURE_DIR}/services/typed-service/app/main.py" << 'PYEOF'
def public_typed(x: int) -> str:
    """Has a docstring."""
    return str(x)


def public_also_typed(value: str) -> bool:
    """Also has a docstring."""
    return bool(value)


def _private(x: int) -> str:
    return str(x)
PYEOF

  # untyped-service: 2 public functions, neither typed nor with docstrings
  cat > "${FIXTURE_DIR}/services/untyped-service/app/main.py" << 'PYEOF'
def public_no_hints(x):
    return str(x)


def public_no_doc(y):
    return y
PYEOF

  # Unit test exists for typed-service only
  touch "${FIXTURE_DIR}/tests/unit/test_typed-service_example.py"

  # BDD feature exists for untyped-service only
  touch "${FIXTURE_DIR}/tests/bdd/features/untyped-service.feature"

  # Minimal docs/METRICS.md for update tests
  printf '# Metrics\n\n## Rework Rate\n\nTBD\n' > "${FIXTURE_DIR}/docs/METRICS.md"
}

teardown() {
  teardown_test_env
}

# =============================================================================
# Basic invocation
# =============================================================================

@test "check-ai-readiness: script exists" {
  [ -f "${SCRIPT}" ]
}

@test "check-ai-readiness: script is executable" {
  [ -x "${SCRIPT}" ]
}

@test "check-ai-readiness: --help exits 0" {
  run bash "${SCRIPT}" --help
  assert_success
}

@test "check-ai-readiness: --help prints script name" {
  run bash "${SCRIPT}" --help
  assert_output --partial "check-ai-readiness.sh"
}

@test "check-ai-readiness: --help prints usage section" {
  run bash "${SCRIPT}" --help
  assert_output --partial "USAGE:"
}

@test "check-ai-readiness: unknown option exits non-zero" {
  run bash "${SCRIPT}" --invalid-flag
  assert_failure
}

@test "check-ai-readiness: unknown option prints error message" {
  run bash "${SCRIPT}" --invalid-flag
  assert_output --partial "Unknown option"
}

# =============================================================================
# Dry-run on the actual repository
# =============================================================================

@test "check-ai-readiness: --dry-run completes without error on real services/" {
  # Exit code 0 or 1 are both valid (1 = services below threshold)
  run bash "${SCRIPT}" --dry-run
  [ "${status}" -eq 0 ] || [ "${status}" -eq 1 ]
}

@test "check-ai-readiness: --dry-run output contains Service header" {
  run bash "${SCRIPT}" --dry-run
  assert_output --partial "Service"
}

@test "check-ai-readiness: --dry-run output contains known service name" {
  run bash "${SCRIPT}" --dry-run
  assert_output --partial "ai-code-review"
}

@test "check-ai-readiness: --dry-run does not modify METRICS.md" {
  METRICS="${PROJECT_ROOT}/docs/METRICS.md"
  before_size="$(wc -c < "${METRICS}")"

  # Run twice with --dry-run; file size must not change
  bash "${SCRIPT}" --dry-run > /dev/null 2>&1 || true
  after_size="$(wc -c < "${METRICS}")"

  [ "${before_size}" -eq "${after_size}" ]
}

# =============================================================================
# Metrics accuracy on fixture data
# =============================================================================

@test "check-ai-readiness: detects 100% type-hint coverage on typed service" {
  run bash -c "
    SERVICES_DIR='${FIXTURE_DIR}/services' \
    TESTS_UNIT_DIR='${FIXTURE_DIR}/tests/unit' \
    TESTS_BDD_DIR='${FIXTURE_DIR}/tests/bdd/features' \
    METRICS_FILE='${FIXTURE_DIR}/docs/METRICS.md' \
    bash '${SCRIPT}' --dry-run 2>&1
  "
  assert_output --partial "typed-service"
  assert_output --partial "2/2 (100%)"
}

@test "check-ai-readiness: detects 0% type-hint coverage on untyped service" {
  run bash -c "
    SERVICES_DIR='${FIXTURE_DIR}/services' \
    TESTS_UNIT_DIR='${FIXTURE_DIR}/tests/unit' \
    TESTS_BDD_DIR='${FIXTURE_DIR}/tests/bdd/features' \
    METRICS_FILE='${FIXTURE_DIR}/docs/METRICS.md' \
    bash '${SCRIPT}' --dry-run 2>&1
  "
  assert_output --partial "untyped-service"
  assert_output --partial "0/2 (0%)"
}

@test "check-ai-readiness: updates METRICS.md with AI-Readiness section" {
  run bash -c "
    SERVICES_DIR='${FIXTURE_DIR}/services' \
    TESTS_UNIT_DIR='${FIXTURE_DIR}/tests/unit' \
    TESTS_BDD_DIR='${FIXTURE_DIR}/tests/bdd/features' \
    METRICS_FILE='${FIXTURE_DIR}/docs/METRICS.md' \
    bash '${SCRIPT}' 2>&1
  "
  grep -q "## AI-Readiness Metrics" "${FIXTURE_DIR}/docs/METRICS.md"
}

@test "check-ai-readiness: METRICS.md update is idempotent" {
  for _i in 1 2; do
    bash -c "
      SERVICES_DIR='${FIXTURE_DIR}/services' \
      TESTS_UNIT_DIR='${FIXTURE_DIR}/tests/unit' \
      TESTS_BDD_DIR='${FIXTURE_DIR}/tests/bdd/features' \
      METRICS_FILE='${FIXTURE_DIR}/docs/METRICS.md' \
      bash '${SCRIPT}' 2>&1
    " > /dev/null || true
  done
  count="$(grep -c "## AI-Readiness Metrics" "${FIXTURE_DIR}/docs/METRICS.md")"
  [ "${count}" -eq 1 ]
}
