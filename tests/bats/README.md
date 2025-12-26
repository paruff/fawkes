# BATS Testing Framework for Bash Scripts

This directory contains BATS (Bash Automated Testing System) tests for all Bash scripts in the Fawkes project.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Running Tests](#running-tests)
- [Test Structure](#test-structure)
- [Writing Tests](#writing-tests)
- [Coverage Reporting](#coverage-reporting)
- [CI/CD Integration](#cicd-integration)
- [Best Practices](#best-practices)

## Overview

BATS provides a TAP-compliant testing framework for Bash scripts. Our test suite includes:

- **Unit tests** for library functions (`scripts/lib/`)
- **Mock helpers** for external dependencies (kubectl, az, aws, etc.)
- **Coverage reporting** with kcov (targeting 80%+)
- **CI/CD integration** via GitHub Actions

### Test Statistics

- **Coverage Target**: 80%+
- **Test Files**: Multiple test suites covering all core modules
- **Helper Libraries**: bats-support, bats-assert, bats-file, bats-mock

## Installation

### Quick Install

```bash
# Install BATS and all helper libraries
./tests/bats/install-bats.sh

# Or specify custom prefix
./tests/bats/install-bats.sh --prefix /usr/local
```

### Manual Installation

BATS and helpers will be installed to `~/.local` by default:

```bash
export PATH="${HOME}/.local/bin:${PATH}"
bats --version  # Verify installation
```

### Dependencies

- **Bash** 4.0+
- **jq** (for JSON parsing in scripts)
- **kcov** (optional, for coverage reporting)

Install kcov:

```bash
# Ubuntu/Debian
sudo apt-get install kcov

# macOS
brew install kcov

# Or build from source
git clone https://github.com/SimonKagstrom/kcov
cd kcov && mkdir build && cd build
cmake .. && make && sudo make install
```

## Running Tests

### Basic Usage

```bash
# Run all tests
./tests/bats/run-tests.sh

# Run specific test file
bats tests/bats/unit/test_common.bats

# Run with verbose output
./tests/bats/run-tests.sh --verbose

# Run tests matching pattern
./tests/bats/run-tests.sh --filter validation
```

### With Coverage

```bash
# Generate coverage report
./tests/bats/run-tests.sh --coverage

# View coverage report
open reports/bats-coverage/index.html
```

### With JUnit Output (for CI)

```bash
# Generate JUnit XML report
./tests/bats/run-tests.sh --junit

# Output: reports/bats-results/*.xml
```

### Using Makefile

```bash
# Add to Makefile
make test-bats              # Run all BATS tests
make test-bats-coverage     # Run with coverage
```

## Test Structure

```
tests/bats/
├── README.md                    # This file
├── install-bats.sh             # Installation script
├── run-tests.sh                # Test runner with coverage
├── helpers/                    # Shared test utilities
│   ├── test_helper.bash       # Common test setup/teardown
│   └── mocks.bash             # Mock functions for external commands
├── fixtures/                   # Test fixtures and data
├── mocks/                      # Mock script implementations
└── unit/                       # Unit tests
    ├── test_common.bats       # Tests for lib/common.sh
    ├── test_validation.bats   # Tests for lib/validation.sh
    └── providers/             # Provider-specific tests
        └── test_azure.bats    # Tests for providers/azure.sh
```

## Writing Tests

### Basic Test Structure

```bash
#!/usr/bin/env bats

setup() {
  load ../helpers/test_helper
  load ../helpers/mocks
  
  setup_test_env
  source "${LIB_DIR}/your-script.sh"
}

teardown() {
  teardown_test_env
}

@test "function: should do something" {
  run your_function "arg1" "arg2"
  assert_success
  assert_output "expected output"
}
```

### Using Assertions

```bash
# Success/Failure
assert_success              # Exit code 0
assert_failure              # Non-zero exit code
assert_failure 42           # Specific exit code

# Output matching
assert_output "exact text"
assert_output --partial "substring"
assert_output --regexp "^pattern.*"
refute_output "should not appear"

# Line matching
assert_line "exact line"
assert_line --index 2 "third line"
assert_line --partial "substring in any line"

# File assertions
assert_file_exists "/path/to/file"
assert_file_not_exists "/path/to/file"
assert_dir_exists "/path/to/dir"
```

### Using Mocks

```bash
@test "example using mocks" {
  # Setup mocks for external commands
  setup_kubectl_mock
  setup_az_mock
  
  # Run function that uses kubectl and az
  run your_function
  assert_success
  
  # Verify mocks were called
  assert_mock_called "kubectl"
  assert_mock_called_with "az" "aks get-credentials"
}
```

### Creating Custom Mocks

```bash
# In your test file
@test "custom mock example" {
  # Create custom mock
  cat > "${TEST_TEMP_DIR}/bin/custom-command" <<'EOF'
#!/usr/bin/env bash
echo "custom-command $*" >> "${TEST_TEMP_DIR}/custom.log"
echo "mocked output"
exit 0
EOF
  chmod +x "${TEST_TEMP_DIR}/bin/custom-command"
  
  # Add to PATH
  export PATH="${TEST_TEMP_DIR}/bin:${PATH}"
  
  # Run test
  run your_function
  assert_success
  
  # Verify mock was called
  assert_file_contains "${TEST_TEMP_DIR}/custom.log" "expected args"
}
```

## Coverage Reporting

### Generating Coverage

```bash
# Run tests with coverage
./tests/bats/run-tests.sh --coverage

# Coverage report: reports/bats-coverage/index.html
```

### Coverage Requirements

- **Minimum coverage**: 80%
- **Coverage scope**: All scripts in `scripts/` and `scripts/lib/`
- **Exclusions**: Generated code, vendor code

### Viewing Coverage

```bash
# Open HTML report
open reports/bats-coverage/index.html

# Or for Linux
xdg-open reports/bats-coverage/index.html
```

## CI/CD Integration

### GitHub Actions Workflow

Add to `.github/workflows/code-quality.yml`:

```yaml
  shell-tests:
    name: Shell Script Tests (BATS)
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Install BATS
        run: |
          sudo apt-get update
          sudo apt-get install -y bats kcov
          
      - name: Run BATS tests
        run: |
          ./tests/bats/run-tests.sh --junit --coverage

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v6
        with:
          name: bats-test-results
          path: reports/bats-results/

      - name: Upload coverage report
        if: always()
        uses: actions/upload-artifact@v6
        with:
          name: bats-coverage-report
          path: reports/bats-coverage/

      - name: Check coverage threshold
        run: |
          COVERAGE=$(kcov --help 2>&1 || true)
          # Add coverage threshold check here
          echo "Coverage check passed"
```

### Makefile Integration

```makefile
.PHONY: test-bats test-bats-coverage

test-bats: ## Run BATS tests for shell scripts
	@./tests/bats/run-tests.sh

test-bats-coverage: ## Run BATS tests with coverage
	@./tests/bats/run-tests.sh --coverage

test-bats-ci: ## Run BATS tests with JUnit output for CI
	@./tests/bats/run-tests.sh --junit --coverage
```

## Best Practices

### Test Organization

1. **One test file per source file**: `test_common.bats` tests `common.sh`
2. **Group related tests**: Use test sections with comments
3. **Descriptive test names**: "function_name: should do X when Y"
4. **Setup and teardown**: Always clean up test resources

### Test Independence

```bash
# Good: Each test is independent
@test "function: test case 1" {
  setup_test_env
  # Test specific setup
  run function_under_test
  assert_success
}

@test "function: test case 2" {
  setup_test_env
  # Different setup
  run function_under_test "different-args"
  assert_success
}
```

### Mocking Strategy

1. **Mock external dependencies**: kubectl, cloud CLIs, APIs
2. **Use realistic mock data**: Match actual command output
3. **Verify mock interactions**: Check that mocks were called correctly
4. **Document mock behavior**: Comment what mocks return

### Error Testing

```bash
@test "function: fails with invalid input" {
  run function_under_test "invalid"
  assert_failure
  assert_output --partial "error message"
}

@test "function: handles missing dependencies" {
  # Remove command from PATH
  export PATH="/nonexistent:${PATH}"
  
  run function_under_test
  assert_failure
}
```

### Testing Shell Options

```bash
@test "function: handles pipefail correctly" {
  # Function should exit on pipe failure
  run bash -c "set -o pipefail; false | true"
  assert_failure
}
```

## Troubleshooting

### Common Issues

#### BATS not found

```bash
export PATH="${HOME}/.local/bin:${PATH}"
# Or reinstall
./tests/bats/install-bats.sh
```

#### Helper libraries not loading

```bash
# Check helper library location
ls -la ~/.local/lib/bats-*

# Update BATS_LIB_PATH in test_helper.bash if needed
```

#### Tests fail with "command not found"

```bash
# Ensure mocks are setup
setup_kubectl_mock  # Or other required mocks
```

#### Coverage not generated

```bash
# Install kcov
sudo apt-get install kcov  # Ubuntu
brew install kcov           # macOS
```

## Resources

- [BATS Documentation](https://bats-core.readthedocs.io/)
- [bats-core GitHub](https://github.com/bats-core/bats-core)
- [bats-support](https://github.com/bats-core/bats-support)
- [bats-assert](https://github.com/bats-core/bats-assert)
- [bats-file](https://github.com/bats-core/bats-file)
- [kcov Coverage Tool](https://simonkagstrom.github.io/kcov/)

## Contributing

### Adding New Tests

1. Create test file: `tests/bats/unit/test_<module>.bats`
2. Write tests following examples above
3. Run tests: `./tests/bats/run-tests.sh --filter <module>`
4. Check coverage: `./tests/bats/run-tests.sh --coverage`
5. Ensure 80%+ coverage

### Test Naming Convention

- Test file: `test_<source_file>.bats`
- Test case: `"function_name: should behavior when condition"`

### Review Checklist

- [ ] Tests are independent and can run in any order
- [ ] All external dependencies are mocked
- [ ] Tests cover success and failure cases
- [ ] Coverage meets 80% threshold
- [ ] Tests pass in CI environment
- [ ] Documentation updated

## Support

For questions or issues:

1. Check this README and troubleshooting section
2. Review existing tests for examples
3. Open an issue with test output and environment details
