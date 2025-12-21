#!/bin/bash
# =============================================================================
# Script: validate-at-e2-001.sh
# Purpose: Validate AT-E2-001 acceptance criteria for AI Coding Assistant
# Usage: ./scripts/validate-at-e2-001.sh [--namespace NAMESPACE]
# Exit Codes: 0=success, 1=validation failed
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
NAMESPACE="${NAMESPACE:-fawkes}"
VERBOSE=false
REPORT_FILE="reports/at-e2-001-validation-$(date +%Y%m%d-%H%M%S).json"
REPORT_DIR="reports"

# Test results
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
declare -a TEST_RESULTS=()

# =============================================================================
# Helper Functions
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Validate AT-E2-001 acceptance criteria for AI Coding Assistant.

OPTIONS:
    --namespace NAME    Kubernetes namespace (default: fawkes)
    --verbose          Enable verbose output
    -h, --help         Show this help message

EXAMPLES:
    $0                           # Use default namespace
    $0 --namespace fawkes        # Specify namespace
    $0 --verbose                 # Enable verbose output

ACCEPTANCE CRITERIA (AT-E2-001):
    ✓ GitHub Copilot configured for org
    ✓ IDE extensions documented
    ✓ Integration with RAG system (documented)
    ✓ Test code generation working
    ✓ Usage telemetry configured (opt-in)
    ✓ Documentation complete and accessible

EOF
}

record_test_result() {
    local test_name=$1
    local status=$2
    local message=$3
    local details=${4:-""}
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if [ "$status" = "PASS" ]; then
        PASSED_TESTS=$((PASSED_TESTS + 1))
        log_success "$test_name: $message"
    else
        FAILED_TESTS=$((FAILED_TESTS + 1))
        log_error "$test_name: $message"
    fi
    
    TEST_RESULTS+=("{\"test\":\"$test_name\",\"status\":\"$status\",\"message\":\"$message\",\"details\":\"$details\"}")
}

# =============================================================================
# Validation Tests
# =============================================================================

# AC1: GitHub Copilot configured for org (documented)
validate_copilot_documentation() {
    log_info "Validating GitHub Copilot documentation..."
    
    local doc_file="docs/ai/copilot-setup.md"
    
    if [ ! -f "$doc_file" ]; then
        record_test_result "AC1_COPILOT_DOC_EXISTS" "FAIL" "Copilot setup documentation not found"
        return 1
    fi
    
    record_test_result "AC1_COPILOT_DOC_EXISTS" "PASS" "Copilot setup documentation exists"
    
    # Check for required sections
    local required_sections=(
        "Organization Setup"
        "IDE Setup"
        "VSCode Setup"
        "IntelliJ IDEA Setup"
        "Vim/Neovim Setup"
        "Best Practices"
        "Troubleshooting"
    )
    
    local missing_sections=0
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$doc_file"; then
            log_warning "Missing section: $section"
            missing_sections=$((missing_sections + 1))
        fi
    done
    
    if [ $missing_sections -eq 0 ]; then
        record_test_result "AC1_COPILOT_DOC_COMPLETE" "PASS" "All required sections present"
    else
        record_test_result "AC1_COPILOT_DOC_COMPLETE" "FAIL" "Missing $missing_sections sections"
        return 1
    fi
    
    # Check documentation size (should be comprehensive)
    local doc_lines=$(wc -l < "$doc_file")
    if [ $doc_lines -gt 200 ]; then
        record_test_result "AC1_COPILOT_DOC_COMPREHENSIVE" "PASS" "Documentation is comprehensive ($doc_lines lines)"
    else
        record_test_result "AC1_COPILOT_DOC_COMPREHENSIVE" "FAIL" "Documentation seems incomplete ($doc_lines lines)"
        return 1
    fi
    
    return 0
}

