#!/usr/bin/env groovy
/**
 * Docker Build Step for Fawkes Platform
 *
 * Provides Docker image building and pushing functionality.
 *
 * Usage:
 * @Library('fawkes-pipeline-library') _
 * dockerBuild {
 *     imageName = 'my-service'
 *     registry = 'harbor.fawkes.local'
 *     tag = 'v1.0.0'
 * }
 *
 * @author Fawkes Platform Team
 */

def call(Map config = [:]) {
    def defaultConfig = [
        imageName: '',
        registry: env.DOCKER_REGISTRY ?: 'harbor.fawkes.local',
        tag: env.GIT_COMMIT?.take(7) ?: 'latest',
        dockerfile: 'Dockerfile',
        context: '.',
        credentialsId: 'docker-registry-credentials',
        push: true,
        buildArgs: [:],
        labels: [:]
    ]

    config = defaultConfig + config

    if (!config.imageName) {
        error "dockerBuild: imageName is required"
    }

    def fullImage = "${config.registry}/${config.imageName}:${config.tag}"
    def latestImage = "${config.registry}/${config.imageName}:latest"

    stage('Docker Build') {
        container('docker') {
            // Build arguments
            def buildArgsStr = config.buildArgs.collect { k, v -> "--build-arg ${k}=${v}" }.join(' ')

            // Labels
            def labelsStr = config.labels.collect { k, v -> "--label ${k}=${v}" }.join(' ')

            // Add default labels
            def defaultLabels = """
                --label org.opencontainers.image.revision=${env.GIT_COMMIT}
                --label org.opencontainers.image.source=${env.GIT_URL}
                --label org.opencontainers.image.created=${new Date().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')}
            """.stripIndent().replaceAll('\n', ' ')

            echo "Building Docker image: ${fullImage}"

            sh """
                docker build \
                    -f ${config.dockerfile} \
                    -t ${fullImage} \
                    -t ${latestImage} \
                    ${buildArgsStr} \
                    ${labelsStr} \
                    ${defaultLabels} \
                    ${config.context}
            """

            if (config.push) {
                pushImage(config, fullImage, latestImage)
            }
        }
    }

    return [
        image: fullImage,
        tag: config.tag,
        digest: getImageDigest(fullImage)
    ]
}

/**
 * Push Docker image to registry
 */
def pushImage(Map config, String fullImage, String latestImage) {
    withCredentials([usernamePassword(
        credentialsId: config.credentialsId,
        usernameVariable: 'REGISTRY_USER',
        passwordVariable: 'REGISTRY_PASS'
    )]) {
        echo "Pushing image to registry: ${config.registry}"

        sh """
            echo \$REGISTRY_PASS | docker login ${config.registry} -u \$REGISTRY_USER --password-stdin
            docker push ${fullImage}
            docker push ${latestImage}
            docker logout ${config.registry}
        """
    }
}

/**
 * Get Docker image digest
 */
def getImageDigest(String image) {
    try {
        return sh(
            script: "docker inspect --format='{{index .RepoDigests 0}}' ${image}",
            returnStdout: true
        ).trim()
    } catch (Exception e) {
        echo "Warning: Could not get image digest"
        return ''
    }
}

return this
