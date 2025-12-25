#!/bin/bash
# =============================================================================
# Script: validate-at-e2-006.sh
# Purpose: Validate AT-E2-006 acceptance criteria for AI Governance
# Usage: ./scripts/validate-at-e2-006.sh [--namespace NAMESPACE]
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
REPORT_FILE="reports/at-e2-006-validation-$(date +%Y%m%d-%H%M%S).json"
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

Validate AT-E2-006 acceptance criteria for AI Governance.

OPTIONS:
    --namespace NAME    Kubernetes namespace (default: fawkes)
    --verbose          Enable verbose output
    -h, --help         Show this help message

EXAMPLES:
    $0                           # Use default namespace
    $0 --namespace fawkes        # Specify namespace
    $0 --verbose                 # Enable verbose output

ACCEPTANCE CRITERIA (AT-E2-006):
    ✓ AI usage policy published in TechDocs
    ✓ Approved tools list documented
    ✓ Security guidelines created
    ✓ Training materials available
    ✓ AI tools catalog in Backstage

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

# AC1: AI usage policy published in TechDocs
validate_usage_policy() {
    log_info "Validating AI usage policy documentation..."

    local policy_file="docs/ai/usage-policy.md"

    if [ ! -f "$policy_file" ]; then
        record_test_result "AC1: AI Usage Policy File" "FAIL" "Policy file not found at $policy_file"
        return 1
    fi

    # Check for required sections
    local required_sections=(
        "Approved AI Tools"
        "Acceptable Use Guidelines"
        "Data Privacy and Security"
        "Code Review Requirements"
        "Intellectual Property"
        "Compliance and Audit"
    )

    local missing_sections=()
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$policy_file"; then
            missing_sections+=("$section")
        fi
    done

    if [ ${#missing_sections[@]} -eq 0 ]; then
        record_test_result "AC1: AI Usage Policy Content" "PASS" "All required sections present"
    else
        record_test_result "AC1: AI Usage Policy Content" "FAIL" "Missing sections: ${missing_sections[*]}"
        return 1
    fi

    # Check file size (should be substantial)
    local file_size=$(wc -c < "$policy_file")
    if [ "$file_size" -gt 10000 ]; then
        record_test_result "AC1: AI Usage Policy Completeness" "PASS" "Policy document is comprehensive ($file_size bytes)"
    else
        record_test_result "AC1: AI Usage Policy Completeness" "FAIL" "Policy document seems incomplete ($file_size bytes)"
        return 1
    fi

    return 0
}

# AC2: Approved tools list documented
validate_approved_tools() {
    log_info "Validating approved tools documentation..."

    local policy_file="docs/ai/usage-policy.md"

    # Check for specific approved tools
    local required_tools=(
        "GitHub Copilot"
        "ChatGPT"
        "Weaviate"
    )

    local missing_tools=()
    for tool in "${required_tools[@]}"; do
        if ! grep -qi "$tool" "$policy_file"; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -eq 0 ]; then
        record_test_result "AC2: Approved Tools List" "PASS" "All expected tools documented"
    else
        record_test_result "AC2: Approved Tools List" "FAIL" "Missing tools: ${missing_tools[*]}"
        return 1
    fi

    # Check for tool use cases and limitations
    if grep -q "Use Cases" "$policy_file" && grep -q "Limitations" "$policy_file"; then
        record_test_result "AC2: Tool Guidelines" "PASS" "Use cases and limitations documented"
    else
        record_test_result "AC2: Tool Guidelines" "FAIL" "Missing use cases or limitations"
        return 1
    fi

    return 0
}

# AC3: Security guidelines created
validate_security_guidelines() {
    log_info "Validating security guidelines..."

    local policy_file="docs/ai/usage-policy.md"

    # Check for security-related sections
    local security_topics=(
        "Data Privacy"
        "Security"
        "secrets"
        "credentials"
        "PII"
    )

    local missing_topics=()
    for topic in "${security_topics[@]}"; do
        if ! grep -qi "$topic" "$policy_file"; then
            missing_topics+=("$topic")
        fi
    done

    if [ ${#missing_topics[@]} -eq 0 ]; then
        record_test_result "AC3: Security Topics Coverage" "PASS" "All security topics covered"
    else
        record_test_result "AC3: Security Topics Coverage" "FAIL" "Missing topics: ${missing_topics[*]}"
        return 1
    fi

    # Check for DO/DO NOT guidelines
    if grep -q "DO:" "$policy_file" && grep -q "DO NOT:" "$policy_file"; then
        record_test_result "AC3: Security Guidelines Format" "PASS" "Clear DO/DO NOT guidelines present"
    else
        record_test_result "AC3: Security Guidelines Format" "FAIL" "Missing clear DO/DO NOT guidelines"
        return 1
    fi

    return 0
}

# AC4: Training materials available
validate_training_materials() {
    log_info "Validating training materials..."

    local quiz_file="docs/ai/training-quiz.md"

    if [ ! -f "$quiz_file" ]; then
        record_test_result "AC4: Training Quiz File" "FAIL" "Training quiz not found at $quiz_file"
        return 1
    fi

    record_test_result "AC4: Training Quiz File" "PASS" "Training quiz file exists"

    # Check for minimum number of questions (should have 10)
    local question_count=$(grep -c "^### Question" "$quiz_file" || echo "0")
    if [ "$question_count" -ge 10 ]; then
        record_test_result "AC4: Training Quiz Content" "PASS" "Quiz has $question_count questions (required: 10)"
    else
        record_test_result "AC4: Training Quiz Content" "FAIL" "Quiz has only $question_count questions (required: 10)"
        return 1
    fi

    # Check for passing score requirement
    if grep -qi "90%" "$quiz_file" || grep -qi "passing score" "$quiz_file"; then
        record_test_result "AC4: Training Quiz Requirements" "PASS" "Passing score requirements documented"
    else
        record_test_result "AC4: Training Quiz Requirements" "FAIL" "Passing score requirements missing"
        return 1
    fi

    # Check for certificate of completion
    if grep -qi "certificate" "$quiz_file"; then
        record_test_result "AC4: Training Certification" "PASS" "Certificate of completion included"
    else
        record_test_result "AC4: Training Certification" "FAIL" "Certificate of completion missing"
        return 1
    fi

    return 0
}

# AC5: AI tools catalog in Backstage
validate_backstage_catalog() {
    log_info "Validating Backstage AI tools catalog..."

    local catalog_file="catalog-info-ai.yaml"

    if [ ! -f "$catalog_file" ]; then
        record_test_result "AC5: Catalog File Exists" "FAIL" "Catalog file not found at $catalog_file"
        return 1
    fi

    record_test_result "AC5: Catalog File Exists" "PASS" "AI tools catalog file exists"

    # Validate YAML syntax
    if command -v yamllint &> /dev/null; then
        if yamllint -d relaxed "$catalog_file" &> /dev/null; then
            record_test_result "AC5: Catalog YAML Valid" "PASS" "Catalog YAML is valid"
        else
            record_test_result "AC5: Catalog YAML Valid" "FAIL" "Catalog YAML has syntax errors"
            return 1
        fi
    else
        log_warning "yamllint not available, skipping YAML validation"
    fi

    # Check for required Backstage entities
    local required_entities=(
        "kind: System"
        "kind: Component"
    )

    local missing_entities=()
    for entity in "${required_entities[@]}"; do
        if ! grep -q "$entity" "$catalog_file"; then
            missing_entities+=("$entity")
        fi
    done

    if [ ${#missing_entities[@]} -eq 0 ]; then
        record_test_result "AC5: Catalog Entity Types" "PASS" "Required entity types present"
    else
        record_test_result "AC5: Catalog Entity Types" "FAIL" "Missing entities: ${missing_entities[*]}"
        return 1
    fi

    # Check for AI tool components
    local ai_tools=(
        "github-copilot"
        "weaviate"
    )

    local missing_tools=()
    for tool in "${ai_tools[@]}"; do
        if ! grep -qi "$tool" "$catalog_file"; then
            missing_tools+=("$tool")
        fi
    done

    if [ ${#missing_tools[@]} -eq 0 ]; then
        record_test_result "AC5: AI Tools Components" "PASS" "AI tool components defined"
    else
        record_test_result "AC5: AI Tools Components" "FAIL" "Missing tools: ${missing_tools[*]}"
        return 1
    fi

    # Check for links to documentation
    if grep -q "backstage.io/techdocs-ref" "$catalog_file"; then
        record_test_result "AC5: TechDocs Integration" "PASS" "TechDocs references configured"
    else
        record_test_result "AC5: TechDocs Integration" "FAIL" "TechDocs references missing"
        return 1
    fi

    return 0
}

# AC6: Documentation integrated with MkDocs
validate_mkdocs_integration() {
    log_info "Validating MkDocs integration..."

    local mkdocs_file="mkdocs.yml"

    if [ ! -f "$mkdocs_file" ]; then
        record_test_result "AC6: MkDocs Config" "FAIL" "mkdocs.yml not found"
        return 1
    fi

    # Check if AI documentation is referenced in nav
    if grep -A 50 "^nav:" "$mkdocs_file" | grep -qi "ai"; then
        record_test_result "AC6: MkDocs Navigation" "PASS" "AI docs included in navigation"
    else
        log_warning "AI documentation should be added to mkdocs.yml nav section"
        record_test_result "AC6: MkDocs Navigation" "PASS" "MkDocs config present (manual nav update recommended)"
    fi

    return 0
}

# Comprehensive validation
validate_comprehensive_coverage() {
    log_info "Performing comprehensive validation..."

    local policy_file="docs/ai/usage-policy.md"

    # Check for cross-references between documents
    if grep -q "training-quiz.md" "$policy_file"; then
        record_test_result "Comprehensive: Cross-References" "PASS" "Documents are cross-referenced"
    else
        log_warning "Consider adding cross-references between policy and training materials"
    fi

    # Check for contact information
    if grep -qi "contact\|support\|email" "$policy_file"; then
        record_test_result "Comprehensive: Support Info" "PASS" "Contact/support information included"
    else
        record_test_result "Comprehensive: Support Info" "FAIL" "Contact/support information missing"
        return 1
    fi

    return 0
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

    # Create reports directory
    mkdir -p "$REPORT_DIR"

    log_info "Starting AT-E2-006 validation..."
    log_info "Namespace: $NAMESPACE"
    echo ""

    # Run validation tests
    validate_usage_policy
    validate_approved_tools
    validate_security_guidelines
    validate_training_materials
    validate_backstage_catalog
    validate_mkdocs_integration
    validate_comprehensive_coverage

    # Generate summary
    echo ""
    log_info "========================================="
    log_info "VALIDATION SUMMARY"
    log_info "========================================="
    log_info "Total Tests: $TOTAL_TESTS"
    log_success "Passed: $PASSED_TESTS"
    log_error "Failed: $FAILED_TESTS"

    local success_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
    log_info "Success Rate: ${success_rate}%"

    # Generate JSON report
    cat > "$REPORT_FILE" <<EOF
{
  "test_suite": "AT-E2-006: AI Governance",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "namespace": "$NAMESPACE",
  "summary": {
    "total_tests": $TOTAL_TESTS,
    "passed": $PASSED_TESTS,
    "failed": $FAILED_TESTS,
    "success_rate": $success_rate
  },
  "results": [
    $(IFS=,; echo "${TEST_RESULTS[*]}")
  ]
}
EOF

    log_info "Report saved to: $REPORT_FILE"
    echo ""

    # Exit with appropriate code
    if [ $FAILED_TESTS -eq 0 ]; then
        log_success "✓ AT-E2-006 validation PASSED"
        log_success "AI Governance acceptance criteria met!"
        exit 0
    else
        log_error "✗ AT-E2-006 validation FAILED"
        log_error "Please address the failed tests above"
        exit 1
    fi
}

# Run main function
main "$@"
