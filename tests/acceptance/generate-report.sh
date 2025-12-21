#!/bin/bash
# =============================================================================
# Script: generate-report.sh
# Purpose: Generate acceptance test reports
# Usage: ./tests/acceptance/generate-report.sh [OPTIONS]
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the root directory
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORTS_DIR="$ROOT_DIR/reports"

# Default values
EPIC=""
WEEK=""
FORMAT="html"
OUTPUT_FILE=""

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

Generate acceptance test reports from test results.

OPTIONS:
    --epic NUMBER       Generate report for specific epic (1, 2, etc.)
    --week NUMBER       Generate report for specific week
    --format FORMAT     Output format: html, json, markdown (default: html)
    --output FILE       Output file path (default: auto-generated)
    -h, --help         Show this help message

EXAMPLES:
    $0 --epic 2 --week 1
    $0 --epic 1 --format json
    $0 --epic 2 --week 1 --format markdown --output my-report.md

EOF
}

find_test_reports() {
    local pattern="$1"
    
    if [ ! -d "$REPORTS_DIR" ]; then
        log_warning "Reports directory not found: $REPORTS_DIR"
        return 1
    fi
    
    find "$REPORTS_DIR" -name "$pattern" -type f 2>/dev/null | sort -r
}

parse_json_report() {
    local report_file="$1"
    
    if [ ! -f "$report_file" ]; then
        return 1
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        log_warning "jq not available, using basic parsing"
        return 1
    fi
    
    local test_suite=$(jq -r '.test_suite // .acceptance_test // "Unknown"' "$report_file" 2>/dev/null)
    local total=$(jq -r '.summary.total_tests // .summary.total // 0' "$report_file" 2>/dev/null)
    local passed=$(jq -r '.summary.passed // .summary.passed_tests // 0' "$report_file" 2>/dev/null)
    local failed=$(jq -r '.summary.failed // .summary.failed_tests // 0' "$report_file" 2>/dev/null)
    local timestamp=$(jq -r '.timestamp // "Unknown"' "$report_file" 2>/dev/null)
    
    echo "$test_suite|$total|$passed|$failed|$timestamp"
}

