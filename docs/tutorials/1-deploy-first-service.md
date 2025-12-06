---
title: Deploy Your First Service
description: Get your first application running on Fawkes in under 30 minutes
---

# Deploy Your First Service

**Time to Complete**: 30 minutes  
**Goal**: Deploy a simple web service to the Fawkes platform and see it running, secured, and visible in Backstage.

## What You'll Learn

By the end of this tutorial, you will have:

1. ✅ Deployed a simple "Hello Fawkes" web service
2. ✅ Accessed your service through a secure ingress endpoint
3. ✅ Verified your service appears in the Backstage service catalog
4. ✅ Understood the basic Fawkes deployment workflow

## Prerequisites

Before you begin, ensure you have:

- [ ] Access to the Fawkes platform (ask your platform team for credentials)
- [ ] `kubectl` installed and configured to access the Fawkes cluster
- [ ] `git` installed on your workstation
- [ ] A GitHub account (for source code repository)
- [ ] Basic understanding of Kubernetes concepts (pods, deployments, services)

!!! tip "New to Kubernetes?"
    If you're unfamiliar with Kubernetes, don't worry! Follow along step-by-step. This tutorial is designed to work even if you don't understand every detail yet.

## Step 1: Verify Platform Access

First, let's confirm you can connect to the Fawkes cluster.

1. Check your kubectl context:
   ```bash
   kubectl config current-context
   ```
   
   You should see a context name containing "fawkes" or your cluster name.

2. Verify you can list namespaces:
   ```bash
   kubectl get namespaces
   ```
   
   You should see core Fawkes namespaces like `fawkes-platform`, `argocd`, `vault`, etc.

3. Check your assigned namespace:
   ```bash
   kubectl get namespace my-first-app
   ```
   
   If this returns an error, create the namespace:
   ```bash
   kubectl create namespace my-first-app
   ```

!!! success "Checkpoint"
    You should now have access to the Fawkes cluster and a namespace for your application.

## Step 2: Create Your Application Repository

We'll start with a simple Node.js application to demonstrate the deployment workflow.

1. Create a new directory for your application:
   ```bash
   mkdir hello-fawkes
   cd hello-fawkes
   ```

2. Initialize a git repository:
   ```bash
   git init
   ```

3. Create a simple Node.js application.

   Create `package.json`:
   ```json
   {
     "name": "hello-fawkes",
     "version": "1.0.0",
     "description": "My first Fawkes service",
     "main": "server.js",
     "scripts": {
       "start": "node server.js"
     },
     "dependencies": {
       "express": "^4.18.2"
     }
   }
   ```

4. Create `server.js`:
   ```javascript
   const express = require('express');
   const app = express();
   const PORT = process.env.PORT || 8080;

   app.get('/', (req, res) => {
     res.json({
       message: 'Hello from Fawkes!',
       timestamp: new Date().toISOString(),
       version: '1.0.0'
     });
   });

   app.get('/health', (req, res) => {
     res.json({ status: 'healthy' });
   });

   app.listen(PORT, '0.0.0.0', () => {
     console.log(`Server running on port ${PORT}`);
   });
   ```

5. Commit your code:
   ```bash
   git add .
   git commit -m "Initial hello-fawkes service"
   ```

6. Push to GitHub (create a repository first at github.com):
   ```bash
   git remote add origin https://github.com/YOUR-USERNAME/hello-fawkes.git
   git branch -M main
   git push -u origin main
   ```

!!! success "Checkpoint"
    You now have a simple web service ready to deploy, stored in a Git repository.

## Step 3: Create Kubernetes Manifests

Fawkes uses GitOps, which means your deployment configuration lives in Git alongside your code.

1. Create a `k8s/` directory in your project:
   ```bash
   mkdir -p k8s
   ```

2. Create `k8s/deployment.yaml`:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     labels:
       app: hello-fawkes
       version: v1
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: hello-fawkes
     template:
       metadata:
         labels:
           app: hello-fawkes
           version: v1
       spec:
         containers:
         - name: hello-fawkes
           image: YOUR-USERNAME/hello-fawkes:v1.0.0
           ports:
           - containerPort: 8080
             name: http
           env:
           - name: PORT
             value: "8080"
           livenessProbe:
             httpGet:
               path: /health
               port: 8080
             initialDelaySeconds: 10
             periodSeconds: 10
           readinessProbe:
             httpGet:
               path: /health
               port: 8080
             initialDelaySeconds: 5
             periodSeconds: 5
           resources:
             requests:
               memory: "64Mi"
               cpu: "100m"
             limits:
               memory: "128Mi"
               cpu: "200m"
           securityContext:
             runAsNonRoot: true
             runAsUser: 1000
             allowPrivilegeEscalation: false
             readOnlyRootFilesystem: true
   ```

3. Create `k8s/service.yaml`:
   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     labels:
       app: hello-fawkes
   spec:
     type: ClusterIP
     ports:
     - port: 80
       targetPort: 8080
       protocol: TCP
       name: http
     selector:
       app: hello-fawkes
   ```