# AC2: IDE extensions documented
validate_ide_extensions_documented() {
    log_info "Validating IDE extensions documentation..."
    
    local doc_file="docs/ai/copilot-setup.md"
    
    if [ ! -f "$doc_file" ]; then
        record_test_result "AC2_IDE_DOC" "FAIL" "Documentation file not found"
        return 1
    fi
    
    # Check for VSCode extension documentation
    if grep -q "VSCode" "$doc_file" && grep -q "Extensions" "$doc_file"; then
        record_test_result "AC2_VSCODE_EXTENSIONS" "PASS" "VSCode extensions documented"
    else
        record_test_result "AC2_VSCODE_EXTENSIONS" "FAIL" "VSCode extensions not documented"
        return 1
    fi
    
    # Check for IntelliJ extension documentation
    if grep -q "IntelliJ" "$doc_file" && grep -q "Plugin" "$doc_file"; then
        record_test_result "AC2_INTELLIJ_EXTENSIONS" "PASS" "IntelliJ extensions documented"
    else
        record_test_result "AC2_INTELLIJ_EXTENSIONS" "FAIL" "IntelliJ extensions not documented"
        return 1
    fi
    
    # Check for Vim/Neovim extension documentation
    if grep -q "Vim\|Neovim" "$doc_file"; then
        record_test_result "AC2_VIM_EXTENSIONS" "PASS" "Vim/Neovim extensions documented"
    else
        record_test_result "AC2_VIM_EXTENSIONS" "FAIL" "Vim/Neovim extensions not documented"
        return 1
    fi
    
    # Check for keyboard shortcuts documentation
    if grep -q "Keyboard Shortcuts\|keyboard shortcuts" "$doc_file"; then
        record_test_result "AC2_KEYBOARD_SHORTCUTS" "PASS" "Keyboard shortcuts documented"
    else
        record_test_result "AC2_KEYBOARD_SHORTCUTS" "FAIL" "Keyboard shortcuts not documented"
        return 1
    fi
    
    return 0
}

# AC3: Integration with RAG system documented
validate_rag_integration_documented() {
    log_info "Validating RAG system integration documentation..."
    
    local doc_file="docs/ai/copilot-setup.md"
    
    if [ ! -f "$doc_file" ]; then
        record_test_result "AC3_RAG_INTEGRATION" "FAIL" "Documentation file not found"
        return 1
    fi
    
    # Check for RAG integration documentation
    if grep -q "RAG\|Retrieval Augmented Generation" "$doc_file"; then
        record_test_result "AC3_RAG_MENTIONED" "PASS" "RAG integration mentioned in documentation"
    else
        record_test_result "AC3_RAG_MENTIONED" "FAIL" "RAG integration not mentioned"
        return 1
    fi
    
    # Check for Weaviate reference
    if grep -q "Weaviate\|vector database" "$doc_file"; then
        record_test_result "AC3_WEAVIATE_REFERENCE" "PASS" "Weaviate/vector database referenced"
    else
        record_test_result "AC3_WEAVIATE_REFERENCE" "FAIL" "Weaviate not referenced"
        return 1
    fi
    
    # Check for context-based approaches
    if grep -q "context\|Context" "$doc_file"; then
        record_test_result "AC3_CONTEXT_APPROACHES" "PASS" "Context-based approaches documented"
    else
        record_test_result "AC3_CONTEXT_APPROACHES" "FAIL" "Context approaches not documented"
        return 1
    fi
    
    # Check for integration limitations
    if grep -q "Limitations\|limitations" "$doc_file"; then
        record_test_result "AC3_LIMITATIONS" "PASS" "Integration limitations documented"
    else
        record_test_result "AC3_LIMITATIONS" "FAIL" "Limitations not documented"
        return 1
    fi
    
    return 0
}

