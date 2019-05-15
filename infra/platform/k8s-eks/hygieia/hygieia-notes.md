# Hygieia Notes

Here are listed any special configuration items that required special consideration.

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

## General Issues

1. see: https://github.com/Hygieia/Hygieia/issues/2681 -- Inconsistencies in docker property-builder script causing unexpected failure due to misconfiguration

