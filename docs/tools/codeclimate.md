# CodeClimate

[CodeClimate](https://codeclimate.com/) is a code quality platform that provides
automated code review for maintainability, test coverage, and technical debt. It
complements SonarQube in the Fawkes quality toolchain.

## What CodeClimate Measures

CodeClimate focuses on **maintainability**. It assigns a letter grade (A–F) based on:

- **Cognitive complexity** — How hard is the code to understand?
- **Duplication** — What percentage of code is copy-pasted?
- **Method length** — Are methods doing too much?
- **File length** — Are files too large to navigate easily?
- **Churn vs complexity** — Files that change frequently AND are complex are the highest risk.

## Configuration

Add a `.codeclimate.yml` to the repository root to tune analysis:

```yaml
version: "2"
plugins:
  python:
    enabled: true
  eslint:
    enabled: true
  duplication:
    enabled: true
    config:
      threshold: 50
checks:
  method-length:
    config:
      threshold: 25
```

## Difference from SonarQube

| Feature | CodeClimate | SonarQube |
|---------|-------------|-----------|
| Maintainability grades | ✅ Primary focus | ✅ Secondary |
| Security SAST | ❌ | ✅ Primary focus |
| Churn/complexity analysis | ✅ | ❌ |
| CI integration | GitHub PR decoration | Jenkins + Quality Gate |

In Fawkes, SonarQube owns security and coverage gates; CodeClimate provides an
additional maintainability lens, especially for identifying high-risk files before
they become hard to change.

## Integration with Fawkes CI

CodeClimate analysis runs as a GitHub Actions step on pull requests. Results appear
as annotations on changed files. A degradation in the maintainability grade blocks
merge via the branch protection rule.

## See Also

- [SonarQube](sonarqube.md)
- [Code Quality Standards](../how-to/development/code-quality-standards.md)
- [Change Failure Rate Reduction](../patterns/change-failure-rate-reduction.md)
