# SonarQube Quality Profiles

## Overview

Quality Profiles define the set of rules applied during code analysis. Fawkes uses customized quality profiles for each supported language to enforce platform standards.

## Default Quality Profiles

### Java Quality Profile

**Profile Name**: `Fawkes Java`
**Parent**: Sonar way (built-in)

#### Additional Rules Enabled

- **Security**:

  - `java:S2068` - Credentials should not be hard-coded
  - `java:S5852` - Regex should not be vulnerable to DoS
  - `java:S4426` - Cryptographic keys should be robust
  - `java:S2245` - Random values should not be predictable

- **Reliability**:

  - `java:S1181` - Catching Throwable is not recommended
  - `java:S1155` - Collection.isEmpty() should be used instead of size()
  - `java:S3776` - Cognitive complexity should not be too high (threshold: 15)

- **Maintainability**:
  - `java:S1192` - String literals should not be duplicated
  - `java:S1172` - Unused method parameters should be removed
  - `java:S1118` - Utility classes should not have public constructors

#### Configuration for Spring Boot

For Spring Boot applications, the following rules are adjusted:

- `java:S3749` - Spring components should use constructor injection (Enabled)
- `java:S1948` - Fields in Serializable classes should be serializable (Info level)
- Actuator endpoints exposed for observability (Suppressed - see ADR-014)

### Python Quality Profile

**Profile Name**: `Fawkes Python`
**Parent**: Sonar way (built-in)

#### Additional Rules Enabled

- **Security**:

  - `python:S1313` - IP addresses should not be hardcoded
  - `python:S2245` - Pseudorandom number generators should not be used for security purposes
  - `python:S5247` - Server hostname should be verified during SSL/TLS connection
  - `python:S4507` - CORS should be properly configured

- **Reliability**:

  - `python:S5754` - boto3 and botocore should be initialized with credentials
  - `python:S1117` - Local variables should not have the same name as global variables
  - `python:S3776` - Cognitive complexity should not be too high (threshold: 15)

- **Maintainability**:
  - `python:S1871` - Branches should not have the same implementation
  - `python:S1172` - Unused function parameters should be removed
  - `python:S5797` - Variables should be defined before use

#### Configuration for FastAPI

For FastAPI applications:

- `python:S5753` - Route handlers should use type hints (Enabled)
- `python:S1192` - String literals should not be duplicated (threshold: 5)

### Node.js/JavaScript Quality Profile

**Profile Name**: `Fawkes JavaScript`
**Parent**: Sonar way (built-in)

#### Additional Rules Enabled

- **Security**:

  - `javascript:S1523` - Code should not be dynamically executed
  - `javascript:S4829` - Server hostnames should be verified during SSL/TLS connections
  - `javascript:S5122` - CORS should be properly configured
  - `javascript:S2068` - Credentials should not be hard-coded

- **Reliability**:

  - `javascript:S3776` - Cognitive complexity should not be too high (threshold: 15)
  - `javascript:S1264` - A while loop should be used instead of a for loop
  - `javascript:S1874` - Deprecated APIs should not be used

- **Maintainability**:
  - `javascript:S1192` - String literals should not be duplicated
  - `javascript:S138` - Functions should not have too many lines (threshold: 75)
  - `javascript:S1541` - Cyclomatic complexity should not be too high (threshold: 10)

#### Configuration for Express

For Express applications:

- `javascript:S5122` - CORS configuration validated
- `javascript:S5689` - Helmet middleware recommended (Info level)

## Creating Quality Profiles via UI

### Initial Setup (First Time)

1. **Access SonarQube**:

   ```bash
   # Local development
   http://sonarqube.127.0.0.1.nip.io

   # Production
   https://sonarqube.fawkes.idp
   ```

2. **Login as Admin**:

   - Username: `admin`
   - Password: `admin` (change immediately!)

3. **Navigate to Quality Profiles**:

   - Click **Quality Profiles** in the top menu
   - Select the language (Java, Python, or JavaScript)

4. **Create Custom Profile**:

   - Click **Create** button
   - Name: `Fawkes <Language>` (e.g., `Fawkes Java`)
   - Parent: Select `Sonar way`
   - Click **Create**

5. **Activate Additional Rules**:

   - Click on the newly created profile
   - Click **Activate More** button
   - Search for rules by key (e.g., `java:S2068`)
   - Select rules and click **Bulk Change** → **Activate In...**
   - Select your custom profile

6. **Set as Default**:
   - Click the **⚙** icon next to the profile
   - Select **Set as Default**