# AC4: Test code generation working
validate_code_generation_tests() {
    log_info "Validating code generation tests..."
    
    local test_script="tests/ai/code-generation-test.sh"
    
    if [ ! -f "$test_script" ]; then
        record_test_result "AC4_TEST_SCRIPT_EXISTS" "FAIL" "Code generation test script not found"
        return 1
    fi
    
    record_test_result "AC4_TEST_SCRIPT_EXISTS" "PASS" "Code generation test script exists"
    
    # Check if script is executable
    if [ -x "$test_script" ]; then
        record_test_result "AC4_TEST_SCRIPT_EXECUTABLE" "PASS" "Test script is executable"
    else
        record_test_result "AC4_TEST_SCRIPT_EXECUTABLE" "FAIL" "Test script is not executable"
        return 1
    fi
    
    # Check for test functions
    if grep -q "test_generate_rest_api\|test_generate_terraform\|test_generate_test_cases" "$test_script"; then
        record_test_result "AC4_TEST_FUNCTIONS" "PASS" "Required test functions present"
    else
        record_test_result "AC4_TEST_FUNCTIONS" "FAIL" "Missing required test functions"
        return 1
    fi
    
    # Run the code generation tests
    log_info "Running code generation tests..."
    if bash "$test_script" > /tmp/code-gen-test-output.log 2>&1; then
        record_test_result "AC4_CODE_GENERATION_TESTS" "PASS" "Code generation tests passed"
    else
        local exit_code=$?
        log_warning "Code generation tests failed with exit code $exit_code"
        record_test_result "AC4_CODE_GENERATION_TESTS" "FAIL" "Code generation tests failed (see logs)"
        
        # Show last few lines of output for debugging
        if [ "$VERBOSE" = true ]; then
            tail -20 /tmp/code-gen-test-output.log
        fi
        
        return 1
    fi
    
    return 0
}

# AC5: Usage telemetry configured (opt-in)
validate_telemetry_configuration() {
    log_info "Validating usage telemetry configuration..."
    
    # Check for telemetry documentation
    local telemetry_doc="platform/apps/ai-telemetry/README.md"
    if [ ! -f "$telemetry_doc" ]; then
        record_test_result "AC5_TELEMETRY_DOC_EXISTS" "FAIL" "Telemetry documentation not found"
        return 1
    fi
    
    record_test_result "AC5_TELEMETRY_DOC_EXISTS" "PASS" "Telemetry documentation exists"
    
    # Check for opt-in mechanism documented
    if grep -q "opt-in\|Opt-in\|OPT-IN" "$telemetry_doc"; then
        record_test_result "AC5_OPT_IN_DOCUMENTED" "PASS" "Opt-in mechanism documented"
    else
        record_test_result "AC5_OPT_IN_DOCUMENTED" "FAIL" "Opt-in not documented"
        return 1
    fi
    
    # Check for privacy considerations
    if grep -q "Privacy\|privacy\|GDPR\|anonymized" "$telemetry_doc"; then
        record_test_result "AC5_PRIVACY_DOCUMENTED" "PASS" "Privacy considerations documented"
    else
        record_test_result "AC5_PRIVACY_DOCUMENTED" "FAIL" "Privacy not documented"
        return 1
    fi
    
    # Check for Grafana dashboard
    local dashboard_file="platform/apps/ai-telemetry/dashboards/ai-telemetry-dashboard.json"
    if [ ! -f "$dashboard_file" ]; then
        record_test_result "AC5_DASHBOARD_EXISTS" "FAIL" "Grafana dashboard not found"
        return 1
    fi
    
    record_test_result "AC5_DASHBOARD_EXISTS" "PASS" "Grafana dashboard exists"
    
    # Validate dashboard JSON
    if python3 -c "import json; json.load(open('$dashboard_file'))" 2>/dev/null; then
        record_test_result "AC5_DASHBOARD_VALID_JSON" "PASS" "Dashboard JSON is valid"
    else
        record_test_result "AC5_DASHBOARD_VALID_JSON" "FAIL" "Dashboard JSON is invalid"
        return 1
    fi
    
    # Check for metrics documentation
    if grep -q "acceptance rate\|lines generated\|time saved" "$telemetry_doc"; then
        record_test_result "AC5_METRICS_DOCUMENTED" "PASS" "Key metrics documented"
    else
        record_test_result "AC5_METRICS_DOCUMENTED" "FAIL" "Metrics not documented"
        return 1
    fi
    
    return 0
}

