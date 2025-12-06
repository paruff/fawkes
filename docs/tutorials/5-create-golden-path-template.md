---
title: Create a Golden Path Template
description: Extend the Fawkes platform by creating a Backstage software template
---

# Create a Golden Path Template

**Time to Complete**: 30-35 minutes  
**Goal**: Create a Backstage software template that encodes best practices and enables self-service application creation.

## What You'll Learn

By the end of this tutorial, you will have:

1. ✅ Created a custom Backstage software template
2. ✅ Encoded Fawkes best practices (Buildpacks, Vault, Tracing) in the template
3. ✅ Published the template to your Backstage catalog
4. ✅ Used the template to scaffold a new service
5. ✅ Understood how templates enable platform self-service

## Prerequisites

Before you begin, ensure you have:

- [ ] Completed tutorials 1-4 (understanding of Fawkes workflows)
- [ ] Access to Backstage UI (typically at `https://backstage.fawkes.yourdomain.com`)
- [ ] A GitHub account with permission to create repositories
- [ ] `cookiecutter` installed (`pip install cookiecutter` or `brew install cookiecutter`)
- [ ] Understanding of YAML and basic templating

!!! info "What is a Golden Path?"
    A "Golden Path" is a supported, opinionated, well-documented way to build and deploy software. It reduces cognitive load by providing sensible defaults while still allowing customization when needed.

## Step 1: Understand Backstage Templates

Backstage templates use a declarative format to scaffold new projects.

1. Navigate to Backstage and click **Create**.

2. Browse the existing templates:
   - What information do they collect?
   - What files do they generate?
   - How do they integrate with the platform?

3. Key components of a template:
   - **Parameters**: Questions to ask the user (service name, owner, etc.)
   - **Steps**: Actions to perform (fetch skeleton, publish to GitHub)
   - **Output**: Links to the created resources

!!! info "Template Philosophy"
    Templates should make it easy to do the right thing and hard to do the wrong thing. Embed security, observability, and compliance by default.

!!! success "Checkpoint"
    You understand what Backstage templates do and how they work.

## Step 2: Create Template Repository Structure

Let's create a template for Node.js services that includes all Fawkes best practices.

1. Create a new directory for your template:
   ```bash
   mkdir fawkes-nodejs-template
   cd fawkes-nodejs-template
   ```

2. Create the directory structure:
   ```bash
   mkdir -p skeleton
   mkdir -p skeleton/k8s
   mkdir -p skeleton/.github/workflows
   ```

3. Initialize a git repository:
   ```bash
   git init
   ```

4. Create a `template.yaml` at the root:
   ```yaml
   apiVersion: scaffolder.backstage.io/v1beta3
   kind: Template
   metadata:
     name: fawkes-nodejs-service
     title: Fawkes Node.js Service
     description: Create a production-ready Node.js service with Buildpacks, Vault, and Tracing
     tags:
       - nodejs
       - fawkes
       - recommended
   spec:
     owner: group:platform-team
     type: service
     
     parameters:
       - title: Service Information
         required:
           - component_id
           - owner
         properties:
           component_id:
             title: Name
             type: string
             description: Unique name for this service (lowercase, hyphens only)
             pattern: '^[a-z0-9-]+$'
             ui:autofocus: true
           description:
             title: Description
             type: string
             description: What does this service do?
           owner:
             title: Owner
             type: string
             description: Team responsible for this service
             ui:field: OwnerPicker
             ui:options:
               catalogFilter:
                 kind: Group
       
       - title: Configuration
         required:
           - port
         properties:
           port:
             title: HTTP Port
             type: number
             default: 8080
             description: Port the service listens on
           enable_tracing:
             title: Enable Distributed Tracing
             type: boolean
             default: true
             description: Instrument with OpenTelemetry
           enable_vault:
             title: Enable Vault Secrets
             type: boolean
             default: true
             description: Use HashiCorp Vault for secrets
       
       - title: Repository
         required:
           - repoUrl
         properties:
           repoUrl:
             title: Repository Location
             type: string
             ui:field: RepoUrlPicker
             ui:options:
               allowedHosts:
                 - github.com

     steps:
       - id: fetch
         name: Fetch Skeleton
         action: fetch:template
         input:
           url: ./skeleton
           values:
             component_id: ${{ parameters.component_id }}
             description: ${{ parameters.description }}
             owner: ${{ parameters.owner }}
             port: ${{ parameters.port }}
             enable_tracing: ${{ parameters.enable_tracing }}
             enable_vault: ${{ parameters.enable_vault }}

       - id: publish
         name: Publish to GitHub
         action: publish:github
         input:
           allowedHosts:
             - github.com
           description: ${{ parameters.description }}
           repoUrl: ${{ parameters.repoUrl }}
           defaultBranch: main

       - id: register
         name: Register Component
         action: catalog:register
         input:
           repoContentsUrl: ${{ steps.publish.output.repoContentsUrl }}
           catalogInfoPath: '/catalog-info.yaml'

       - id: create-argocd-app
         name: Create ArgoCD Application
         action: fawkes:create-argocd-app
         input:
           name: ${{ parameters.component_id }}
           namespace: ${{ parameters.component_id }}
           repoUrl: ${{ steps.publish.output.remoteUrl }}

     output:
       links:
         - title: Repository
           url: ${{ steps.publish.output.remoteUrl }}
         - title: View in Catalog
           icon: catalog
           entityRef: ${{ steps.register.output.entityRef }}
         - title: ArgoCD
           url: https://argocd.fawkes.yourdomain.com/applications/${{ parameters.component_id }}
   ```

