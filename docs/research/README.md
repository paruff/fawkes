# User Research Repository

## Overview

This repository contains user research artifacts for the Fawkes Internal Product Delivery Platform. The research helps us understand user needs, pain points, and behaviors to inform product decisions and improve developer experience.

## Purpose

- **Store Research Artifacts**: Centralized location for all user research materials
- **Enable Collaboration**: Make research accessible to product, engineering, and design teams
- **Maintain Research Quality**: Standardized templates and processes
- **Track Insights**: Build institutional knowledge about our users over time
- **Inform Decisions**: Evidence-based product and platform improvements

## Directory Structure

```
research/
├── README.md                    # This file - usage guidelines
├── templates/                   # Templates for creating research artifacts
│   ├── persona.md              # User persona template
│   ├── interview-guide.md      # Interview script templates
│   └── journey-map.md          # User journey map template
├── personas/                    # User personas
│   └── .gitkeep
├── interviews/                  # Interview notes and transcripts
│   └── .gitkeep
├── journey-maps/               # User journey maps
│   └── .gitkeep
├── insights/                   # Research insights and syntheses
│   └── .gitkeep
├── data/                       # Research data
│   ├── raw/                    # Raw research data (surveys, recordings)
│   │   └── .gitkeep
│   └── processed/              # Cleaned and analyzed data
│       └── .gitkeep
└── assets/                     # Media files for research
    ├── images/                 # Screenshots, photos, diagrams
    │   └── .gitkeep
    ├── videos/                 # Video recordings (tracked with Git LFS)
    │   └── .gitkeep
    ├── audio/                  # Audio recordings (tracked with Git LFS)
    │   └── .gitkeep
    └── diagrams/               # Workflow diagrams, wireframes
        └── .gitkeep
```

## Getting Started

### Prerequisites

1. **Git LFS**: Large files (videos, audio) are tracked with Git LFS
   ```bash
   # Install Git LFS (if not already installed)
   git lfs install
   
   # Pull LFS files
   git lfs pull
   ```

2. **Access**: Ensure you have appropriate access to the repository
   - Read access: All team members
   - Write access: Product team, researchers, designated contributors

### Quick Start

1. **Clone the repository** (if not already done):
   ```bash
   git clone https://github.com/paruff/fawkes.git
   cd fawkes/docs/research
   ```

2. **Create a new research artifact**:
   ```bash
   # Copy a template
   cp templates/persona.md personas/my-new-persona.md
   
   # Edit the file with your content
   vim personas/my-new-persona.md
   ```

3. **Commit and push**:
   ```bash
   git add personas/my-new-persona.md
   git commit -m "Add new persona: Platform Engineer"
   git push
   ```

## Usage Guidelines

### Creating Research Artifacts

#### Personas

**Purpose**: Represent key user segments with their goals, pain points, and behaviors.

**When to Create**:
- After conducting 5+ user interviews
- When you identify a distinct user segment
- When updating existing personas with new insights

**Naming Convention**: `{role}-{descriptor}.md`
- Examples: `platform-engineer-senior.md`, `app-developer-junior.md`

**Process**:
1. Copy `templates/persona.md`
2. Fill in sections based on research data
3. Include direct quotes from users
4. Add to `personas/` directory
5. Reference in related journey maps and insights

#### Interview Notes

**Purpose**: Document findings from user interviews.

**When to Create**:
- After each user interview
- During user testing sessions
- Following feedback sessions

**Naming Convention**: `YYYY-MM-DD-{participant-role}-{topic}.md`
- Examples: `2025-12-23-platform-engineer-deployment-pain-points.md`

**Process**:
1. Use `templates/interview-guide.md` for script
2. Take notes during interview (with permission)
3. Transcribe within 24 hours
4. Anonymize participant information
5. Highlight key quotes and insights
6. Store in `interviews/` directory

**Privacy Guidelines**:
- Remove personally identifiable information (PII)
- Use pseudonyms or role descriptions
- Obtain consent for recording
- Store recordings separately (see Data Management)

#### Journey Maps

**Purpose**: Visualize user experience across stages to identify pain points and opportunities.

**When to Create**:
- When analyzing a specific user workflow
- After identifying consistent patterns in interviews
- When prioritizing improvements

**Naming Convention**: `{persona}-{scenario}.md`
- Examples: `platform-engineer-incident-response.md`, `app-developer-first-deployment.md`

**Process**:
1. Copy `templates/journey-map.md`
2. Choose specific persona and scenario
3. Map stages based on research
4. Document actions, thoughts, emotions
5. Identify pain points and opportunities
6. Store in `journey-maps/` directory

