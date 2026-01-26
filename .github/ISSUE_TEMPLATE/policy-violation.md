---
name: Policy Violation Remediation
about: Track remediation of a security policy violation
title: '[POLICY] {{ POLICY_NAME }} violation in {{ COMPONENT }}'
labels: security, policy-violation
assignees: ''
---

## 🛡️ Policy Violation Details

**Policy**: {{ POLICY_NAME }}  
**Severity**: {{ SEVERITY }}  
**Component**: {{ COMPONENT }}  
**File**: {{ FILE_PATH }}  
**Discovered By**: {{ SCANNER_NAME }}  
**Discovery Date**: {{ DATE }}

## Violation Description

{{ VIOLATION_DESCRIPTION }}

## Policy Requirement

The policy requires:
{{ POLICY_REQUIREMENT }}

## Current State

Current configuration/code:
```yaml
{{ CURRENT_CODE }}
```

## Required Changes

Expected configuration/code:
```yaml
{{ EXPECTED_CODE }}
```

## Impact Assessment

### Security Impact
{{ SECURITY_IMPACT }}

### Business Impact
{{ BUSINESS_IMPACT }}

### Risk if Not Fixed
- [ ] **Critical** - Potential for security breach
- [ ] **High** - Significant security weakness
- [ ] **Medium** - Minor security concern
- [ ] **Low** - Best practice deviation

## Remediation Options

### Option 1: Fix Violation (Recommended)
```bash
# Steps to fix
{{ FIX_STEPS }}
```

**Estimated Effort**: {{ EFFORT_ESTIMATE }}  
**Breaking Changes**: {{ BREAKING_CHANGES }}

### Option 2: Request Policy Exemption
If this violation cannot be fixed due to technical constraints:

- [ ] Compensating controls in place
- [ ] False positive - policy doesn't apply
- [ ] Temporary exemption needed (with expiration)

**Justification**: {{ EXEMPTION_JUSTIFICATION }}  
**Compensating Controls**: {{ COMPENSATING_CONTROLS }}  
**Expiration Date**: {{ EXPIRATION_DATE }}  
**Approver**: @{{ SECURITY_LEAD }}

## Remediation Plan

### Steps
1. [ ] Review policy and violation details
2. [ ] Design fix that meets policy requirements
3. [ ] Implement changes
4. [ ] Test changes locally with `conftest test`
5. [ ] Run full security scan
6. [ ] Submit PR with changes
7. [ ] Verify policy check passes in CI
8. [ ] Deploy changes
9. [ ] Verify compliance
10. [ ] Update documentation

### Testing Locally
```bash
# Test policy compliance locally
conftest test {{ FILE_PATH }} -p .security-plane/policies/

# Expected output: no violations
```

## Policy Details

### Policy File
`.security-plane/policies/{{ POLICY_FILE }}`

### Relevant Policy Code
```rego
{{ POLICY_CODE }}
```

### Policy Rationale
{{ POLICY_RATIONALE }}

## Examples

### Compliant Example
```yaml
{{ COMPLIANT_EXAMPLE }}
```

### Similar Fixes in Other Components
- {{ EXAMPLE_1 }}
- {{ EXAMPLE_2 }}

## Timeline

- **Target Fix Date**: {{ TARGET_DATE }}
- **PR Submission**: {{ PR_DATE }}
- **Verification Date**: {{ VERIFICATION_DATE }}

## References

- Policy Documentation: `docs/security-plane/policies/{{ POLICY_NAME }}.md`
- Related Policies: {{ RELATED_POLICIES }}
- Best Practice Guides: {{ GUIDES }}

## Additional Context

{{ ADDITIONAL_CONTEXT }}

## Verification

After fix is implemented:
```bash
# Verify policy compliance
conftest test {{ FILE_PATH }} -p .security-plane/policies/ --all-namespaces

# Run full security workflow
gh workflow run security-plane-adoption.yml
```

**Expected Result**: Policy violation no longer appears in scan results

---

**Labels**: `security`, `policy-violation`, `severity:{{ SEVERITY }}`, `policy:{{ POLICY_NAME }}`  
**Priority**: {{ PRIORITY }}

/cc @security-team @{{ COMPONENT_OWNER }}
