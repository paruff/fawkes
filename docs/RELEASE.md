# Release Process Guide

This document describes the release process for Fawkes. Follow these steps every time a new version is published.

---

## Overview

Fawkes uses [Semantic Versioning](https://semver.org/) (`MAJOR.MINOR.PATCH`) and follows the [Keep a Changelog](https://keepachangelog.com/) convention.

| Version component | When to increment |
|---|---|
| `MAJOR` | Breaking changes to public APIs or platform contracts |
| `MINOR` | New features that are backwards-compatible |
| `PATCH` | Backwards-compatible bug fixes only |

Current releases are listed in [CHANGELOG.md](../CHANGELOG.md) and on the [GitHub Releases page](https://github.com/paruff/fawkes/releases).

---

## Step-by-Step Release Checklist

### 1. Prepare the release branch

Work on `main` (or a dedicated `release/vX.Y.Z` branch for larger releases):

```bash
git checkout main
git pull origin main
```

### 2. Update CHANGELOG.md

Move items from `[Unreleased]` into a new versioned section:

```markdown
## [X.Y.Z] - YYYY-MM-DD

**Short release title**
[GitHub Release](https://github.com/paruff/fawkes/releases/tag/vX.Y.Z)

### Added
- Description of new features

### Changed
- Description of changes to existing functionality

### Fixed
- Description of bug fixes

### Removed
- Description of removed features (use sparingly)
```

Update the comparison links at the bottom of CHANGELOG.md:

```markdown
[Unreleased]: https://github.com/paruff/fawkes/compare/vX.Y.Z...HEAD
[X.Y.Z]: https://github.com/paruff/fawkes/compare/vX.Y.(Z-1)...vX.Y.Z
```

For example, when releasing v0.3.0:

```markdown
[Unreleased]: https://github.com/paruff/fawkes/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/paruff/fawkes/compare/v0.2.0...v0.3.0
```

### 3. Update README.md

In the `## 🗺️ Roadmap` section, update the **Current Release** line to point to the new version:

```markdown
### Current Release: [vX.Y.Z](https://github.com/paruff/fawkes/releases/tag/vX.Y.Z) (Month YYYY)
```

Move completed items from the "planned" lists into the current release bullet list with ✅ checkmarks.

### 4. Commit the version bump

```bash
git add CHANGELOG.md README.md
git commit -m "chore(release): prepare vX.Y.Z"
git push origin main
```

### 5. Tag the release

Create an annotated tag:

```bash
git tag -a vX.Y.Z -m "Release vX.Y.Z — <short title>"
git push origin vX.Y.Z
```

> **Note:** Always prefix the tag with `v` (e.g., `v0.3.0`, not `0.3.0`).

### 6. Create the GitHub Release

1. Go to [GitHub Releases](https://github.com/paruff/fawkes/releases) → **Draft a new release**.
2. Select the tag `vX.Y.Z` you just pushed.
3. Set the title to a short human-readable description of the release theme.
4. Paste the CHANGELOG section for this version into the release body.
5. Mark as **pre-release** if the version is `0.x.y` or includes a `-alpha`/`-beta` suffix.
6. Click **Publish release**.

### 7. Verify

- [ ] Tag appears at `https://github.com/paruff/fawkes/tags`
- [ ] Release appears at `https://github.com/paruff/fawkes/releases`
- [ ] CHANGELOG.md `[Unreleased]` comparison link points to new tag
- [ ] README.md roadmap section shows the new version as current
- [ ] CI is green on `main` post-tag

---

## Hotfix Releases

For critical fixes on a released version (e.g., hotfix to v0.3.0 → v0.3.1):

```bash
git checkout -b hotfix/v0.3.1 v0.3.0
# Make fixes
git commit -m "fix(scope): description of fix"
git tag -a v0.3.1 -m "Hotfix v0.3.1 — <description>"
git push origin v0.3.1
git checkout main
git merge hotfix/v0.3.1
git push origin main
```

Then follow steps 2–7 above for the patch version.

---

## Versioning Policy

- Versions `0.x.y` are considered **pre-stable**. Breaking changes may occur between minor versions.
- Version `1.0.0` marks the first **stable release** with committed API stability.
- Dependency-only updates (Dependabot bumps) do not require a new release; they are batched into the next MINOR or PATCH release.

---

## Related Documents

- [CHANGELOG.md](../CHANGELOG.md) — full version history
- [CONTRIBUTING.md](contributing.md) — how to contribute to Fawkes
- [docs/ARCHITECTURE.md](ARCHITECTURE.md) — platform architecture overview
- [GitHub Releases](https://github.com/paruff/fawkes/releases) — published release notes