4. Create `k8s/ingress.yaml`:
   ```yaml
   apiVersion: networking.k8s.io/v1
   kind: Ingress
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     annotations:
       cert-manager.io/cluster-issuer: letsencrypt-prod
   spec:
     ingressClassName: nginx
     tls:
     - hosts:
       - hello-fawkes.127.0.0.1.nip.io
       secretName: hello-fawkes-tls
     rules:
     - host: hello-fawkes.127.0.0.1.nip.io
       http:
         paths:
         - path: /
           pathType: Prefix
           backend:
             service:
               name: hello-fawkes
               port:
                 number: 80
   ```

!!! info "Why runAsNonRoot?"
    Notice the `securityContext` settings? Fawkes enforces security best practices. Running as non-root prevents privilege escalation attacks. [Learn more about Zero Trust Security](../explanation/security/zero-trust-model.md).

5. Commit the manifests:
   ```bash
   git add k8s/
   git commit -m "Add Kubernetes manifests"
   git push
   ```

!!! success "Checkpoint"
    Your application now has Kubernetes deployment manifests that follow Fawkes security policies.

## Step 4: Build and Push Container Image

Since we're not using Cloud Native Buildpacks in this first tutorial (that's Tutorial 4!), we'll use a simple Dockerfile.

1. Create a `Dockerfile`:
   ```dockerfile
   FROM node:18-alpine
   
   # Create app directory
   WORKDIR /app
   
   # Install dependencies
   COPY package*.json ./
   RUN npm ci --only=production
   
   # Copy app source
   COPY server.js ./
   
   # Create non-root user
   RUN addgroup -g 1000 appuser && \
       adduser -D -u 1000 -G appuser appuser && \
       chown -R appuser:appuser /app
   
   USER appuser
   
   EXPOSE 8080
   
   CMD ["npm", "start"]
   ```

2. Build the container image:
   ```bash
   docker build -t YOUR-USERNAME/hello-fawkes:v1.0.0 .
   ```

3. Push to a container registry (Docker Hub, GitHub Container Registry, etc.):
   ```bash
   docker login
   docker push YOUR-USERNAME/hello-fawkes:v1.0.0
   ```

4. Update the image reference in `k8s/deployment.yaml` if needed.

!!! success "Checkpoint"
    Your container image is now available in a registry and ready to be deployed.

## Step 5: Deploy with ArgoCD (GitOps Way)

Fawkes uses ArgoCD for GitOps-based deployments. This is the preferred method.