#### Insights

**Purpose**: Synthesize learnings across multiple research activities.

**When to Create**:
- After completing a research sprint
- Quarterly research summaries
- When preparing for planning sessions
- Ad-hoc synthesis of patterns

**Naming Convention**: `YYYY-MM-{topic}-insights.md`
- Examples: `2025-12-deployment-experience-insights.md`

**Template Structure**:
```markdown
# [Topic] Insights - [Date]

## Summary
[2-3 sentence overview]

## Key Findings
1. [Finding 1]
2. [Finding 2]
3. [Finding 3]

## Evidence
- [Reference to interviews, surveys, etc.]

## Recommendations
1. [Action 1]
2. [Action 2]

## Next Steps
- [Follow-up research needed]
```

**Process**:
1. Review multiple research artifacts
2. Identify patterns and themes
3. Document with supporting evidence
4. Include recommendations
5. Store in `insights/` directory

### Data Management

#### Raw Data

**Location**: `data/raw/`

**Contents**:
- Survey responses (CSV, JSON)
- Analytics exports
- Unprocessed interview recordings
- Raw observation notes

**Guidelines**:
- Keep original, unmodified data
- Include metadata file describing collection method
- Use descriptive filenames with dates
- Never commit PII or sensitive data

#### Processed Data

**Location**: `data/processed/`

**Contents**:
- Cleaned survey data
- Anonymized transcripts
- Aggregated analytics
- Coded qualitative data

**Guidelines**:
- Document transformation process
- Include data dictionary
- Version processed datasets
- Link to source raw data

#### Media Assets

**Images** (`assets/images/`):
- Screenshots
- Photos from sessions
- Diagrams and wireframes
- Supported formats: PNG, JPG, SVG

**Videos** (`assets/videos/`):
- User testing recordings
- Demo videos
- Prototype walkthroughs
- Tracked with Git LFS
- Supported formats: MP4, MOV

**Audio** (`assets/audio/`):
- Interview recordings
- Podcast-style summaries
- Tracked with Git LFS
- Supported formats: MP3, WAV, M4A

**Diagrams** (`assets/diagrams/`):
- Flowcharts
- System diagrams
- Process maps
- Supported formats: Mermaid (`.mmd`), SVG, PNG

### Git LFS Configuration

Large files are automatically tracked with Git LFS. Configured file types:

- Videos: `*.mp4`, `*.mov`, `*.avi`, `*.mkv`
- Audio: `*.mp3`, `*.wav`, `*.m4a`, `*.aac`
- Images (large): `*.psd`, `*.ai`
- Archives: `*.zip`, `*.tar.gz` (for bundled data)

**Working with LFS Files**:

```bash
# Check LFS status
git lfs status

# List tracked files
git lfs ls-files

# Pull all LFS objects
git lfs pull

# Push LFS objects
git lfs push origin main
```

**Storage Limits**:
- Keep individual files under 100MB when possible
- Use external storage (e.g., shared drive) for very large files
- Link to external files in markdown with `[Download](link)`

## Contribution Guidelines

### Who Can Contribute

- **Product Team**: Primary owners, can create and modify all artifacts
- **UX Researchers**: Create personas, journey maps, conduct interviews
- **Engineers**: Add insights from support tickets, usage data
- **Designers**: Contribute journey maps, usability findings
- **Product Managers**: Add insights, update personas

### Contribution Process

1. **Create a Branch**:
   ```bash
   git checkout -b research/add-new-persona-platform-engineer
   ```

2. **Make Changes**:
   - Follow templates
   - Use descriptive filenames
   - Include supporting evidence
   - Link related artifacts

3. **Commit with Clear Messages**:
   ```bash
   git add personas/platform-engineer-senior.md
   git commit -m "Add senior platform engineer persona based on Q4 2025 interviews"
   ```

4. **Open Pull Request**:
   - Describe research context
   - Link to source interviews/data
   - Tag reviewers (product team)

5. **Review Process**:
   - Product owner reviews for completeness
   - Researcher validates against data
   - Merge after approval

### Review Checklist

Before submitting research artifacts, ensure:

- [ ] **Based on Data**: Grounded in actual user research, not assumptions
- [ ] **Anonymized**: No PII or sensitive information
- [ ] **Cited Sources**: References to interviews, surveys, or data
- [ ] **Clear Naming**: Follows naming conventions
- [ ] **Proper Location**: Filed in correct directory
- [ ] **Linked Artifacts**: Cross-references related materials
- [ ] **Current**: Includes date and version information
- [ ] **Actionable**: Includes insights or recommendations where appropriate

