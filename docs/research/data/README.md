# Research Data

This directory contains raw and processed data from user research activities.

## Directory Structure

```
data/
├── raw/              # Original, unmodified data
└── processed/        # Cleaned and analyzed data
```

## Raw Data (`raw/`)

**Purpose**: Store original, unmodified data as collected.

**Contents**:

- Survey responses (CSV, JSON)
- Analytics exports
- Unprocessed interview recordings metadata
- Raw observation notes
- Form submissions
- Usage logs

**Guidelines**:

- **Never modify**: Keep original data intact
- **Metadata**: Include a `README.md` or metadata file describing:
  - Collection method
  - Date collected
  - Sample size
  - Collection tool used
  - Any known issues or limitations
- **Naming**: Use descriptive names with dates
  - Example: `2025-12-23-user-survey-responses.csv`
- **Privacy**: Do NOT commit files with PII or sensitive data
  - Use anonymization before committing
  - Reference secure storage location if needed

**Example Metadata File** (`raw/2025-12-deployment-survey-metadata.md`):

```markdown
# Deployment Experience Survey - December 2025

**Collection Period**: December 1-15, 2025
**Tool**: Google Forms
**Sample Size**: 47 responses
**Response Rate**: 68% (47/69 invited)
**Target Audience**: Platform users who deployed in last 30 days

## Questions

1. Role and experience level
2. Deployment frequency
3. Pain points (open-ended)
4. Satisfaction rating (1-5)
5. Feature requests (optional)

## Data Files

- `2025-12-15-deployment-survey-raw.csv` - All responses
- `2025-12-15-deployment-survey-open-responses.txt` - Open-ended answers

## Known Issues

- Question 3 had a character limit, some responses truncated
- 3 responses excluded due to test submissions

## Privacy

- All emails and names removed
- Anonymized as Respondent_001, Respondent_002, etc.
```

## Processed Data (`processed/`)

**Purpose**: Store cleaned, analyzed, or transformed data.

**Contents**:

- Cleaned survey data
- Anonymized interview transcripts
- Aggregated analytics
- Coded qualitative data
- Statistical analysis outputs

**Guidelines**:

- **Document transformation**: Include notes on how data was processed
- **Link to source**: Reference original raw data file
- **Version**: If data is processed multiple times, use versions
  - Example: `2025-12-deployment-survey-processed-v2.csv`
- **Data dictionary**: Include column definitions for datasets

**Example Processing Notes** (`processed/2025-12-deployment-survey-processing-notes.md`):

```markdown
# Processing Notes: Deployment Survey

**Source**: `raw/2025-12-15-deployment-survey-raw.csv`
**Processed**: December 16, 2025
**Processed By**: Research Team

## Transformations Applied

1. **Anonymization**

   - Removed email addresses
   - Replaced names with Respondent_NNN

2. **Data Cleaning**

   - Removed 3 test submissions
   - Fixed typos in role field
   - Standardized experience level values

3. **Categorization**

   - Coded open-ended pain points into 8 themes
   - Tagged responses by user segment

4. **Aggregation**
   - Calculated average satisfaction by role
   - Counted pain point mentions by theme

## Output Files

- `2025-12-deployment-survey-processed.csv` - Clean dataset
- `2025-12-deployment-survey-themes.csv` - Coded themes
- `2025-12-deployment-survey-summary.json` - Aggregated stats

## Data Dictionary

See: `2025-12-deployment-survey-data-dictionary.md`
```

## Data Types

### Quantitative Data

- Survey responses with rating scales
- Analytics metrics
- Usage statistics
- Performance measurements
- A/B test results

**Tools**: Excel, Google Sheets, Python (pandas), R

### Qualitative Data

- Interview transcripts
- Open-ended survey responses
- Observation notes
- Support ticket content
- User feedback

**Tools**: NVivo, Atlas.ti, spreadsheets for simple coding

### Mixed Methods

- Surveys with both ratings and open-ended questions
- Interviews with structured and unstructured sections

## Privacy and Security

### What NOT to Commit

❌ **Never commit**:

- Personally identifiable information (PII)
  - Names, email addresses, phone numbers
  - User IDs that can be linked to individuals
  - IP addresses
- Sensitive data
  - Passwords or credentials
  - API keys
  - Internal system details
- Raw audio/video recordings with identifiable information

### What's Safe to Commit

✅ **Safe to commit**:

- Anonymized survey responses
- Aggregated analytics (no individual-level data)
- De-identified interview transcripts
- Statistical summaries
- Coded qualitative data (without PII)

### Anonymization Checklist

Before committing data:

- [ ] Remove all names and email addresses
- [ ] Replace identifiers with pseudonyms (Respondent_001)
- [ ] Remove or generalize location data
- [ ] Remove timestamps that could identify individuals
- [ ] Ensure no combination of attributes could re-identify users
- [ ] Review free-text fields for accidental PII mentions

## Data Retention

- **Raw data**: Retain for 1 year after collection, then archive or delete
- **Processed data**: Retain indefinitely for historical analysis
- **PII**: Delete within 1 year or per company policy
- **Recordings**: Store securely outside Git, delete after 1 year

## Best Practices

✅ **Do:**

- Document collection methodology
- Keep raw and processed data separate
- Include data dictionaries
- Version processed datasets
- Link data to insights and artifacts
- Review data privacy before committing

❌ **Don't:**

- Modify raw data files
- Commit PII or sensitive information
- Use vague filenames
- Skip documentation
- Share data without authorization
- Keep data without purpose

## Data Analysis

### Tools

- **Spreadsheets**: Google Sheets, Excel (for simple analysis)
- **Python**: pandas, matplotlib (for data processing and visualization)
- **R**: ggplot2, dplyr (for statistical analysis)
- **Qualitative**: NVivo, Atlas.ti, or manual coding

### Analysis Workflow

1. **Load data**: Import raw data
2. **Clean**: Remove invalid entries, standardize formats
3. **Explore**: Calculate descriptive statistics, visualize distributions
4. **Analyze**: Test hypotheses, identify patterns
5. **Visualize**: Create charts and graphs
6. **Interpret**: Draw insights and conclusions
7. **Document**: Record methodology and findings

## Resources

- [Main Research README](../README.md)
- [Insights Directory](../insights/)
- [GDPR Compliance Guide](https://gdpr.eu/)
- [Anonymization Best Practices](https://www.nngroup.com/articles/qualitative-research-ethics/)
