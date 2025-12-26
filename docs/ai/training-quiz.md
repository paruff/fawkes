# AI Usage Policy Training Quiz

## Quiz Information

**Duration**: 20 minutes
**Passing Score**: 90% (9 out of 10 correct)
**Attempts**: Unlimited
**Certification**: Valid for 1 year

---

## Instructions

1. Read each question carefully
2. Select the best answer for each question
3. Some questions may have multiple correct answers
4. Review the [AI Usage Policy](./usage-policy.md) if needed
5. Submit your answers for evaluation

---

## Questions

### Question 1: Approved AI Tools

**Which of the following AI tools are approved for use without restrictions?**

A. GitHub Copilot with organization subscription
B. ChatGPT for sharing proprietary code
C. Internal Weaviate RAG system
D. Any AI tool as long as it's free

**Correct Answer(s)**: A, C

**Explanation**: GitHub Copilot (with org subscription) and the internal Weaviate RAG system are fully approved. ChatGPT has restrictions on what can be shared (no proprietary code). Not all AI tools are approved - they must go through an evaluation process.

---

### Question 2: Data Classification Scenario

**You need help debugging a function that processes user login credentials. Which approach is correct?**

A. Paste the entire function including credentials into ChatGPT for debugging help
B. Ask GitHub Copilot to suggest improvements while working in your IDE
C. Create a pseudocode version removing sensitive data and ask ChatGPT conceptual questions
D. Use the internal RAG system to search for similar authentication patterns

**Correct Answer(s)**: B, C, D

**Explanation**: Never share actual credentials or sensitive authentication code with external AI services (A is wrong). Options B, C, and D are all acceptable: Copilot works in your IDE without sending full context externally, pseudocode removes sensitive details, and internal RAG is safe for sensitive queries.

---

### Question 3: Code Review Requirements

**You used GitHub Copilot to generate 80% of a new REST API endpoint. What are your responsibilities before submitting a PR?**

A. Nothing special - Copilot-generated code doesn't need review
B. Review the code line-by-line and add tests
C. Tag the commit with `[AI-assisted]` and document AI usage in the PR
D. Have the code reviewed by a senior engineer with security focus

**Correct Answer(s)**: B, C, D

**Explanation**: All AI-generated code requires thorough review (A is wrong). You must review the code yourself (B), document AI usage (C), and have it peer-reviewed with appropriate scrutiny (D). Security-critical code may need additional expert review.

---

### Question 4: Security Incident

**You accidentally pasted an AWS access key into ChatGPT while asking for help with a deployment script. What should you do?**

A. Don't worry about it - ChatGPT won't use it maliciously
B. Delete the ChatGPT conversation and pretend it didn't happen
C. Immediately rotate the AWS access key
D. Report the incident to security@fawkes.idp and follow incident response procedures

**Correct Answer(s)**: C, D

**Explanation**: This is a serious security incident. Immediately rotate the compromised credentials (C) and report to the security team (D). Never ignore security incidents (A and B are wrong). Self-reporting unintentional violations helps prevent harm and won't result in disciplinary action.

---

### Question 5: Intellectual Property

**GitHub Copilot suggests code that looks like it might come from an open-source project. What should you do?**

A. Use it without concern - Copilot has filtered out copyrighted code
B. Research the potential source and verify license compatibility
C. Add attribution if it matches a known open-source project
D. Ask Copilot to regenerate a different solution

**Correct Answer(s)**: B, C, D

**Explanation**: While Copilot tries to filter problematic suggestions, you must verify license compatibility (B), add proper attribution (C), or request alternative suggestions (D). Don't blindly trust that filtering is perfect (A is wrong).

---

### Question 6: Acceptable Use

**Which of these are acceptable uses of ChatGPT according to the policy?**

A. "Help me understand the concept of dependency injection with a simple example"
B. "Here's our production database schema with customer table structure - optimize this query"
C. "Explain the trade-offs between microservices and monolithic architecture"
D. "Here's our proprietary recommendation algorithm - help me debug it"

**Correct Answer(s)**: A, C

**Explanation**: General concepts (A) and architectural discussions (C) are fine for external AI tools. Sharing production database schemas (B) or proprietary algorithms (D) violates the policy. For questions about your specific codebase, use the internal RAG system instead.

---

### Question 7: Data Privacy

**Which types of data are you allowed to share with external AI services like ChatGPT?**

A. Customer email addresses for testing email validation logic
B. Public documentation and open-source code examples
C. Internal API endpoints and service architecture
D. Anonymized, pseudocode versions of business logic for conceptual help

**Correct Answer(s)**: B, D

**Explanation**: Public documentation (B) and properly anonymized pseudocode (D) are acceptable. Customer PII like email addresses (A) and internal architecture details (C) should not be shared with external AI services. When in doubt, use the internal RAG system.

---

### Question 8: Commit Message Format

**You used AI assistance for part of your code. Which commit message follows policy guidelines?**

A. `git commit -m "Add user service"`
B. `git commit -m "[AI-assisted] Add user service - Used Copilot for boilerplate, manually added validation and tests"`
C. `git commit -m "Add user service - Copilot did everything"`
D. `git commit -m "[Copilot] Add user service"`

**Correct Answer(s)**: B

