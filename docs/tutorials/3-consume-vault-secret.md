---
title: Consume Vault Secrets
description: Secure your application with HashiCorp Vault for compliant secret management
---

# Consume Vault Secrets

**Time to Complete**: 30 minutes
**Goal**: Replace hardcoded configuration with secrets managed by HashiCorp Vault, following the Fawkes security best practices.

## What You'll Learn

By the end of this tutorial, you will have:

1. ✅ Stored a secret in HashiCorp Vault
2. ✅ Configured your application to authenticate with Vault using Kubernetes Service Account
3. ✅ Retrieved secrets at runtime using the Vault Agent pattern
4. ✅ Rotated a secret and verified your application picks up the new value

## Prerequisites

Before you begin, ensure you have:

- [ ] Completed [Tutorial 1: Deploy Your First Service](1-deploy-first-service.md)
- [ ] Your `hello-fawkes` service running and accessible
- [ ] Access to HashiCorp Vault (typically at `https://vault.127.0.0.1.nip.io`)
- [ ] `vault` CLI installed on your workstation
- [ ] Basic understanding of Kubernetes secrets (helpful but not required)

!!! info "Why Vault?"
Storing secrets in code, environment variables, or ConfigMaps is insecure. Vault provides centralized secret management with audit logs, access control, and rotation capabilities. [Learn more about Zero Trust Security](../explanation/security/zero-trust-model.md).

## Step 1: Authenticate to Vault

First, let's verify you can access Vault.

1. Set the Vault address:

   ```bash
   export VAULT_ADDR="https://vault.127.0.0.1.nip.io"
   ```

2. Log in to Vault (use the token provided by your platform team):

   ```bash
   vault login
   ```

   Enter your token when prompted.

3. Verify authentication:

   ```bash
   vault token lookup
   ```

   You should see details about your token, including policies and permissions.

!!! tip "Vault Token Management"
In production, individual users don't use root tokens. Instead, applications authenticate using Kubernetes Service Accounts. We'll set that up later in this tutorial.

!!! success "Checkpoint"
You can authenticate to Vault and are ready to create secrets.

## Step 2: Create a Secret in Vault

Let's create a database connection secret for our application.

1. Enable the KV v2 secrets engine if not already enabled:

   ```bash
   vault secrets enable -path=secret kv-v2
   ```

   If it's already enabled, you'll see an error - that's okay!

2. Create a secret for your application:

   ```bash
   vault kv put secret/hello-fawkes/database \
     host="postgres.database.svc.cluster.local" \
     port="5432" \
     username="hello_fawkes_user" \
     password="SuperSecretPassword123!"
   ```

3. Verify the secret was created:

   ```bash
   vault kv get secret/hello-fawkes/database
   ```

   You should see your secret values:

   ```
   ====== Data ======
   Key         Value
   ---         -----
   host        postgres.database.svc.cluster.local
   port        5432
   username    hello_fawkes_user
   password    SuperSecretPassword123!
   ```

4. Create another secret for API keys:
   ```bash
   vault kv put secret/hello-fawkes/api \
     api_key="fawkes-api-key-12345" \
     api_secret="fawkes-secret-67890"
   ```

!!! success "Checkpoint"
Your secrets are stored in Vault and can be accessed programmatically.

## Step 3: Configure Vault Kubernetes Authentication

For your application to access Vault, we need to set up Kubernetes authentication.

1. Enable Kubernetes auth method (if not already enabled):

   ```bash
   vault auth enable kubernetes
   ```

2. Configure the Kubernetes auth method:

   ```bash
   vault write auth/kubernetes/config \
     kubernetes_host="https://kubernetes.default.svc:443"
   ```

3. Create a policy that allows reading your secrets:

   Create a file `hello-fawkes-policy.hcl`:

   ```hcl
   # Allow reading secrets for hello-fawkes
   path "secret/data/hello-fawkes/*" {
     capabilities = ["read", "list"]
   }

   # Allow reading secret metadata
   path "secret/metadata/hello-fawkes/*" {
     capabilities = ["read", "list"]
   }
   ```

4. Upload the policy to Vault:

   ```bash
   vault policy write hello-fawkes hello-fawkes-policy.hcl
   ```

5. Create a Vault role that maps to your Kubernetes service account:
   ```bash
   vault write auth/kubernetes/role/hello-fawkes \
     bound_service_account_names=hello-fawkes \
     bound_service_account_namespaces=my-first-app \
     policies=hello-fawkes \
     ttl=24h
   ```