!!! success "Checkpoint"
    Template metadata and parameters are defined.

## Step 3: Create Skeleton Files

Now let's create the actual files that will be generated.

1. Create `skeleton/catalog-info.yaml`:
   ```yaml
   apiVersion: backstage.io/v1alpha1
   kind: Component
   metadata:
     name: ${{ values.component_id }}
     description: ${{ values.description }}
     annotations:
       github.com/project-slug: ${{ values.repoUrl | parseRepoUrl | pick('owner') }}/${{ values.component_id }}
       argocd/app-name: ${{ values.component_id }}
     tags:
       - nodejs
       - fawkes
   spec:
     type: service
     lifecycle: experimental
     owner: ${{ values.owner }}
     system: fawkes-platform
   ```

2. Create `skeleton/package.json`:
   ```json
   {
     "name": "${{ values.component_id }}",
     "version": "1.0.0",
     "description": "${{ values.description }}",
     "main": "server.js",
     "scripts": {
       "start": "node server.js",
       "test": "echo 'No tests yet' && exit 0"
     },
     "dependencies": {
       "express": "^4.18.2"{% if values.enable_tracing %},
       "@opentelemetry/api": "^1.4.1",
       "@opentelemetry/sdk-node": "^0.41.0",
       "@opentelemetry/auto-instrumentations-node": "^0.39.1",
       "@opentelemetry/exporter-trace-otlp-http": "^0.41.0"{% endif %}{% if values.enable_vault %},
       "node-vault": "^0.10.2"{% endif %}
     }
   }
   ```

3. Create `skeleton/server.js`:
   ```javascript
   {% if values.enable_tracing %}// Load tracing before anything else
   require('./tracing');
   {% endif %}
   const express = require('express');
   {% if values.enable_vault %}const { initVaultClient, getSecret } = require('./vault-client');
   {% endif %}
   const app = express();
   const PORT = process.env.PORT || ${{ values.port }};

   {% if values.enable_vault %}// Store Vault client and secrets
   let vaultClient;
   let secrets = {};

   // Initialize Vault and load secrets
   const initializeSecrets = async () => {
     try {
       vaultClient = await initVaultClient();
       console.log('Vault initialized');
       // Add your secret paths here
       // secrets.mySecret = await getSecret(vaultClient, '${{ values.component_id }}/config');
       return true;
     } catch (error) {
       console.error('Failed to initialize secrets:', error);
       return false;
     }
   };
   {% endif %}
   app.get('/', (req, res) => {
     res.json({
       service: '${{ values.component_id }}',
       description: '${{ values.description }}',
       version: '1.0.0',
       timestamp: new Date().toISOString()
     });
   });

   app.get('/health', (req, res) => {
     res.json({ status: 'healthy' });
   });

   // Start server
   (async () => {
     {% if values.enable_vault %}const secretsLoaded = await initializeSecrets();
     if (!secretsLoaded) {
       console.warn('Secrets not loaded, but starting anyway...');
     }
     {% endif %}
     app.listen(PORT, '0.0.0.0', () => {
       console.log(`${{ values.component_id }} listening on port ${PORT}`);
     });
   })();
   ```