## Access Controls

### Read Access

**Who**: All Fawkes team members

**Includes**:
- View all personas, journey maps, templates
- Read processed insights and summaries
- Access anonymized interview notes
- View diagrams and screenshots

**Does Not Include**:
- Raw interview recordings (privacy)
- Unprocessed survey data with PII
- Internal research strategy documents

### Write Access

**Who**: Product team, designated researchers

**Includes**:
- Create new research artifacts
- Update existing personas and journey maps
- Add interview notes and insights
- Upload supporting media

**Process**:
- Request access via GitHub team membership
- Contact product owner: @paruff
- Join `#product-research` channel in Mattermost

### Sensitive Data Access

**Who**: Product owner, lead researcher only

**Location**: Not stored in this repository

**Includes**:
- Raw recordings with identifiable information
- Unredacted survey responses
- Research strategy and roadmap

**Storage**: Secure shared drive (link in internal docs)

## Best Practices

### Research Quality

1. **Sample Size**: Interview 5+ users before creating a persona
2. **Diversity**: Include different roles, experience levels, teams
3. **Recency**: Update personas quarterly or when patterns change
4. **Validation**: Cross-check insights with quantitative data when available
5. **Actionability**: Every insight should inform a decision or action

### Documentation Standards

1. **Markdown Formatting**: Use consistent heading levels and structure
2. **Links**: Use relative links for internal references
3. **Images**: Include alt text for accessibility
4. **Quotes**: Always attribute quotes to persona or interview
5. **Dates**: Use ISO format (YYYY-MM-DD)

### Collaboration

1. **Share Early**: Post WIP personas/maps for feedback
2. **Tag Stakeholders**: Notify relevant teams when publishing insights
3. **Present Findings**: Schedule readouts for major research
4. **Iterate**: Update based on new learnings
5. **Reference**: Link to research in PRD and design docs

### Privacy and Ethics

1. **Informed Consent**: Always obtain consent before recording
2. **Anonymization**: Remove all PII from shared documents
3. **Data Retention**: Delete raw recordings after 1 year (or per policy)
4. **Respect**: Handle user feedback with empathy and professionalism
5. **Transparency**: Be clear about how research will be used

## Research Calendar

### Quarterly Activities

- **Q1**: Annual persona refresh, year-end synthesis
- **Q2**: Journey map updates, feature prioritization research
- **Q3**: Usability testing, onboarding research
- **Q4**: Year-ahead planning, trend analysis

### Ongoing Activities

- **Weekly**: Ad-hoc user interviews, support ticket analysis
- **Monthly**: Insights synthesis, research shareout
- **As-needed**: Feature validation, concept testing

## Resources

### Internal Links

- [Fawkes Architecture](../architecture.md)
- [Product Roadmap](../../ROADMAP.md)
- [DORA Metrics Dashboard](../observability/dora-metrics.md)
- [Developer Portal (Backstage)](https://backstage.fawkes.local)

### External Resources

- [Nielsen Norman Group - User Research Methods](https://www.nngroup.com/articles/)
- [IDEO Design Kit](https://www.designkit.org/)
- [The Mom Test by Rob Fitzpatrick](https://www.momtestbook.com/)
- [Jobs to Be Done Framework](https://jtbd.info/)
- [Google HEART Framework](https://research.google/pubs/pub36299/)

### Recommended Reading

- "Continuous Discovery Habits" by Teresa Torres
- "User Research: Improve Product and Service Design and Enhance Your UX" by Stephanie Marsh
- "Just Enough Research" by Erika Hall
- "Interviewing Users" by Steve Portigal

## Support

### Questions?

- **Slack**: `#product-research` channel
- **Email**: product-team@fawkes.local
- **Office Hours**: Wednesdays 2-3 PM (calendar invite in Mattermost)

### Issues?

- **Repository Issues**: [GitHub Issues](https://github.com/paruff/fawkes/issues)
- **Access Problems**: Contact @paruff
- **Git LFS Issues**: See [Git LFS Troubleshooting](https://github.com/git-lfs/git-lfs/wiki/Tutorial)

## Changelog

### 2025-12-23
- Initial repository structure created
- Added templates (persona, interview guide, journey map)
- Configured Git LFS for media files
- Documented contribution guidelines and access controls

---

**Version**: 1.0  
**Last Updated**: December 23, 2025  
**Owner**: Product Team  
**Status**: Active