!!! info "What Did We Just Do?"
We created a Vault role that trusts the `hello-fawkes` ServiceAccount in the `my-first-app` namespace. This allows pods using that ServiceAccount to authenticate to Vault and read secrets according to the `hello-fawkes` policy.

!!! success "Checkpoint"
Kubernetes authentication is configured, allowing your application to securely access Vault.

## Step 4: Create a Kubernetes Service Account

Your application needs a ServiceAccount to authenticate with Vault.

1. Create `k8s/serviceaccount.yaml`:

   ```yaml
   apiVersion: v1
   kind: ServiceAccount
   metadata:
     name: hello-fawkes
     namespace: my-first-app
   ```

2. Update `k8s/deployment.yaml` to use the ServiceAccount:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     labels:
       app: hello-fawkes
       version: v3
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: hello-fawkes
     template:
       metadata:
         labels:
           app: hello-fawkes
           version: v3
       spec:
         serviceAccountName: hello-fawkes # Add this line
         containers:
           - name: hello-fawkes
             image: YOUR-USERNAME/hello-fawkes:v3.0.0
             # ... rest of container spec
   ```

3. Apply the ServiceAccount:
   ```bash
   kubectl apply -f k8s/serviceaccount.yaml
   ```

!!! success "Checkpoint"
Your application now has a ServiceAccount that can authenticate with Vault.

## Step 5: Update Application to Use Vault

Now let's modify our application to fetch secrets from Vault at runtime.

1. Install the Vault client library:

   ```bash
   npm install --save node-vault
   ```

2. Create a new file `vault-client.js`:

   ```javascript
   const vault = require("node-vault");
   const fs = require("fs");

   // Read the service account token
   const getK8sToken = () => {
     try {
       return fs.readFileSync("/var/run/secrets/kubernetes.io/serviceaccount/token", "utf8");
     } catch (error) {
       console.error("Failed to read Kubernetes token:", error);
       return null;
     }
   };

   // Initialize Vault client
   const initVaultClient = async () => {
     const vaultClient = vault({
       apiVersion: "v1",
       endpoint: process.env.VAULT_ADDR || "http://vault.fawkes-platform.svc.cluster.local:8200",
     });

     // Authenticate using Kubernetes service account
     const k8sToken = getK8sToken();
     if (!k8sToken) {
       throw new Error("No Kubernetes token available");
     }

     try {
       const result = await vaultClient.kubernetesLogin({
         role: "hello-fawkes",
         jwt: k8sToken,
       });

       console.log("Successfully authenticated to Vault");

       // Set the client token for future requests
       vaultClient.token = result.auth.client_token;

       return vaultClient;
     } catch (error) {
       console.error("Vault authentication failed:", error);
       throw error;
     }
   };

   // Get a secret from Vault
   const getSecret = async (vaultClient, path) => {
     try {
       const secret = await vaultClient.read(`secret/data/${path}`);
       return secret.data.data; // KV v2 nests data twice
     } catch (error) {
       console.error(`Failed to read secret ${path}:`, error);
       throw error;
     }
   };

   module.exports = {
     initVaultClient,
     getSecret,
   };
   ```

3. Update `server.js` to use Vault secrets:

   ```javascript
   // Load tracing first
   require("./tracing");

   const express = require("express");
   const { initVaultClient, getSecret } = require("./vault-client");

   const app = express();
   const PORT = process.env.PORT || 8080;

   // Store Vault client and secrets
   let vaultClient;
   let secrets = {
     database: null,
     api: null,
   };

   // Initialize Vault and load secrets
   const initializeSecrets = async () => {
     try {
       vaultClient = await initVaultClient();

       // Load database secrets
       secrets.database = await getSecret(vaultClient, "hello-fawkes/database");
       console.log("Database secrets loaded");

       // Load API secrets
       secrets.api = await getSecret(vaultClient, "hello-fawkes/api");
       console.log("API secrets loaded");

       return true;
     } catch (error) {
       console.error("Failed to initialize secrets:", error);
       return false;
     }
   };

   app.get("/", (req, res) => {
     res.json({
       message: "Hello from Fawkes!",
       timestamp: new Date().toISOString(),
       version: "3.0.0",
       tracing: "enabled",
       secrets: "managed by Vault",
     });
   });

   app.get("/health", (req, res) => {
     const healthy = secrets.database !== null && secrets.api !== null;
     res.status(healthy ? 200 : 503).json({
       status: healthy ? "healthy" : "unhealthy",
       secretsLoaded: healthy,
     });
   });

   // Endpoint that uses database secrets
   app.get("/api/data", async (req, res) => {
     if (!secrets.database) {
       return res.status(503).json({ error: "Database secrets not loaded" });
     }

     // In a real app, you'd use these to connect to the database
     const dbConfig = {
       host: secrets.database.host,
       port: secrets.database.port,
       username: secrets.database.username,
       // Never log passwords!
     };

     res.json({
       message: "Database connection configured",
       host: dbConfig.host,
       port: dbConfig.port,
       user: dbConfig.username,
     });
   });

   // Endpoint to trigger secret refresh
   app.post("/api/refresh-secrets", async (req, res) => {
     console.log("Refreshing secrets from Vault...");
     const success = await initializeSecrets();
     res.json({
       success,
       message: success ? "Secrets refreshed" : "Failed to refresh secrets",
     });
   });

   // Start server after loading secrets
   (async () => {
     const secretsLoaded = await initializeSecrets();

     if (!secretsLoaded) {
       console.error("Failed to load secrets. Server will start but may not function correctly.");
     }

     app.listen(PORT, "0.0.0.0", () => {
       console.log(`Server running on port ${PORT}`);
     });
   })();
   ```

4. Commit the changes:
   ```bash
   git add vault-client.js server.js package.json package-lock.json
   git commit -m "Add Vault secret management"
   ```

!!! success "Checkpoint"
Your application now fetches secrets from Vault instead of using hardcoded values!

## Step 6: Update Deployment Configuration

Add environment variables for Vault connectivity.

1. Update `k8s/deployment.yaml`:

   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     labels:
       app: hello-fawkes
       version: v3
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: hello-fawkes
     template:
       metadata:
         labels:
           app: hello-fawkes
           version: v3
       spec:
         serviceAccountName: hello-fawkes
         containers:
           - name: hello-fawkes
             image: YOUR-USERNAME/hello-fawkes:v3.0.0
             ports:
               - containerPort: 8080
                 name: http
             env:
               - name: PORT
                 value: "8080"
               - name: VAULT_ADDR
                 value: "http://vault.fawkes-platform.svc.cluster.local:8200"
               - name: OTEL_SERVICE_NAME
                 value: "hello-fawkes"
               - name: SERVICE_VERSION
                 value: "3.0.0"
               - name: ENVIRONMENT
                 value: "development"
               - name: OTEL_EXPORTER_OTLP_ENDPOINT
                 value: "http://tempo.fawkes-platform.svc.cluster.local:4318/v1/traces"
             livenessProbe:
               httpGet:
                 path: /health
                 port: 8080
               initialDelaySeconds: 15
               periodSeconds: 10
             readinessProbe:
               httpGet:
                 path: /health
                 port: 8080
               initialDelaySeconds: 10
               periodSeconds: 5
             resources:
               requests:
                 memory: "128Mi"
                 cpu: "100m"
               limits:
                 memory: "256Mi"
                 cpu: "200m"
             securityContext:
               runAsNonRoot: true
               runAsUser: 1000
               allowPrivilegeEscalation: false
               readOnlyRootFilesystem: true
   ```

