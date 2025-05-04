# Hygieia Notes

## Deployment Environment Variables

Update these environment variables in the specified YAML files:

1. `jenkins-build-collector-deployment.yaml`: `JENKINS_API_KEY`, `JENKINS_MASTER`
2. `sonar-codequality-collector-deployment.yaml`: `SONAR_URL`
3. `jira-collector-deployment.yaml`: `JIRA_CREDENTIALS`, `JIRA_BASE_URL`
4. `gitlab-scm-collector-deployment.yaml`: `GITLAB_API_TOKEN`

## Collector Configuration

### GitLab SCM Collector

- Create an API Access Token for use in the `GITLAB_API_TOKEN` environment variable in `gitlab-scm-collector-deployment.yaml`.

### Jenkins Build Collector

- Create an API Key for the admin user and set it in `JENKINS_API_KEY` in `jenkins-build-collector-deployment.yaml`.
- Set the base URL of your Jenkins deployment in `JENKINS_MASTER`.
- Jenkins URL should match your collector configuration.  
  - If Jenkins and Hygieia are in the same K8s cluster, you can use the internal host (e.g., `jenkins`), but URLs may not be clickable for dashboard users.
  - It is recommended to set the Jenkins URL in **Manage Jenkins → System Configuration** to ensure generated URLs are reachable.

## UI Updates

- Dockerfile updated to not call `conf-builder.sh` (the contained `sed` command fails).
- `default.conf` updated to use host `api` at port `8080` by default.
- `default.conf` is now copied directly to the nginx conf directory instead of being built from a template.

## Jenkins Plugin Recommendation

Hygieia developers recommend using the [Jenkins plugin](https://hygieia.github.io/Hygieia/hygieia-jenkins-plugin.html) instead of the collectors due to performance issues with the Jenkins build collectors, especially on instances with many jobs.  
See: [Hygieia Issue #2489](https://github.com/Hygieia/Hygieia/issues/2489)

> "Ideally, you should be using the Jenkins plugin we provide as there are some performance issues for the Jenkins build collectors on Jenkins instances with a large number of jobs."

### Jenkins Build Collector Dockerfile

1. Fixed Dockerfile to ensure `properties-builder.sh` is copied after the target directory is created.
2. Applied general issue #1 (see below).
3. Built, tagged, and deployed a custom Docker image.
4. Manually created an API Key in Jenkins for `JENKINS_API_KEY`.

## Jira Collector

- Story, Epic, and Custom field IDs differ between Jira instances.
- To reveal the IDs needed in `jira-collector-deployment.yaml`, run:

    ```sh
    curl -u <user>:<token> https://<your-jira-instance>/rest/api/2/field
    ```

## General Issues

1. [Inconsistencies in Docker property-builder script](https://github.com/Hygieia/Hygieia/issues/2681) can cause unexpected failures due to misconfiguration.
2. Stopped using dynamically built Docker images due to unpredictable results.