4. If tracing is enabled, create `skeleton/tracing.js`:
   ```javascript
   {% if values.enable_tracing %}const { NodeSDK } = require('@opentelemetry/sdk-node');
   const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
   const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
   const { Resource } = require('@opentelemetry/resources');
   const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

   const traceExporter = new OTLPTraceExporter({
     url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://tempo.fawkes-platform.svc.cluster.local:4318/v1/traces',
   });

   const resource = new Resource({
     [SemanticResourceAttributes.SERVICE_NAME]: '${{ values.component_id }}',
     [SemanticResourceAttributes.SERVICE_VERSION]: '1.0.0',
   });

   const sdk = new NodeSDK({
     resource,
     traceExporter,
     instrumentations: [getNodeAutoInstrumentations()],
   });

   sdk.start();
   console.log('OpenTelemetry tracing initialized');
   {% endif %}
   ```

5. If Vault is enabled, create `skeleton/vault-client.js`:
   ```javascript
   {% if values.enable_vault %}const vault = require('node-vault');
   const fs = require('fs');

   const getK8sToken = () => {
     try {
       return fs.readFileSync('/var/run/secrets/kubernetes.io/serviceaccount/token', 'utf8');
     } catch (error) {
       console.error('Failed to read Kubernetes token:', error);
       return null;
     }
   };

   const initVaultClient = async () => {
     const vaultClient = vault({
       apiVersion: 'v1',
       endpoint: process.env.VAULT_ADDR || 'http://vault.fawkes-platform.svc.cluster.local:8200',
     });

     const k8sToken = getK8sToken();
     if (!k8sToken) {
       throw new Error('No Kubernetes token available');
     }

     const result = await vaultClient.kubernetesLogin({
       role: '${{ values.component_id }}',
       jwt: k8sToken,
     });

     vaultClient.token = result.auth.client_token;
     return vaultClient;
   };

   const getSecret = async (vaultClient, path) => {
     const secret = await vaultClient.read(`secret/data/${path}`);
     return secret.data.data;
   };

   module.exports = { initVaultClient, getSecret };
   {% endif %}
   ```

!!! success "Checkpoint"
    Skeleton application files are created with conditional features.

## Step 4: Create Kubernetes Manifests