2. Commit the changes:
   ```bash
   git add k8s/
   git commit -m "Configure Vault integration in deployment"
   ```

!!! success "Checkpoint"
Deployment is configured to connect to Vault using the ServiceAccount.

## Step 7: Deploy and Verify

Let's deploy the updated application and verify it can read secrets from Vault.

1. Build and push the new version:

   ```bash
   docker build -t YOUR-USERNAME/hello-fawkes:v3.0.0 .
   docker push YOUR-USERNAME/hello-fawkes:v3.0.0
   ```

2. Push to Git (ArgoCD will auto-sync):

   ```bash
   git push
   ```

3. Watch the deployment:

   ```bash
   kubectl rollout status deployment/hello-fawkes -n my-first-app
   ```

4. Check that secrets loaded successfully:

   ```bash
   kubectl logs -n my-first-app -l app=hello-fawkes | grep -i vault
   ```

   You should see:

   ```
   Successfully authenticated to Vault
   Database secrets loaded
   API secrets loaded
   ```

5. Test the health endpoint:

   ```bash
   curl https://hello-fawkes.127.0.0.1.nip.io/health
   ```

   Should return:

   ```json
   {
     "status": "healthy",
     "secretsLoaded": true
   }
   ```

6. Test the data endpoint that uses secrets:

   ```bash
   curl https://hello-fawkes.127.0.0.1.nip.io/api/data
   ```

   Should return database configuration from Vault:

   ```json
   {
     "message": "Database connection configured",
     "host": "postgres.database.svc.cluster.local",
     "port": "5432",
     "user": "hello_fawkes_user"
   }
   ```

