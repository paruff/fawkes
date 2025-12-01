#!/usr/bin/env groovy
/**
 * Vault Secrets Integration for Fawkes Platform
 *
 * Provides utilities for retrieving secrets from HashiCorp Vault
 * in Jenkins pipelines. Supports both Kubernetes Auth and AppRole
 * authentication methods.
 *
 * Usage:
 * @Library('fawkes-pipeline-library') _
 *
 * // Method 1: Using withVaultSecrets block
 * vaultSecrets.withVaultSecrets([
 *     [path: 'secret/data/fawkes/cicd/jenkins', envVars: [
 *         [vaultKey: 'github_token', envVar: 'GITHUB_TOKEN'],
 *         [vaultKey: 'docker_password', envVar: 'DOCKER_PASS']
 *     ]]
 * ]) {
 *     sh 'docker login -u user -p $DOCKER_PASS registry.example.com'
 * }
 *
 * // Method 2: Get individual secret
 * def token = vaultSecrets.getSecret('secret/data/fawkes/cicd/jenkins', 'github_token')
 *
 * @author Fawkes Platform Team
 */

/**
 * Configuration for Vault connection
 */
def getVaultConfig() {
    return [
        vaultUrl: env.VAULT_ADDR ?: 'http://vault.vault.svc:8200',
        vaultNamespace: env.VAULT_NAMESPACE ?: '',
        authMethod: env.VAULT_AUTH_METHOD ?: 'kubernetes',
        kubernetesRole: env.VAULT_K8S_ROLE ?: 'jenkins',
        kubernetesMountPath: env.VAULT_K8S_MOUNT_PATH ?: 'kubernetes',
        appRoleCredentialId: env.VAULT_APPROLE_CREDENTIAL_ID ?: 'vault-approle',
        tokenCredentialId: env.VAULT_TOKEN_CREDENTIAL_ID ?: 'vault-token'
    ]
}

/**
 * Execute a closure with Vault secrets injected as environment variables
 *
 * @param secretMappings List of secret mappings with path and envVars
 * @param body The closure to execute with secrets available
 *
 * Example secretMappings:
 * [
 *     [path: 'secret/data/fawkes/cicd/jenkins', envVars: [
 *         [vaultKey: 'github_token', envVar: 'GITHUB_TOKEN'],
 *         [vaultKey: 'docker_password', envVar: 'DOCKER_PASS']
 *     ]]
 * ]
 */
def withVaultSecrets(List secretMappings, Closure body) {
    def config = getVaultConfig()

    // Convert our format to the Vault plugin format
    def vaultSecrets = secretMappings.collect { mapping ->
        [
            path: mapping.path,
            secretValues: mapping.envVars.collect { ev ->
                [vaultKey: ev.vaultKey, envVar: ev.envVar, isRequired: ev.isRequired ?: true]
            }
        ]
    }

    // Use the HashiCorp Vault plugin if available
    try {
        // NOTE: skipSslVerification should be false in production environments.
        // Set VAULT_SKIP_SSL_VERIFY=false in production to enforce TLS verification.
        def skipSsl = env.VAULT_SKIP_SSL_VERIFY?.toBoolean() ?: false
        withVault(
            configuration: [
                vaultUrl: config.vaultUrl,
                vaultNamespace: config.vaultNamespace,
                vaultCredentialId: config.tokenCredentialId,
                skipSslVerification: skipSsl,
                timeout: 60
            ],
            vaultSecrets: vaultSecrets
        ) {
            body()
        }
    } catch (NoSuchMethodError e) {
        // Fallback to manual secret retrieval if plugin not available
        echo "Vault plugin not available, using manual secret retrieval"
        withManualVaultSecrets(secretMappings, body)
    }
}

/**
 * Manual secret retrieval fallback when Vault plugin is not available
 */
def withManualVaultSecrets(List secretMappings, Closure body) {
    def config = getVaultConfig()
    def envVarMap = [:]

    // Get Vault token via Kubernetes auth
    def token = getKubernetesAuthToken(config)

    secretMappings.each { mapping ->
        def secrets = readSecretFromVault(config.vaultUrl, token, mapping.path)
        mapping.envVars.each { ev ->
            def value = secrets?.data?.data?.(ev.vaultKey)
            if (value) {
                envVarMap[ev.envVar] = value
            } else if (ev.isRequired != false) {
                error "Required secret key '${ev.vaultKey}' not found at path '${mapping.path}'"
            }
        }
    }

    // Inject environment variables
    withEnv(envVarMap.collect { k, v -> "${k}=${v}" }) {
        body()
    }
}

/**
 * Get a single secret value from Vault
 *
 * @param path The Vault secret path (e.g., 'secret/data/fawkes/cicd/jenkins')
 * @param key The key within the secret to retrieve
 * @return The secret value
 */
def getSecret(String path, String key) {
    def config = getVaultConfig()
    def token = getKubernetesAuthToken(config)
    def secrets = readSecretFromVault(config.vaultUrl, token, path)

    def value = secrets?.data?.data?.(key)
    if (!value) {
        error "Secret key '${key}' not found at path '${path}'"
    }
    return value
}

/**
 * Get all secrets from a Vault path as a map
 *
 * @param path The Vault secret path
 * @return Map of secret key-value pairs
 */