**Explanation**: Option B correctly uses the `[AI-assisted]` tag, specifies the tool used, and describes what was AI-generated vs. manually added. A doesn't mention AI usage. C implies no human review (unacceptable). D lacks detail about the extent of AI assistance.

---

### Question 9: License Compliance

**An AI tool suggests code that appears to be under GPL license. What should you do?**

A. Use it freely - AI-generated code is not subject to licensing
B. Check if your project is compatible with GPL license terms
C. Contact the legal team for review before using GPL code
D. Rewrite the functionality to avoid the GPL code entirely

**Correct Answer(s)**: B, C, D

**Explanation**: GPL is a strong copyleft license that may have implications for your project. You must check compatibility (B), get legal review (C), or avoid it by implementing differently (D). AI suggestions don't exempt you from license obligations (A is wrong).

---

### Question 10: Training and Certification

**How often must you renew your AI Tool User Certification?**

A. Never - once certified, always certified
B. Every 6 months
C. Annually (every year)
D. Only when the policy changes significantly

**Correct Answer(s)**: C

**Explanation**: According to the policy, AI Tool User Certification must be renewed annually to ensure developers stay current with policy updates, new tools, and evolving best practices.

---

## Scoring Guide

### Score Calculation

Each question is worth 10 points. To calculate your score:

1. Count the number of correctly answered questions
2. Multiply by 10 to get your percentage score
3. You need 90% (9/10 correct) to pass

### Passing Requirements

To receive your AI Tool User Certification:

- ✅ Score 90% or higher (9-10 correct answers)
- ✅ Review any incorrect answers and understand why
- ✅ Complete certification form (provided after passing)

### If You Don't Pass

- Review the [AI Usage Policy](./usage-policy.md) thoroughly
- Pay special attention to sections related to questions you missed
- Retake the quiz - unlimited attempts allowed
- Contact the Platform Team (#ai-tools on Slack) if you need clarification

---

## Certificate of Completion

Upon passing this quiz with 90% or higher, you will receive:

### AI Tool User Certification

```
═══════════════════════════════════════════════════════════
                CERTIFICATE OF COMPLETION
═══════════════════════════════════════════════════════════

                     This certifies that

                      [YOUR NAME HERE]

          has successfully completed the AI Usage Policy
               Training and demonstrated proficiency
                 in responsible AI tool usage at

                      Fawkes Platform

Date Issued: [DATE]
Valid Until: [DATE + 1 YEAR]
Certificate ID: [UNIQUE-ID]

Quiz Score: [SCORE]%

Authorized by: Platform Team
Training Version: 1.0

═══════════════════════════════════════════════════════════

           This certification grants access to:

           ✓ GitHub Copilot Organization License
           ✓ Internal Weaviate RAG System
           ✓ Approved AI Tools Catalog

           Renewal Required: Annual
           Contact: platform-team@fawkes.idp

═══════════════════════════════════════════════════════════
```

---

## Answer Key

**For Training Administrators Only**

| Question | Correct Answer(s) | Topic                 |
| -------- | ----------------- | --------------------- |
| Q1       | A, C              | Approved Tools        |
| Q2       | B, C, D           | Data Classification   |
| Q3       | B, C, D           | Code Review           |
| Q4       | C, D              | Security Incident     |
| Q5       | B, C, D           | Intellectual Property |
| Q6       | A, C              | Acceptable Use        |
| Q7       | B, D              | Data Privacy          |
| Q8       | B                 | Documentation         |
| Q9       | B, C, D           | License Compliance    |
| Q10      | C                 | Training Requirements |

---

## Feedback and Questions

### Need Help?

- **Platform Team**: platform-team@fawkes.idp
- **Slack**: #ai-tools
- **Office Hours**: Every Tuesday 2-3 PM

### Quiz Feedback

Help us improve this quiz:

- Submit feedback: [Quiz Feedback Form](https://backstage.fawkes.idp/ai-quiz-feedback)
- Report errors: platform-team@fawkes.idp
- Suggest questions: #ai-policy-discussion (Slack)

---

## Next Steps After Certification

Once certified, you should:

1. **Set up your AI tools**

   - [GitHub Copilot Setup Guide](./copilot-setup.md)
   - [Access Internal RAG System](./vector-database.md)
   - [Browse AI Tools Catalog](https://backstage.fawkes.idp/catalog?filters[kind]=tool&filters[spec.type]=ai)

2. **Join the AI Community**

   - Slack: #ai-tools
   - Monthly AI Tips newsletter
   - Quarterly AI Tool workshops

3. **Stay Current**

   - Watch for policy updates
   - Participate in quarterly refreshers
   - Share your AI tips and learnings

4. **Mark Your Calendar**
   - Set reminder for certification renewal (1 year)
   - Attend optional advanced AI workshops
   - Participate in AI Community of Practice

---

## Related Resources

- [AI Usage Policy](./usage-policy.md) - Complete policy document
- [GitHub Copilot Setup Guide](./copilot-setup.md) - Tool configuration
- [Vector Database Guide](./vector-database.md) - Internal RAG system
- [Security Policy](../security.md) - Organization security standards
- [Code Review Guidelines](../contributing.md) - Development standards

---

**Quiz Version**: 1.0
**Last Updated**: December 2025
**Next Review**: March 2026