!!! success "Checkpoint"
Your application is running and successfully retrieving secrets from Vault! 🎉

## Step 8: Rotate a Secret

Let's verify that secret rotation works by updating a secret in Vault and refreshing it in the application.

1. Update the database password in Vault:

   ```bash
   vault kv put secret/hello-fawkes/database \
     host="postgres.database.svc.cluster.local" \
     port="5432" \
     username="hello_fawkes_user" \
     password="NewRotatedPassword456!"
   ```

2. Verify the secret was updated:

   ```bash
   vault kv get secret/hello-fawkes/database
   ```

3. Trigger secret refresh in your application:

   ```bash
   curl -X POST https://hello-fawkes.127.0.0.1.nip.io/api/refresh-secrets
   ```

   Should return:

   ```json
   {
     "success": true,
     "message": "Secrets refreshed"
   }
   ```

4. Check the logs to verify the new secret was loaded:

   ```bash
   kubectl logs -n my-first-app -l app=hello-fawkes --tail=20
   ```

   You should see:

   ```
   Refreshing secrets from Vault...
   Database secrets loaded
   API secrets loaded
   ```

!!! info "Production Secret Rotation"
In production, you'd automate secret rotation using: - Vault's automatic rotation features - A sidecar that refreshes secrets periodically - Or External Secrets Operator for full automation

    See [How to Rotate Vault Secrets](../how-to/security/rotate-vault-secrets.md) for advanced patterns.

!!! success "Checkpoint"
You've successfully rotated a secret and verified your application picked up the new value!

## What You've Accomplished

Congratulations! You've successfully:

- ✅ Created and stored secrets in HashiCorp Vault
- ✅ Configured Kubernetes authentication for Vault
- ✅ Updated your application to fetch secrets at runtime
- ✅ Deployed with proper ServiceAccount permissions
- ✅ Rotated a secret and verified the update

## Best Practices You've Learned

1. **Never hardcode secrets** - Always use a secret management system
2. **Use Kubernetes ServiceAccounts** - Avoid using root tokens in applications
3. **Implement least privilege** - Create specific policies for each application
4. **Enable audit logging** - Vault logs all secret access
5. **Plan for rotation** - Design applications to handle secret updates gracefully

## What's Next?

Continue securing and enhancing your application:

1. **[Buildpack Migration](4-buildpack-migration.md)** - Automate secure container builds
2. **[Measure DORA Metrics](6-measure-dora-metrics.md)** - Track your security improvements
3. **[Zero Trust Security Model](../explanation/security/zero-trust-model.md)** - Understand the full security architecture

## Troubleshooting

### Application Can't Authenticate to Vault

```bash
# Check ServiceAccount exists
kubectl get serviceaccount hello-fawkes -n my-first-app

# Verify Vault role exists
vault read auth/kubernetes/role/hello-fawkes

# Check pod has ServiceAccount token mounted
kubectl exec -n my-first-app deployment/hello-fawkes -- \
  ls -la /var/run/secrets/kubernetes.io/serviceaccount/
```

### Secrets Not Loading

```bash
# Test Vault policy
vault token create -policy=hello-fawkes

# Check application logs
kubectl logs -n my-first-app -l app=hello-fawkes

# Verify secrets exist
vault kv get secret/hello-fawkes/database
```

### Permission Denied Errors

- Verify the policy allows `read` on `secret/data/hello-fawkes/*`
- Check that the role is bound to the correct ServiceAccount and namespace
- Ensure the Vault token hasn't expired

## Learn More

- **[Zero Trust Security Model](../explanation/security/zero-trust-model.md)** - Defense in depth with Vault, Kyverno, and Ingress
- **[How to Rotate Vault Secrets](../how-to/security/rotate-vault-secrets.md)** - Advanced rotation patterns
- **[Vault Documentation](https://www.vaultproject.io/docs)** - Official HashiCorp Vault docs

## Feedback

How was your experience with Vault integration? Share your thoughts in the [Fawkes Community Mattermost](https://fawkes-community.mattermost.com)!