1. Create an ArgoCD Application manifest `argocd-app.yaml`:
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: hello-fawkes
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: https://github.com/YOUR-USERNAME/hello-fawkes.git
       targetRevision: main
       path: k8s
     destination:
       server: https://kubernetes.default.svc
       namespace: my-first-app
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
       - CreateNamespace=true
   ```

2. Apply the ArgoCD Application:
   ```bash
   kubectl apply -f argocd-app.yaml
   ```

3. Watch ArgoCD sync your application:
   ```bash
   kubectl get applications -n argocd hello-fawkes -w
   ```

   Wait until `STATUS` shows `Synced` and `HEALTH` shows `Healthy`.

!!! tip "Alternative: Direct kubectl Apply"
    If ArgoCD isn't available, you can deploy directly:
    ```bash
    kubectl apply -f k8s/
    ```

!!! success "Checkpoint"
    ArgoCD is now managing your application deployment. Any changes you push to Git will automatically sync!

## Step 6: Verify Your Deployment

Let's confirm everything is working.

1. Check pod status:
   ```bash
   kubectl get pods -n my-first-app
   ```
   
   You should see 2 pods running (we specified `replicas: 2`):
   ```
   NAME                            READY   STATUS    RESTARTS   AGE
   hello-fawkes-xxxxxxxxx-xxxxx    1/1     Running   0          2m
   hello-fawkes-xxxxxxxxx-xxxxx    1/1     Running   0          2m
   ```

2. Check the service:
   ```bash
   kubectl get service -n my-first-app
   ```

3. Check the ingress:
   ```bash
   kubectl get ingress -n my-first-app
   ```
   
   Note the `ADDRESS` field - this is your ingress IP.

4. Test the endpoint locally first:
   ```bash
   kubectl port-forward -n my-first-app svc/hello-fawkes 8080:80
   ```
   
   In another terminal:
   ```bash
   curl http://localhost:8080
   ```
   
   You should see:
   ```json
   {
     "message": "Hello from Fawkes!",
     "timestamp": "2025-12-06T12:00:00.000Z",
     "version": "1.0.0"
   }
   ```

5. Test via ingress (in your browser or with curl):
   ```bash
   curl https://hello-fawkes.127.0.0.1.nip.io
   ```

!!! success "Checkpoint"
    Your service is running, accessible via HTTPS, and responding to requests! 🎉

## Step 7: Register in Backstage Catalog

To make your service visible in the Fawkes developer portal, register it in Backstage.

1. Create a `catalog-info.yaml` file in your repository root:
   ```yaml
   apiVersion: backstage.io/v1alpha1
   kind: Component
   metadata:
     name: hello-fawkes
     description: My first service on Fawkes
     annotations:
       github.com/project-slug: YOUR-USERNAME/hello-fawkes
       argocd/app-name: hello-fawkes
   spec:
     type: service
     lifecycle: experimental
     owner: team-platform
     system: tutorials
   ```

2. Commit and push:
   ```bash
   git add catalog-info.yaml
   git commit -m "Add Backstage catalog info"
   git push
   ```

3. Register the component in Backstage:
   - Navigate to the Backstage UI (typically `https://backstage.fawkes.yourdomain.com`)
   - Click **Create** → **Register Existing Component**
   - Enter your repository URL: `https://github.com/YOUR-USERNAME/hello-fawkes`
   - Click **Analyze** → **Import**

4. View your service in the catalog:
   - Go to **Catalog** → **All**
   - Search for "hello-fawkes"
   - Click on your component to see details

!!! success "Checkpoint"
    Your service is now registered in the Backstage service catalog, making it discoverable to your entire team!

## Step 8: Celebrate Your First Success! 🎉

Congratulations! You've successfully:

- ✅ Created a cloud-native web service
- ✅ Deployed it using GitOps principles
- ✅ Made it accessible via secure HTTPS ingress
- ✅ Registered it in the developer portal
- ✅ Followed Fawkes security best practices

## What's Next?

Now that you have a running service, you can:

1. **[Add Distributed Tracing](2-add-tracing-tempo.md)** - Learn how to instrument your service with OpenTelemetry and view traces in Grafana Tempo
2. **[Consume Vault Secrets](3-consume-vault-secret.md)** - Secure your application by using HashiCorp Vault for secrets management
3. **[Explore DORA Metrics](6-measure-dora-metrics.md)** - See how your deployment is contributing to your team's DORA metrics

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod -n my-first-app -l app=hello-fawkes

# Check logs
kubectl logs -n my-first-app -l app=hello-fawkes
```

Common issues:
- **ImagePullBackOff**: Check your image name and registry credentials
- **CrashLoopBackOff**: Check application logs for startup errors
- **Pending**: Check resource quotas and node capacity

### Ingress Not Accessible

```bash
# Verify ingress controller is running
kubectl get pods -n ingress-nginx

# Check ingress events
kubectl describe ingress -n my-first-app hello-fawkes
```

### ArgoCD Not Syncing

```bash
# Check ArgoCD application status
kubectl get application -n argocd hello-fawkes -o yaml

# View sync errors
kubectl describe application -n argocd hello-fawkes
```

## Learn More

- **[GitOps Strategy Explanation](../explanation/architecture/gitops-strategy.md)** - Understand why Fawkes uses GitOps
- **[Zero Trust Security Model](../explanation/security/zero-trust-model.md)** - Learn about the security context settings we used
- **[How to Configure Ingress with TLS](../how-to/networking/configure-ingress-tls.md)** - Advanced ingress configuration

## Feedback

This tutorial is designed to get you to success in under 30 minutes. Did you make it? Was anything confusing? Let us know in the [Fawkes Community Mattermost](https://fawkes-community.mattermost.com) or [open an issue](https://github.com/paruff/fawkes/issues).
