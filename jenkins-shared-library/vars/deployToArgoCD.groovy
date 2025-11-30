#!/usr/bin/env groovy
/**
 * Deploy to ArgoCD Step for Fawkes Platform
 *
 * Updates GitOps manifests to trigger ArgoCD deployment.
 *
 * Usage:
 * @Library('fawkes-pipeline-library') _
 * deployToArgoCD {
 *     appName = 'my-service'
 *     environment = 'dev'
 *     imageTag = 'abc1234'
 * }
 *
 * @author Fawkes Platform Team
 */

def call(Map config = [:]) {
    def defaultConfig = [
        appName: '',
        environment: 'dev',
        imageTag: env.GIT_COMMIT?.take(7) ?: 'latest',
        gitopsRepo: 'github.com/paruff/fawkes-gitops',
        credentialsId: 'github-credentials',
        manifestPath: '',
        waitForSync: true,
        syncTimeoutSeconds: 300
    ]

    config = defaultConfig + config

    if (!config.appName) {
        error "deployToArgoCD: appName is required"
    }

    // Set default manifest path if not provided
    if (!config.manifestPath) {
        config.manifestPath = "apps/${config.environment}/${config.appName}"
    }

    stage('Update GitOps') {
        echo "Updating GitOps manifest for ${config.appName} in ${config.environment}"
        
        updateGitOpsManifest(config)
        
        if (config.waitForSync) {
            waitForArgoSync(config)
        }
    }
}

/**
 * Update GitOps manifest in repository
 */
def updateGitOpsManifest(Map config) {
    withCredentials([usernamePassword(
        credentialsId: config.credentialsId,
        usernameVariable: 'GIT_USER',
        passwordVariable: 'GIT_TOKEN'
    )]) {
        sh """
            # Clone GitOps repository
            rm -rf gitops-repo
            git clone https://\${GIT_USER}:\${GIT_TOKEN}@${config.gitopsRepo} gitops-repo
            cd gitops-repo
            
            # Update image tag in deployment manifest
            MANIFEST_PATH="${config.manifestPath}/deployment.yaml"
            
            if [ -f "\${MANIFEST_PATH}" ]; then
                echo "Updating image tag to ${config.imageTag} in \${MANIFEST_PATH}"
                
                # Use kustomize if available, otherwise sed
                if command -v kustomize &> /dev/null && [ -f "${config.manifestPath}/kustomization.yaml" ]; then
                    cd ${config.manifestPath}
                    kustomize edit set image *=${config.imageTag}
                    cd -
                else
                    sed -i 's|:.*\$|:${config.imageTag}|g' \${MANIFEST_PATH}
                fi
                
                # Commit and push
                git config user.name "Jenkins CI"
                git config user.email "jenkins@fawkes.local"
                git add -A
                git diff --cached --quiet || git commit -m "Deploy ${config.appName} ${config.imageTag} to ${config.environment}"
                git push origin main
                
                echo "GitOps manifest updated successfully"
            else
                echo "Warning: Manifest not found at \${MANIFEST_PATH}"
                echo "Available files in ${config.manifestPath}:"
                ls -la ${config.manifestPath} || echo "Directory not found"
            fi
            
            cd ..
            rm -rf gitops-repo
        """
    }
}

/**
 * Wait for ArgoCD to sync the application
 */
def waitForArgoSync(Map config) {
    def argocdServer = env.ARGOCD_SERVER ?: 'argocd-server.argocd.svc'
    def appName = "${config.appName}-${config.environment}"
    
    echo "Waiting for ArgoCD to sync ${appName}..."
    
    try {
        withCredentials([string(credentialsId: 'argocd-token', variable: 'ARGOCD_TOKEN')]) {
            timeout(time: config.syncTimeoutSeconds, unit: 'SECONDS') {
                sh """
                    # Install argocd CLI if not present
                    if ! command -v argocd &> /dev/null; then
                        curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                        chmod +x /usr/local/bin/argocd
                    fi
                    
                    # Login to ArgoCD
                    argocd login ${argocdServer} --grpc-web --insecure --username admin --password \${ARGOCD_TOKEN}
                    
                    # Sync the application
                    argocd app sync ${appName} --grpc-web
                    
                    # Wait for sync to complete
                    argocd app wait ${appName} --grpc-web --health --timeout ${config.syncTimeoutSeconds}
                """
            }
        }
        echo "ArgoCD sync completed successfully for ${appName}"
    } catch (Exception e) {
        echo "Warning: ArgoCD sync wait failed: ${e.message}"
        echo "ArgoCD will continue to reconcile the application"
    }
}

return this
