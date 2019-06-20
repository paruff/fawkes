# Hygieia Notes

Here are listed any special configuration items that required special consideration.

## gitlab-scm-collector

1. create an API Access Token for use in environment variable: GITLAB_API_TOKEN defined in gitlab-scm-collector-deployment.yaml

## jenkins-build-collector

1. create an API Key for admin user and in jenkins-build-collector-deployment.yaml in environment variable: JENKINS_API_KEY
2. update jenkins-build-collector-deployment.yaml was the base URL of your jenkins deployment in environment variable: JENKINS_MASTER

# Things Updated in Preparation for K8S Deployment

## UI

1. Dockerfile updated to not call conf-builder.sh as the contained 'sed' command fails.
2. updated default.conf to use host 'api' at port '8080' by default
3. default.conf copied to nginx conf directly instead of building with conf-builder.sh from template

## Jenkins

Hygieia developers recommend using the Jenkins plugin instead of the collectors.  See: https://github.com/Hygieia/Hygieia/issues/2489

"... Ideally though you should be using the jenkins plugin we provide as there are some performance issues for the jenkins build collectors on jenkins instances with a large number of jobs."

Hygieia Jenkins plugin is available at: https://hygieia.github.io/Hygieia/hygieia-jenkins-plugin.html

### jenkins-build-collector

1. It was necessary to fix the Dockerfile.  It tried to copy the properties-builder.sh file before a target directory had been created.
2. general issue #1 (see below) applied
3. custom docker image then built, tagged and deployed.
4. had to manually create an API Key in jenkins to place in environment variable JENKINS_API_KEY
5. Jenkins URL passed needs to match our collector configuration.  Jenkins needs to pass an accessible FQDN or else just make sure that hygieia and jenkins are in the same k8s cluster were jenkins host is just 'jenkins' internally.  The drawback here is that URLs will not be clickable by dashboard users.  It is recommended to set the Jenkins URL inside "Manage Jenkins" -> "System Configuration".  Jenkins cannot reliably know how to get back to itself without this set--generated URLs will be unreachable otherwise.


# General Issues

1. see: https://github.com/Hygieia/Hygieia/issues/2681 -- Inconsistencies in docker property-builder script causing unexpected failure due to misconfiguration
2. Had to stop using Dynamically built docker images.  It resulted in unpredictable results.