# AC6: Documentation complete and accessible
validate_documentation_completeness() {
    log_info "Validating documentation completeness..."
    
    # Check all required documentation files exist
    local required_docs=(
        "docs/ai/copilot-setup.md"
        "platform/apps/ai-telemetry/README.md"
        "platform/apps/ai-telemetry/dashboards/ai-telemetry-dashboard.json"
        "tests/ai/code-generation-test.sh"
    )
    
    local missing_docs=0
    for doc in "${required_docs[@]}"; do
        if [ ! -f "$doc" ]; then
            log_warning "Missing documentation: $doc"
            missing_docs=$((missing_docs + 1))
        fi
    done
    
    if [ $missing_docs -eq 0 ]; then
        record_test_result "AC6_ALL_DOCS_PRESENT" "PASS" "All required documentation present"
    else
        record_test_result "AC6_ALL_DOCS_PRESENT" "FAIL" "Missing $missing_docs documentation files"
        return 1
    fi
    
    # Check for cross-references
    if grep -q "vector-database.md\|RAG.*README\|telemetry.*README" "docs/ai/copilot-setup.md"; then
        record_test_result "AC6_CROSS_REFERENCES" "PASS" "Documentation includes cross-references"
    else
        record_test_result "AC6_CROSS_REFERENCES" "FAIL" "Missing cross-references"
        return 1
    fi
    
    # Check for examples and usage instructions
    if grep -q "Example\|example\|EXAMPLE" "docs/ai/copilot-setup.md"; then
        record_test_result "AC6_EXAMPLES_PRESENT" "PASS" "Documentation includes examples"
    else
        record_test_result "AC6_EXAMPLES_PRESENT" "FAIL" "Missing examples"
        return 1
    fi
    
    return 0
}

# =============================================================================
# Generate Report
# =============================================================================

generate_report() {
    log_info "Generating validation report..."
    
    mkdir -p "$REPORT_DIR"
    
    local report_json="["
    for result in "${TEST_RESULTS[@]}"; do
        report_json="$report_json$result,"
    done
    report_json="${report_json%,}]"  # Remove trailing comma
    
    # Create full report
    cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "test_suite": "AT-E2-001: AI Coding Assistant Validation",
  "acceptance_test": "AT-E2-001",
  "description": "Validate GitHub Copilot configuration and AI coding assistant setup",
  "namespace": "$NAMESPACE",
  "summary": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "success_rate": $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc 2>/dev/null || echo "0")
  },
  "acceptance_criteria": {
    "copilot_configured": "$([ $PASSED_TESTS -gt 0 ] && echo "true" || echo "false")",
    "ide_extensions_documented": "$([ $PASSED_TESTS -gt 2 ] && echo "true" || echo "false")",
    "rag_integration": "$([ $PASSED_TESTS -gt 5 ] && echo "true" || echo "false")",
    "test_generation": "$([ $PASSED_TESTS -gt 8 ] && echo "true" || echo "false")",
    "telemetry_configured": "$([ $PASSED_TESTS -gt 11 ] && echo "true" || echo "false")"
  },
  "results": $report_json
}
EOF
    
    log_success "Report saved to $REPORT_FILE"
    
    # Print summary
    echo ""
    echo "========================================="
    echo "AT-E2-001 Validation Summary"
    echo "========================================="
    echo "Test Suite:   AI Coding Assistant"
    echo "Namespace:    $NAMESPACE"
    echo "Total Tests:  $TOTAL_TESTS"
    echo "Passed:       $PASSED_TESTS"
    echo "Failed:       $FAILED_TESTS"
    if [ $TOTAL_TESTS -gt 0 ]; then
        echo "Success Rate: $(echo "scale=2; $PASSED_TESTS * 100 / $TOTAL_TESTS" | bc)%"
    fi
    echo "========================================="
    echo ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        echo -e "${GREEN}✓ AT-E2-001 PASSED${NC}"
        echo "All acceptance criteria met!"
    else
        echo -e "${RED}✗ AT-E2-001 FAILED${NC}"
        echo "Some acceptance criteria not met. Review the report."
    fi
    echo ""
}

# =============================================================================
# Main Execution
# =============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --namespace)
                NAMESPACE="$2"
                shift 2
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    log_info "Starting AT-E2-001 validation: AI Coding Assistant..."
    log_info "Namespace: $NAMESPACE"
    echo ""
    
    # Run validation tests
    validate_copilot_documentation || true
    validate_ide_extensions_documented || true
    validate_rag_integration_documented || true
    validate_code_generation_tests || true
    validate_telemetry_configuration || true
    validate_documentation_completeness || true
    
    # Generate report
    generate_report
    
    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "AT-E2-001 validation passed! ✨"
        exit 0
    else
        log_error "AT-E2-001 validation failed. Review the report at $REPORT_FILE"
        exit 1
    fi
}

# Run main function
main "$@"