def getSecrets(String path) {
    def config = getVaultConfig()
    def token = getKubernetesAuthToken(config)
    def secrets = readSecretFromVault(config.vaultUrl, token, path)

    return secrets?.data?.data ?: [:]
}

/**
 * Authenticate with Vault using Kubernetes service account
 */
def getKubernetesAuthToken(Map config) {
    // Read the service account token from the pod
    def jwt = ''
    try {
        jwt = readFile('/var/run/secrets/kubernetes.io/serviceaccount/token').trim()
    } catch (Exception e) {
        error "Failed to read Kubernetes service account token: ${e.message}"
    }

    // Authenticate with Vault
    def authUrl = "${config.vaultUrl}/v1/auth/${config.kubernetesMountPath}/login"

    def response = httpRequest(
        url: authUrl,
        httpMode: 'POST',
        contentType: 'APPLICATION_JSON',
        requestBody: """
        {
            "role": "${config.kubernetesRole}",
            "jwt": "${jwt}"
        }
        """,
        validResponseCodes: '200:299',
        quiet: true
    )

    def authResult = readJSON(text: response.content)
    return authResult.auth.client_token
}

/**
 * Read a secret from Vault using the Vault HTTP API
 */
def readSecretFromVault(String vaultUrl, String token, String path) {
    def secretUrl = "${vaultUrl}/v1/${path}"

    def response = httpRequest(
        url: secretUrl,
        httpMode: 'GET',
        customHeaders: [[name: 'X-Vault-Token', value: token, maskValue: true]],
        validResponseCodes: '200:299',
        quiet: true
    )

    return readJSON(text: response.content)
}

/**
 * Write a secret to Vault (for CI/CD operations like rotating credentials)
 *
 * @param path The Vault secret path
 * @param data Map of key-value pairs to write
 */
def writeSecret(String path, Map data) {
    def config = getVaultConfig()
    def token = getKubernetesAuthToken(config)
    def secretUrl = "${config.vaultUrl}/v1/${path}"

    def requestBody = [data: data]

    httpRequest(
        url: secretUrl,
        httpMode: 'POST',
        contentType: 'APPLICATION_JSON',
        customHeaders: [[name: 'X-Vault-Token', value: token, maskValue: true]],
        requestBody: groovy.json.JsonOutput.toJson(requestBody),
        validResponseCodes: '200:204',
        quiet: true
    )

    echo "Secret written to ${path}"
}

/**
 * Check if Vault is available and the Jenkins role is properly configured
 */
def healthCheck() {
    def config = getVaultConfig()

    try {
        // Check Vault health
        def healthUrl = "${config.vaultUrl}/v1/sys/health"
        def response = httpRequest(
            url: healthUrl,
            httpMode: 'GET',
            validResponseCodes: '200,429,472,473,501,503',
            quiet: true
        )

        def health = readJSON(text: response.content)

        if (health.sealed) {
            error "Vault is sealed. Please unseal Vault before proceeding."
        }

        if (!health.initialized) {
            error "Vault is not initialized. Please initialize Vault first."
        }

        // Try to authenticate
        def token = getKubernetesAuthToken(config)
        echo "✅ Vault health check passed. Connection established."
        return true

    } catch (Exception e) {
        echo "❌ Vault health check failed: ${e.message}"
        return false
    }
}

/**
 * Get database credentials from Vault dynamic secrets engine
 *
 * @param role The database role to use
 * @param dbMountPath The mount path for the database engine (default: 'database')
 * @return Map with 'username' and 'password' keys
 */
def getDatabaseCredentials(String role, String dbMountPath = 'database') {
    def config = getVaultConfig()
    def token = getKubernetesAuthToken(config)
    def credsUrl = "${config.vaultUrl}/v1/${dbMountPath}/creds/${role}"

    def response = httpRequest(
        url: credsUrl,
        httpMode: 'GET',
        customHeaders: [[name: 'X-Vault-Token', value: token, maskValue: true]],
        validResponseCodes: '200',
        quiet: true
    )

    def creds = readJSON(text: response.content)

    return [
        username: creds.data.username,
        password: creds.data.password,
        leaseId: creds.lease_id,
        leaseDuration: creds.lease_duration
    ]
}

/**
 * Convenience method for common CI/CD secrets
 *
 * Returns a map with common secrets used in CI/CD pipelines:
 * - GITHUB_TOKEN
 * - DOCKER_USERNAME
 * - DOCKER_PASSWORD
 * - SONAR_TOKEN
 */
def getCICDSecrets() {
    return getSecrets('secret/data/fawkes/cicd/jenkins')
}

/**
 * Get Docker registry credentials for pushing images
 *
 * @return Map with 'username' and 'password' keys
 */
def getDockerCredentials() {
    def secrets = getSecrets('secret/data/fawkes/shared/docker-registry')
    return [
        username: secrets.username,
        password: secrets.password,
        registry: secrets.registry ?: 'harbor.fawkes.local'
    ]
}

/**
 * Get GitHub token for API operations
 *
 * @return The GitHub token
 */
def getGitHubToken() {
    return getSecret('secret/data/fawkes/shared/github', 'token')
}

return this
