# AI Usage Policy

## Document Information

**Version**: 1.0
**Last Updated**: December 2025
**Status**: Active
**Owner**: Platform Team
**Review Cycle**: Quarterly

---

## Table of Contents

1. [Introduction](#introduction)
2. [Scope and Purpose](#scope-and-purpose)
3. [Approved AI Tools](#approved-ai-tools)
4. [Acceptable Use Guidelines](#acceptable-use-guidelines)
5. [Data Privacy and Security](#data-privacy-and-security)
6. [Code Review Requirements](#code-review-requirements)
7. [Intellectual Property Considerations](#intellectual-property-considerations)
8. [Compliance and Audit](#compliance-and-audit)
9. [Training and Certification](#training-and-certification)
10. [Violations and Enforcement](#violations-and-enforcement)
11. [Contact and Support](#contact-and-support)

---

## Introduction

This policy establishes guidelines for the responsible use of Artificial Intelligence (AI) tools within our organization. As AI technology becomes increasingly integrated into software development workflows, it's essential to ensure its use aligns with our security, legal, and ethical standards.

### Why This Policy Matters

- **Security**: Protect sensitive data and intellectual property
- **Quality**: Maintain code quality and system reliability
- **Compliance**: Meet regulatory and legal requirements
- **Ethics**: Ensure responsible and fair use of AI technology
- **Productivity**: Maximize benefits while minimizing risks

---

## Scope and Purpose

### Who This Applies To

This policy applies to:

- All software developers and engineers
- DevOps and platform engineers
- Product managers and technical leads
- Contractors and consultants with code access
- Anyone using AI tools for work-related activities

### Purpose

This policy aims to:

1. Define approved AI tools and their appropriate use cases
2. Establish security and privacy boundaries
3. Ensure code quality and maintainability
4. Protect intellectual property rights
5. Enable audit and compliance tracking
6. Promote responsible AI adoption

---

## Approved AI Tools

### Primary AI Tools

#### 1. GitHub Copilot (Approved ✅)

**Purpose**: AI-powered code completion and generation

**Access**: Organization-wide subscription
- Individual license: Contact Platform Team
- IDE extensions available for VS Code, IntelliJ, Vim/Neovim

**Use Cases**:
- Code completion and suggestions
- Function and class generation
- Test case generation
- Documentation writing
- Code refactoring suggestions

**Limitations**:
- Must review all suggestions before accepting
- Not suitable for security-critical code without review
- May suggest deprecated or vulnerable patterns

**Configuration**:
```json
{
  "github.copilot.enable": true,
  "github.copilot.advanced": {
    "blockSuggestions": {
      "matchingPublicCode": true
    }
  }
}
```

**Documentation**: [GitHub Copilot Setup Guide](./copilot-setup.md)

#### 2. ChatGPT / Claude (Approved with Restrictions ⚠️)

**Purpose**: Code assistance, problem-solving, learning

**Access**: Individual accounts (Team or Plus plan recommended)

**Approved Use Cases**:
- General programming questions and learning
- Algorithm design discussions
- Architecture brainstorming
- Public code examples and patterns
- Documentation writing assistance

**Restricted Use Cases**:
- ❌ Do NOT paste proprietary code
- ❌ Do NOT share API keys, credentials, or secrets
- ❌ Do NOT share customer data or PII
- ❌ Do NOT share architectural details of production systems
- ❌ Do NOT share business logic or proprietary algorithms

**Best Practices**:
- Anonymize code snippets before sharing
- Use pseudocode instead of actual implementation
- Focus on concepts rather than specifics
- Verify all responses with official documentation

#### 3. Weaviate RAG System (Approved ✅)

**Purpose**: Internal knowledge retrieval and code context

**Access**: Available to all developers through internal platform

**Use Cases**:
- Query internal documentation
- Search codebase patterns
- Find similar implementations
- Retrieve policy and compliance information

**Advantages**:
- Uses only internal, approved data sources
- No data leaves our infrastructure
- Integrated with Backstage developer portal

**Documentation**: [Vector Database Guide](./vector-database.md)

### Evaluation Process for New AI Tools

To request approval for a new AI tool:

1. Submit request via [AI Tools Request Form](https://backstage.fawkes.idp/ai-tool-request)
2. Platform Team reviews for:
   - Data privacy and security implications
   - License compliance
   - Integration requirements
   - Cost-benefit analysis
3. Decision within 5 business days
4. Approved tools added to this policy

---

## Acceptable Use Guidelines

### ✅ DO: Recommended Practices

1. **Use AI as an Assistant, Not a Replacement**
   - Review and understand all AI-generated code
   - Verify logic, security, and performance implications
   - Consider AI suggestions as starting points, not final solutions

2. **Leverage AI for Productivity**
   - Boilerplate code generation
   - Test case scaffolding
   - Documentation writing
   - Code refactoring suggestions
   - Learning new technologies

3. **Follow Security Best Practices**
   - Never include secrets or credentials in prompts
   - Sanitize code before sharing externally
   - Use internal RAG system for sensitive queries
   - Enable public code blocking in Copilot

4. **Maintain Code Quality**
   - Follow existing code style and conventions
   - Add appropriate comments and documentation
   - Write tests for AI-generated code
   - Conduct peer reviews

5. **Track AI Usage**
   - Tag commits with AI-generated code: `[AI-assisted]`
   - Document AI tool and method in PR descriptions
   - Report issues or concerns to Platform Team

### ❌ DO NOT: Prohibited Activities

1. **Security Violations**
   - ❌ Share API keys, tokens, passwords, or credentials
   - ❌ Paste production configuration files
   - ❌ Share database connection strings
   - ❌ Upload private keys or certificates

2. **Data Privacy Violations**
   - ❌ Share customer PII (names, emails, addresses, etc.)
   - ❌ Share financial or payment information
   - ❌ Share healthcare or sensitive personal data
   - ❌ Share internal employee information

3. **Intellectual Property Violations**
   - ❌ Share proprietary algorithms or business logic
   - ❌ Share trade secrets or confidential information
   - ❌ Copy AI-generated code without attribution
   - ❌ Use AI tools that claim ownership of outputs

4. **Quality Violations**
   - ❌ Blindly accept all AI suggestions without review
   - ❌ Skip testing for AI-generated code
   - ❌ Deploy AI code without peer review
   - ❌ Use AI for critical security or safety code without expert review

---

## Data Privacy and Security

### Data Classification

Before using AI tools, classify your data:

| Classification | Description | AI Tool Usage |
|----------------|-------------|---------------|
| **Public** | Open source, public documentation | ✅ All approved tools |
| **Internal** | Internal docs, non-sensitive code | ✅ Copilot, Internal RAG only |
| **Confidential** | Business logic, customer data | ⚠️ Internal RAG only, with care |
| **Restricted** | Secrets, PII, financial data | ❌ No AI tools |

### Security Requirements

1. **Data Minimization**
   - Share only necessary context with AI tools
   - Remove sensitive information before prompts
   - Use code snippets instead of full files when possible

2. **Access Controls**
   - Use organization-managed AI accounts
   - Enable SSO/SAML where available
   - Follow least-privilege principles

3. **Network Security**
   - Use approved networks for AI tool access
   - VPN required for external AI services
   - Internal RAG system preferred for sensitive queries

4. **Audit Logging**
   - Track AI tool usage in development workflow
   - Tag commits and PRs with AI-assisted labels
   - Report security incidents immediately

### Privacy Considerations

1. **Third-Party AI Services**: Assume data sent to external AI services may be:
   - Stored for training purposes (unless explicitly opted out)
   - Visible to service provider employees
   - Subject to data breach risks
   - Covered by third-party privacy policies

2. **Opt-Out Options**: When available, opt out of:
   - Data collection for model training
   - Telemetry and analytics
   - Public code matching (Copilot)

3. **Data Residency**: Prefer AI tools with:
   - Clear data location policies
   - GDPR/CCPA compliance
   - SOC 2 Type II certification
   - ISO 27001 certification

---

## Code Review Requirements

### AI-Generated Code Review Process

All code with significant AI assistance must undergo enhanced review:

#### 1. Developer Responsibilities

**Before Committing:**
- [ ] Review all AI-generated code line by line
- [ ] Verify logic correctness and edge case handling
- [ ] Check for security vulnerabilities
- [ ] Ensure code follows team conventions
- [ ] Add appropriate tests
- [ ] Document AI usage in commit message

**Commit Message Format:**
```
[AI-assisted] Add user authentication service

- Used GitHub Copilot for boilerplate setup
- Manually reviewed and customized for our use case
- Added integration tests
- Verified against OWASP Top 10

Closes #123
```

#### 2. Reviewer Responsibilities

**Code Review Checklist:**
- [ ] Verify code quality and readability
- [ ] Check for security vulnerabilities (SQLi, XSS, etc.)
- [ ] Validate error handling and edge cases
- [ ] Ensure adequate test coverage
- [ ] Confirm alignment with architecture
- [ ] Review for license compatibility

**Enhanced Scrutiny Areas:**
1. **Authentication/Authorization** - Extra security review required
2. **Data Validation** - Ensure proper input sanitization
3. **External API Calls** - Verify error handling
4. **Database Queries** - Check for SQL injection risks
5. **Cryptography** - Require expert review

#### 3. Security Review Triggers

Automatic security review required for:
- Authentication/authorization changes
- Cryptographic operations
- Database schema changes
- External API integrations
- File system operations
- Network communications

#### 4. Documentation Requirements

Document in PR description:
- AI tool(s) used (Copilot, ChatGPT, etc.)
- Extent of AI assistance (%, estimated)
- Manual modifications made
- Security considerations addressed
- Test coverage added

**Example PR Description:**
```markdown
## Changes
- Implemented user session management
- Added Redis-based session store
- Created session cleanup job

## AI Assistance
- Tool: GitHub Copilot
- Extent: ~60% initial scaffolding
- Manual work: Security hardening, custom business logic, tests

## Security Review
- Input validation added for all endpoints
- Session tokens use cryptographically secure random
- CSRF protection implemented
- Rate limiting configured

## Testing
- Unit test coverage: 95%
- Integration tests: Session lifecycle
- Security tests: Token validation, injection attempts
```

---

## Intellectual Property Considerations

### Code Ownership

1. **Organization Ownership**: All code created using company resources (including AI tools) belongs to the organization

2. **AI-Generated Content**:
   - Treat AI-generated code as any other code
   - Organization owns the final work product
   - Attribution to AI tool optional but recommended

3. **Third-Party Code**: If AI suggests code matching open source:
   - GitHub Copilot: Enable "block public code" setting
   - Manually verify license compatibility
   - Add appropriate attribution and license headers

### License Compliance

#### Acceptable Licenses
✅ Permissive licenses (MIT, Apache 2.0, BSD)
✅ Weak copyleft (LGPL, MPL)
⚠️ Strong copyleft (GPL) - Legal review required
❌ Proprietary/Commercial - Prohibited without legal approval

#### License Review Process

1. **Automatic Scanning**: Trivy and SonarQube scan dependencies
2. **Manual Review**: For any AI-suggested external code
3. **Documentation**: Track licenses in `LICENSE.md` and `NOTICE.md`
4. **Legal Consultation**: Contact legal team for GPL or unclear licenses

### Attribution Requirements

When AI suggests code matching public sources:

```python
# Source: Adapted from [Project Name] (License: MIT)
# Original: https://github.com/user/repo/blob/main/file.py
# Modified by: [Your Name] using GitHub Copilot suggestions
# Changes: [Brief description of modifications]

def example_function():
    # AI-suggested implementation with modifications
    pass
```

---

## Compliance and Audit

### Audit Trail Requirements

#### 1. Development Workflow Tracking

**Required Metadata:**
- AI tool used (Copilot, ChatGPT, RAG)
- Date and time of usage
- Developer identity
- Code files affected
- Commit hash

**Implementation:**
- Git commit tags: `[AI-assisted]`
- PR labels: `ai-generated`
- Code comments: `# Generated with [Tool]`

#### 2. Access Logging

The Platform Team maintains logs of:
- AI tool access requests and approvals
- Organization-level tool usage statistics
- Security incidents related to AI tools
- Training completion records

#### 3. Regular Audits

**Quarterly Reviews:**
- Sample code reviews for AI usage compliance
- Security scan results analysis
- License compliance verification
- Policy effectiveness assessment

**Annual Reviews:**
- Comprehensive AI tool usage audit
- Policy updates based on new tools/risks
- Training program effectiveness
- ROI analysis

### Compliance Requirements

#### Industry Standards

- **SOC 2**: Track AI tool data handling
- **ISO 27001**: Include AI in ISMS
- **GDPR/CCPA**: Document data processing
- **HIPAA** (if applicable): Restrict AI for PHI

#### Regulatory Considerations

1. **Data Residency**: Some jurisdictions require data to stay in-region
2. **AI Transparency**: EU AI Act may require disclosure
3. **Algorithmic Accountability**: Document AI decision-making processes
4. **Bias and Fairness**: Monitor for discriminatory outputs

### Incident Reporting

**Report immediately if:**
- Secrets or credentials exposed to AI tool
- Customer data shared inappropriately
- AI tool generates malicious or vulnerable code
- License violation discovered
- Unauthorized AI tool usage detected

**Reporting Process:**
1. Stop using the affected AI tool immediately
2. Document the incident details
3. Report to security@fawkes.idp or Platform Team
4. Follow incident response procedures
5. Participate in post-incident review

---

## Training and Certification

### Required Training

All developers using AI tools must complete:

#### 1. AI Usage Policy Training (1 hour)
- Policy overview and key requirements
- Approved tools and use cases
- Security and privacy guidelines
- Code review requirements

#### 2. Hands-On AI Tool Training (2 hours)
- GitHub Copilot setup and configuration
- Effective prompt engineering
- Code review best practices
- Internal RAG system usage

#### 3. Security Awareness (30 minutes)
- Data classification review
- Common security pitfalls
- Incident reporting procedures
- Case studies of AI-related incidents

### Certification Requirements

**AI Tool User Certification:**
- Complete all required training modules
- Pass training quiz with 90% score (see [training-quiz.md](./training-quiz.md))
- Renew annually
- Maintain compliance with policy

**Certification Process:**
1. Complete training modules in learning management system
2. Take and pass the [AI Usage Policy Quiz](./training-quiz.md)
3. Receive certification via email
4. Access granted to AI tools

### Ongoing Education

- **Monthly Tips**: AI best practices shared in team channels
- **Quarterly Updates**: Policy changes and new tools
- **Office Hours**: Platform Team available for questions
- **Community of Practice**: Internal Slack channel #ai-tools

---

## Violations and Enforcement

### Violation Categories

#### Minor Violations (Warning)
- Forgot to tag AI-assisted commits
- Used approved tool outside recommended use case
- Missed code review checklist item

**Response**: Verbal/written warning, remedial training

#### Moderate Violations (Probation)
- Shared internal (non-sensitive) code externally
- Skipped security review for AI-generated code
- Repeated minor violations

**Response**: Temporary suspension of AI tool access, mandatory retraining

#### Severe Violations (Disciplinary Action)
- Shared secrets, credentials, or restricted data
- Intentionally bypassed security controls
- Used unauthorized AI tools
- Plagiarism or license violations

**Response**: Revocation of AI tool access, formal disciplinary action, possible termination

### Appeals Process

If you disagree with an enforcement action:

1. Submit written appeal to Platform Team lead
2. Review by impartial committee within 5 business days
3. Decision communicated in writing
4. Escalation to CISO if needed

### Self-Reporting

Encouraged! If you accidentally violate this policy:

1. Report to Platform Team immediately
2. Document what happened and potential impact
3. Cooperate with remediation efforts
4. Learn from the incident

*Self-reporting of unintentional violations will not result in disciplinary action, only corrective measures.*

---

## Contact and Support

### Questions and Guidance

**Platform Team**
- Email: platform-team@fawkes.idp
- Slack: #platform-support
- Office Hours: Every Tuesday 2-3 PM

**AI Tools Specialists**
- GitHub Copilot: copilot-admin@fawkes.idp
- RAG System: rag-support@fawkes.idp
- General AI questions: #ai-tools (Slack)

### Request AI Tool Access

1. Visit [Backstage AI Tools Catalog](https://backstage.fawkes.idp/catalog?filters[kind]=tool&filters[spec.type]=ai)
2. Select desired tool
3. Click "Request Access"
4. Complete brief questionnaire
5. Approval within 1 business day

### Report Security Incidents

**Urgent (24/7)**:
- Security Hotline: security@fawkes.idp
- Incident Response: +1-555-SECURE

**Non-Urgent**:
- Platform Team: platform-team@fawkes.idp
- Submit ticket: [Security Incident Form](https://backstage.fawkes.idp/security-incident)

### Policy Feedback

This policy is a living document. Your feedback helps improve it:

- Submit feedback: [Policy Feedback Form](https://backstage.fawkes.idp/ai-policy-feedback)
- Propose changes: Create PR in documentation repository
- Discussion: #ai-policy-discussion (Slack)

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-12 | Platform Team | Initial policy release |

---

## Related Documentation

- [GitHub Copilot Setup Guide](./copilot-setup.md)
- [Vector Database Guide](./vector-database.md)
- [AI Training Quiz](./training-quiz.md)
- [Security Policy](../security.md)
- [Code Review Guidelines](../contributing.md)

---

## Acknowledgments

This policy was developed with input from:
- Platform Engineering Team
- Security Team
- Legal & Compliance
- Developer Community

**Policy Owner**: Platform Team
**Review Cycle**: Quarterly
**Next Review**: March 2026