### Exporting Quality Profiles

Once configured, export profiles for backup/version control:

```bash
# Export Java profile
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/backup?qualityProfile=Fawkes%20Java&language=java" \
  > fawkes-java-profile.xml

# Export Python profile
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/backup?qualityProfile=Fawkes%20Python&language=py" \
  > fawkes-python-profile.xml

# Export JavaScript profile
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/backup?qualityProfile=Fawkes%20JavaScript&language=js" \
  > fawkes-javascript-profile.xml
```

### Importing Quality Profiles

To import quality profiles on a new SonarQube instance:

```bash
# Import Java profile
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  -F "backup=@fawkes-java-profile.xml" \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/restore"

# Repeat for Python and JavaScript profiles
```

## Creating Quality Profiles via API

### Using the Web API

```bash
# 1. Copy from Sonar way
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/copy?fromKey=<sonar-way-key>&toName=Fawkes%20Java"

# 2. Activate rules
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/activate_rule?key=<profile-key>&rule=java:S2068"

# 3. Set as default
curl -u admin:${SONAR_PASSWORD} \
  -X POST \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/set_default?qualityProfile=Fawkes%20Java&language=java"
```

## Quality Profile Enforcement

### Pipeline Integration

Quality profiles are automatically applied in the Golden Path pipeline:

```groovy
stage('SonarQube Analysis') {
    steps {
        withSonarQubeEnv('SonarQube') {
            // Profile is selected based on project language
            sh 'mvn sonar:sonar -Dsonar.projectKey=${PROJECT_KEY}'
        }
    }
}
```

### Project-Specific Overrides

To use a specific quality profile for a project:

```xml
<!-- pom.xml for Java -->
<properties>
    <sonar.profile>Fawkes Java</sonar.profile>
</properties>
```

```python
# sonar-project.properties for Python
sonar.profile=Fawkes Python
```

```javascript
// sonar-project.properties for Node.js
sonar.profile=Fawkes JavaScript
```

## Quality Gate Configuration

Quality Profiles work with Quality Gates. The default Fawkes Quality Gate requires:

| Metric                         | Operator        | Threshold |
| ------------------------------ | --------------- | --------- |
| New Bugs                       | Is Greater Than | 0         |
| New Vulnerabilities            | Is Greater Than | 0         |
| New Security Hotspots Reviewed | Is Less Than    | 100%      |
| New Code Coverage              | Is Less Than    | 80%       |
| New Duplicated Lines (%)       | Is Greater Than | 3%        |
| New Maintainability Rating     | Is Worse Than   | A         |

See [ADR-014](../../../docs/adr/ADR-014 sonarqube quality gates.md) for details.

## Maintenance

### Updating Profiles

1. **Review Rule Updates**: Check SonarQube release notes for new/updated rules
2. **Test Changes**: Test profile changes on a non-default profile first
3. **Document Changes**: Update this file with any modifications
4. **Export Backup**: Export updated profiles and commit to repository
5. **Communicate**: Notify teams of significant rule changes

### Monitoring Profile Usage

```bash
# List all profiles
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/search"

# Get profile details
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/show?profile=Fawkes%20Java&language=java"

# List projects using a profile
curl -u admin:${SONAR_PASSWORD} \
  "http://sonarqube.fawkes.svc:9000/api/qualityprofiles/projects?profile=Fawkes%20Java&language=java"
```

## Troubleshooting

### Profile Not Applied

**Issue**: Project analysis doesn't use the expected profile

**Solution**:

1. Verify profile is set as default for the language
2. Check project-specific profile assignment
3. Ensure project key matches configuration

### Rules Not Enforcing

**Issue**: Rules in profile don't fail Quality Gate

**Solution**:

1. Verify rule is activated (not just added to profile)
2. Check rule severity matches Quality Gate conditions
3. Ensure Quality Gate is properly configured
4. Review `waitForQualityGate()` configuration in Jenkins

### False Positives

**Issue**: Rules flagging valid code patterns

**Solution**:

1. Use `@SuppressWarnings` or language-specific suppression
2. Add comment explaining why suppression is valid
3. Consider adjusting rule parameters in profile
4. Document in team coding standards

## Resources

- [SonarQube Quality Profiles Documentation](https://docs.sonarqube.org/latest/instance-administration/quality-profiles/)
- [SonarQube Rules](https://rules.sonarsource.com/)
- [SonarQube Web API](https://docs.sonarqube.org/latest/extend/web-api/)
- [Fawkes ADR-014](../../../docs/adr/ADR-014 sonarqube quality gates.md)