generate_html_report() {
    local output_file="$1"
    local report_data="$2"
    
    cat > "$output_file" << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Fawkes Acceptance Test Report</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
        }
        h1 {
            margin: 0;
            font-size: 2.5em;
        }
        .meta {
            opacity: 0.9;
            margin-top: 10px;
        }
        .summary {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .summary-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .summary-card h3 {
            margin: 0 0 10px 0;
            color: #666;
            font-size: 0.9em;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .summary-card .value {
            font-size: 2em;
            font-weight: bold;
            color: #333;
        }
        .passed { color: #10b981; }
        .failed { color: #ef4444; }
        .total { color: #3b82f6; }
        .success-rate { color: #8b5cf6; }
        .test-results {
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e5e7eb;
        }
        th {
            background-color: #f9fafb;
            font-weight: 600;
            color: #374151;
        }
        tr:hover {
            background-color: #f9fafb;
        }
        .status-badge {
            display: inline-block;
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .status-pass {
            background-color: #d1fae5;
            color: #065f46;
        }
        .status-fail {
            background-color: #fee2e2;
            color: #991b1b;
        }
        .footer {
            margin-top: 30px;
            text-align: center;
            color: #666;
            font-size: 0.9em;
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🚀 Fawkes Acceptance Test Report</h1>
        <div class="meta">
            <strong>Epic:</strong> {{EPIC}} | 
            <strong>Generated:</strong> {{TIMESTAMP}}
        </div>
    </div>
    
    <div class="summary">
        <div class="summary-card">
            <h3>Total Tests</h3>
            <div class="value total">{{TOTAL_TESTS}}</div>
        </div>
        <div class="summary-card">
            <h3>Passed</h3>
            <div class="value passed">{{PASSED_TESTS}}</div>
        </div>
        <div class="summary-card">
            <h3>Failed</h3>
            <div class="value failed">{{FAILED_TESTS}}</div>
        </div>
        <div class="summary-card">
            <h3>Success Rate</h3>
            <div class="value success-rate">{{SUCCESS_RATE}}%</div>
        </div>
    </div>
    
    <div class="test-results">
        <h2>Test Results</h2>
        <table>
            <thead>
                <tr>
                    <th>Test Suite</th>
                    <th>Status</th>
                    <th>Total</th>
                    <th>Passed</th>
                    <th>Failed</th>
                    <th>Timestamp</th>
                </tr>
            </thead>
            <tbody>
{{TEST_ROWS}}
            </tbody>
        </table>
    </div>
    
    <div class="footer">
        <p>Generated by Fawkes Acceptance Test Framework</p>
    </div>
</body>
</html>
EOF
    
    # Replace placeholders with actual data
    local epic_name="$EPIC"
    [ -z "$epic_name" ] && epic_name="All"
    
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # Process report data and calculate totals
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    local test_rows=""
    
    while IFS='|' read -r suite total passed failed ts; do
        if [ -n "$suite" ]; then
            total_tests=$((total_tests + total))
            passed_tests=$((passed_tests + passed))
            failed_tests=$((failed_tests + failed))
            
            local status="PASS"
            local status_class="status-pass"
            if [ "$failed" -gt 0 ]; then
                status="FAIL"
                status_class="status-fail"
            fi
            
            test_rows+="                <tr>
                    <td><strong>$suite</strong></td>
                    <td><span class=\"status-badge $status_class\">$status</span></td>
                    <td>$total</td>
                    <td>$passed</td>
                    <td>$failed</td>
                    <td>$(echo "$ts" | cut -d'T' -f1)</td>
                </tr>
"
        fi
    done <<< "$report_data"
    
    local success_rate=0
    if [ "$total_tests" -gt 0 ]; then
        success_rate=$(awk "BEGIN {printf \"%.1f\", ($passed_tests * 100 / $total_tests)}")
    fi
    
    # Replace all placeholders
    sed -i "s/{{EPIC}}/$epic_name/g" "$output_file"
    sed -i "s/{{TIMESTAMP}}/$timestamp/g" "$output_file"
    sed -i "s/{{TOTAL_TESTS}}/$total_tests/g" "$output_file"
    sed -i "s/{{PASSED_TESTS}}/$passed_tests/g" "$output_file"
    sed -i "s/{{FAILED_TESTS}}/$failed_tests/g" "$output_file"
    sed -i "s/{{SUCCESS_RATE}}/$success_rate/g" "$output_file"
    sed -i "s|{{TEST_ROWS}}|$test_rows|g" "$output_file"
}

generate_json_report() {
    local output_file="$1"
    local report_data="$2"
    
    cat > "$output_file" << EOF
{
  "generated": "$(date -Iseconds)",
  "epic": "$EPIC",
  "week": "$WEEK",
  "tests": [
EOF
    
    local first=true
    while IFS='|' read -r suite total passed failed ts; do
        if [ -n "$suite" ]; then
            if [ "$first" = false ]; then
                echo "," >> "$output_file"
            fi
            first=false
            
            local status="PASS"
            if [ "$failed" -gt 0 ]; then
                status="FAIL"
            fi
            
            cat >> "$output_file" << TESTEOF
    {
      "test_suite": "$suite",
      "status": "$status",
      "total": $total,
      "passed": $passed,
      "failed": $failed,
      "timestamp": "$ts"
    }
TESTEOF
        fi
    done <<< "$report_data"
    
    cat >> "$output_file" << EOF

  ]
}
EOF
}

generate_markdown_report() {
    local output_file="$1"
    local report_data="$2"
    
    cat > "$output_file" << EOF
# Fawkes Acceptance Test Report

**Epic:** $EPIC  
**Week:** $WEEK  
**Generated:** $(date "+%Y-%m-%d %H:%M:%S")

---

## Summary

EOF
    
    # Calculate totals
    local total_tests=0
    local passed_tests=0
    local failed_tests=0
    
    while IFS='|' read -r suite total passed failed ts; do
        if [ -n "$suite" ]; then
            total_tests=$((total_tests + total))
            passed_tests=$((passed_tests + passed))
            failed_tests=$((failed_tests + failed))
        fi
    done <<< "$report_data"
    
    local success_rate=0
    if [ "$total_tests" -gt 0 ]; then
        success_rate=$(awk "BEGIN {printf \"%.1f\", ($passed_tests * 100 / $total_tests)}")
    fi
    
    cat >> "$output_file" << EOF
- **Total Tests:** $total_tests
- **Passed:** $passed_tests ✅
- **Failed:** $failed_tests ❌
- **Success Rate:** $success_rate%

---

## Test Results

| Test Suite | Status | Total | Passed | Failed | Timestamp |
|------------|--------|-------|--------|--------|-----------|
EOF
    
    while IFS='|' read -r suite total passed failed ts; do
        if [ -n "$suite" ]; then
            local status="✅ PASS"
            if [ "$failed" -gt 0 ]; then
                status="❌ FAIL"
            fi
            
            echo "| $suite | $status | $total | $passed | $failed | $(echo "$ts" | cut -d'T' -f1) |" >> "$output_file"
        fi
    done <<< "$report_data"
    
    cat >> "$output_file" << EOF

---

*Generated by Fawkes Acceptance Test Framework*
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --epic)
                EPIC="$2"
                shift 2
                ;;
            --week)
                WEEK="$2"
                shift 2
                ;;
            --format)
                FORMAT="$2"
                shift 2
                ;;
            --output)
                OUTPUT_FILE="$2"
                shift 2
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
    
    log_info "Generating acceptance test report..."
    
    # Determine which reports to include
    local pattern="*.json"
    if [ -n "$EPIC" ]; then
        case "$EPIC" in
            1)
                pattern="at-e1-*-validation-*.json"
                ;;
            2)
                pattern="at-e2-*-validation-*.json"
                ;;
            *)
                log_error "Invalid epic number: $EPIC"
                exit 1
                ;;
        esac
    fi
    
    # Find all matching test reports
    log_info "Searching for test reports matching: $pattern"
    local report_files=$(find_test_reports "$pattern")
    
    if [ -z "$report_files" ]; then
        log_error "No test reports found matching pattern: $pattern"
        log_info "Please run acceptance tests first to generate reports"
        exit 1
    fi
    
    # Parse all reports
    local report_data=""
    local report_count=0
    
    while IFS= read -r report_file; do
        log_info "Processing: $(basename "$report_file")"
        local parsed=$(parse_json_report "$report_file")
        if [ -n "$parsed" ]; then
            report_data+="$parsed"$'\n'
            report_count=$((report_count + 1))
        fi
    done <<< "$report_files"
    
    if [ $report_count -eq 0 ]; then
        log_error "Failed to parse any test reports"
        exit 1
    fi
    
    log_success "Parsed $report_count test report(s)"
    
    # Generate output file name if not specified
    if [ -z "$OUTPUT_FILE" ]; then
        local epic_suffix=""
        [ -n "$EPIC" ] && epic_suffix="-epic${EPIC}"
        local week_suffix=""
        [ -n "$WEEK" ] && week_suffix="-week${WEEK}"
        OUTPUT_FILE="$REPORTS_DIR/acceptance-test-report${epic_suffix}${week_suffix}-$(date +%Y%m%d-%H%M%S).$FORMAT"
    fi
    
    # Generate report in requested format
    case "$FORMAT" in
        html)
            generate_html_report "$OUTPUT_FILE" "$report_data"
            ;;
        json)
            generate_json_report "$OUTPUT_FILE" "$report_data"
            ;;
        markdown|md)
            generate_markdown_report "$OUTPUT_FILE" "$report_data"
            ;;
        *)
            log_error "Unsupported format: $FORMAT"
            log_error "Supported formats: html, json, markdown"
            exit 1
            ;;
    esac
    
    log_success "Report generated: $OUTPUT_FILE"
    
    # Display report location
    echo ""
    echo "========================================="
    echo "Report Generated Successfully"
    echo "========================================="
    echo "Format:   $FORMAT"
    echo "Location: $OUTPUT_FILE"
    echo "Tests:    $report_count"
    echo "========================================="
    echo ""
    
    if [ "$FORMAT" = "html" ]; then
        log_info "Open in browser: file://$OUTPUT_FILE"
    fi
}

# Run main function
main "$@"