1. Create `skeleton/k8s/deployment.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: ${{ values.component_id }}
     namespace: ${{ values.component_id }}
     labels:
       app: ${{ values.component_id }}
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: ${{ values.component_id }}
     template:
       metadata:
         labels:
           app: ${{ values.component_id }}
         annotations:
           buildpack.io/builder: "paketobuildpacks/builder:base"
       spec:
         {% if values.enable_vault %}serviceAccountName: ${{ values.component_id }}
         {% endif %}containers:
         - name: ${{ values.component_id }}
           image: REPLACE_WITH_YOUR_IMAGE
           ports:
           - containerPort: ${{ values.port }}
             name: http
           env:
           - name: PORT
             value: "${{ values.port }}"
           {% if values.enable_vault %}- name: VAULT_ADDR
             value: "http://vault.fawkes-platform.svc.cluster.local:8200"
           {% endif %}{% if values.enable_tracing %}- name: OTEL_SERVICE_NAME
             value: "${{ values.component_id }}"
           - name: OTEL_EXPORTER_OTLP_ENDPOINT
             value: "http://tempo.fawkes-platform.svc.cluster.local:4318/v1/traces"
           {% endif %}livenessProbe:
             httpGet:
               path: /health
               port: ${{ values.port }}
             initialDelaySeconds: 10
             periodSeconds: 10
           readinessProbe:
             httpGet:
               path: /health
               port: ${{ values.port }}
             initialDelaySeconds: 5
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

2. Create other Kubernetes manifests (service, ingress, serviceaccount if needed).

3. Create `skeleton/README.md`:
   ```markdown
   # ${{ values.component_id }}

   ${{ values.description }}

   ## Quick Start

   ```bash
   npm install
   npm start
   ```

   ## Building with Buildpacks

   ```bash
   pack build ${{ values.component_id }}:latest --builder paketobuildpacks/builder:base
   ```

   ## Deployment

   This service is deployed using ArgoCD. Push to `main` branch to trigger deployment.

   ## Features

   - ✅ Express.js REST API
   {% if values.enable_tracing %}- ✅ OpenTelemetry distributed tracing
   {% endif %}{% if values.enable_vault %}- ✅ HashiCorp Vault secret management
   {% endif %}- ✅ Cloud Native Buildpacks
   - ✅ Kubernetes-ready with health checks
   - ✅ Security best practices (non-root, read-only filesystem)

   ## Owner

   Team: ${{ values.owner }}
   ```

!!! success "Checkpoint"
    Complete skeleton with Kubernetes manifests and README.

## Step 5: Publish the Template

1. Commit all files:
   ```bash
   git add .
   git commit -m "Initial Fawkes Node.js template"
   ```

2. Create a GitHub repository:
   - Go to github.com
   - Create a new repository: `fawkes-nodejs-template`
   - Push your code:
     ```bash
     git remote add origin https://github.com/YOUR-ORG/fawkes-nodejs-template.git
     git branch -M main
     git push -u origin main
     ```

3. Register the template in Backstage:
   - Navigate to Backstage UI
   - Click **Create** → **Register Existing Component**
   - Enter: `https://github.com/YOUR-ORG/fawkes-nodejs-template/blob/main/template.yaml`
   - Click **Analyze** → **Import**

!!! success "Checkpoint"
    Your template is published and available in Backstage!

## Step 6: Use Your Template

Let's create a new service using your template.

1. In Backstage, click **Create**.

2. Find and select **Fawkes Node.js Service**.

3. Fill in the form:
   - Name: `my-awesome-service`
   - Description: `A service created from the Golden Path template`
   - Owner: Select your team
   - Enable Tracing: ✅ Yes
   - Enable Vault: ✅ Yes
   - Repository: Choose location

4. Click **Create**.

5. Watch Backstage:
   - Fetch the skeleton
   - Substitute variables
   - Create GitHub repository
   - Register in catalog
   - Create ArgoCD application

6. Navigate to the newly created repository and service in the catalog!

!!! success "Checkpoint"
    You've used your Golden Path template to create a production-ready service in minutes!

## What You've Accomplished

Congratulations! You've successfully:

- ✅ Created a Backstage software template
- ✅ Encoded Fawkes best practices (Buildpacks, Vault, Tracing)
- ✅ Published the template to Backstage
- ✅ Used the template to scaffold a new service
- ✅ Enabled self-service platform adoption

## Impact of Golden Paths

By creating this template, you've:

1. **Reduced Onboarding Time** - New services in minutes, not days
2. **Enforced Best Practices** - Security, observability by default
3. **Improved Consistency** - All services follow the same patterns
4. **Enabled Self-Service** - Developers don't need platform expertise
5. **Accelerated DORA Metrics** - Faster deployment frequency

## What's Next?

1. **[Measure DORA Metrics](6-measure-dora-metrics.md)** - See the impact of your Golden Path
2. **Extend the Template** - Add database setup, message queues, etc.
3. **Create More Templates** - Python, Java, Go, Frontend, etc.

## Learn More

- **[Backstage Template Documentation](https://backstage.io/docs/features/software-templates/)** - Official Backstage docs
- **[Golden Path Usage Guide](../golden-path-usage.md)** - How to use Fawkes Golden Paths

## Feedback

Share your Golden Path template with the community! Post in [Fawkes Community Mattermost](https://fawkes-community.mattermost.com)!
