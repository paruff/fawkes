---
title: Migrate to Cloud Native Buildpacks
description: Move from Dockerfiles to Cloud Native Buildpacks for automated, secure container builds
---

# Migrate to Cloud Native Buildpacks

**Time to Complete**: 20-25 minutes  
**Goal**: Replace your Dockerfile with Cloud Native Buildpacks (CNB) for automated, secure, and maintainable container builds.

## What You'll Learn

By the end of this tutorial, you will have:

1. ✅ Understood the benefits of Cloud Native Buildpacks over Dockerfiles
2. ✅ Removed your Dockerfile and configured Buildpacks
3. ✅ Built a container image using Buildpacks
4. ✅ Deployed the Buildpack-built image to Fawkes
5. ✅ Verified automatic base image updates (rebasing)

## Prerequisites

Before you begin, ensure you have:

- [ ] Completed [Tutorial 1: Deploy Your First Service](1-deploy-first-service.md)
- [ ] Your `hello-fawkes` service with a Dockerfile
- [ ] Docker or Podman installed locally
- [ ] `pack` CLI installed ([installation guide](https://buildpacks.io/docs/tools/pack/))
- [ ] Basic understanding of Docker and container images

!!! info "Why Buildpacks?"
    Dockerfiles give you control, but with control comes responsibility. Who updates base images when CVEs are discovered? Who ensures all teams follow security best practices? Buildpacks automate these concerns. [Learn the philosophy](../explanation/containers/buildpacks-philosophy.md).

## Step 1: Understand Your Current Dockerfile

Let's review what your Dockerfile is doing and how Buildpacks will replace it.

1. View your current `Dockerfile`:
   ```dockerfile
   FROM node:18-alpine
   
   WORKDIR /app
   
   COPY package*.json ./
   RUN npm ci --only=production
   
   COPY server.js ./
   COPY tracing.js ./
   COPY vault-client.js ./
   
   RUN addgroup -g 1000 appuser && \
       adduser -D -u 1000 -G appuser appuser && \
       chown -R appuser:appuser /app
   
   USER appuser
   
   EXPOSE 8080
   
   CMD ["npm", "start"]
   ```

2. Identify what the Dockerfile is doing:
   - ✅ Choosing a base image (node:18-alpine)
   - ✅ Installing dependencies (npm ci)
   - ✅ Copying application code
   - ✅ Creating a non-root user
   - ✅ Setting the start command

3. Problems with this approach:
   - **Manual updates**: When Node.js 18 reaches EOL, you must update it
   - **CVE lag**: Security patches require rebuilding every image
   - **Inconsistency**: Different teams use different base images
   - **No caching**: Every team implements their own layer caching

!!! info "Buildpacks Automate All of This"
    Buildpacks detect your application type, choose appropriate base images, install dependencies, and configure security - all automatically.

!!! success "Checkpoint"
    You understand what your Dockerfile does and why Buildpacks are an improvement.

## Step 2: Install Pack CLI

Pack is the CLI for working with Cloud Native Buildpacks.

1. Install Pack (choose your platform):

   **macOS (Homebrew):**
   ```bash
   brew install buildpacks/tap/pack
   ```

   **Linux:**
   ```bash
   sudo add-apt-repository ppa:cncf-buildpacks/pack-cli
   sudo apt-get update
   sudo apt-get install pack-cli
   ```

   **Windows (Chocolatey):**
   ```bash
   choco install pack
   ```

2. Verify installation:
   ```bash
   pack --version
   ```

3. Set a default builder (we'll use Paketo):
   ```bash
   pack config default-builder paketobuildpacks/builder:base
   ```

!!! info "What's a Builder?"
    A builder is a container image that contains buildpacks and knows how to build your application. Paketo Buildpacks is a CNCF project that provides enterprise-grade buildpacks for multiple languages.

!!! success "Checkpoint"
    Pack CLI is installed and configured with a default builder.

## Step 3: Prepare for Buildpacks

Buildpacks work best when your application follows conventions. Let's ensure your app is ready.

1. Verify your `package.json` has a start script:
   ```json
   {
     "name": "hello-fawkes",
     "version": "3.0.0",
     "scripts": {
       "start": "node server.js"
     },
     "dependencies": {
       "express": "^4.18.2",
       "node-vault": "^0.10.2",
       "@opentelemetry/api": "^1.4.1",
       "@opentelemetry/sdk-node": "^0.41.0",
       "@opentelemetry/auto-instrumentations-node": "^0.39.1",
       "@opentelemetry/exporter-trace-otlp-http": "^0.41.0"
     }
   }
   ```

2. Ensure you have a `package-lock.json`:
   ```bash
   npm install
   ```

3. Optional: Create a `.packignore` file to exclude files from the build:
   ```
   .git/
   .gitignore
   *.md
   Dockerfile
   k8s/
   node_modules/
   ```

4. Commit these changes:
   ```bash
   git add .packignore package.json package-lock.json
   git commit -m "Prepare for Buildpacks migration"
   ```

!!! success "Checkpoint"
    Your application follows Buildpacks conventions and is ready to build.

## Step 4: Build with Buildpacks

Now for the exciting part - building your first Buildpack image!

1. Build your application with Pack:
   ```bash
   pack build YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack \
     --builder paketobuildpacks/builder:base \
     --env BP_NODE_VERSION=18
   ```

2. Watch the build process:
   - Buildpacks will detect that you're using Node.js
   - It will install the correct Node.js version
   - It will run `npm ci` to install dependencies
   - It will configure the start command
   - It will create a secure, minimal container image

3. Inspect the build output:
   ```
   ===> DETECTING
   [detector] 6 of 24 buildpacks participating
   [detector] paketo-buildpacks/ca-certificates   3.6.3
   [detector] paketo-buildpacks/node-engine        2.0.0
   [detector] paketo-buildpacks/npm-install        1.2.3
   [detector] paketo-buildpacks/node-run-script    1.0.5
   [detector] paketo-buildpacks/node-start         1.0.5
   [detector] paketo-buildpacks/procfile           5.6.3
   
   ===> BUILDING
   [builder] Running npm ci...
   [builder] Installing node_modules...
   
   ===> EXPORTING
   [exporter] Adding layer 'paketo-buildpacks/node-engine:node'
   [exporter] Adding layer 'paketo-buildpacks/npm-install:modules'
   ```

4. Verify the image was created:
   ```bash
   docker images | grep hello-fawkes
   ```

!!! tip "Build Time"
    The first build may take a few minutes as it downloads base images and buildpacks. Subsequent builds are much faster thanks to layer caching.

!!! success "Checkpoint"
    You've built a container image using Cloud Native Buildpacks!

## Step 5: Compare Image Sizes

Let's see how the Buildpack image compares to your Dockerfile image.

1. Check Dockerfile image size:
   ```bash
   docker images YOUR-USERNAME/hello-fawkes:v3.0.0
   ```

2. Check Buildpack image size:
   ```bash
   docker images YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```

3. Compare the layers:
   ```bash
   # Dockerfile image
   docker history YOUR-USERNAME/hello-fawkes:v3.0.0
   
   # Buildpack image
   docker history YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```

!!! info "Image Size Differences"
    Buildpack images may be larger than Alpine-based Dockerfile images because they use Ubuntu Bionic for better compatibility. However, they're more secure and maintainable. The trade-off is worth it for most applications.

!!! success "Checkpoint"
    You understand the characteristics of your Buildpack-built image.

## Step 6: Test the Buildpack Image Locally

Before deploying, let's verify the image works correctly.

1. Run the container locally:
   ```bash
   docker run -d --name hello-fawkes-test \
     -p 8080:8080 \
     -e PORT=8080 \
     -e VAULT_ADDR=http://vault.fawkes-platform.svc.cluster.local:8200 \
     YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```

2. Test the endpoint:
   ```bash
   curl http://localhost:8080/
   ```
   
   Should return:
   ```json
   {
     "message": "Hello from Fawkes!",
     "timestamp": "2025-12-06T12:00:00.000Z",
     "version": "3.0.0",
     "tracing": "enabled",
     "secrets": "managed by Vault"
   }
   ```

3. Check the running user (should be non-root):
   ```bash
   docker exec hello-fawkes-test whoami
   ```
   
   Should output: `cnb` (Buildpacks default non-root user)

4. Stop and remove the test container:
   ```bash
   docker stop hello-fawkes-test
   docker rm hello-fawkes-test
   ```

!!! success "Checkpoint"
    The Buildpack image works correctly and follows security best practices!

## Step 7: Deploy Buildpack Image to Fawkes

Now let's deploy the Buildpack-built image to your cluster.

1. Push the image to your registry:
   ```bash
   docker push YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```

2. Update `k8s/deployment.yaml` to use the new image:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     labels:
       app: hello-fawkes
       version: v4
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: hello-fawkes
     template:
       metadata:
         labels:
           app: hello-fawkes
           version: v4
         annotations:
           buildpack.io/builder: "paketobuildpacks/builder:base"
       spec:
         serviceAccountName: hello-fawkes
         containers:
         - name: hello-fawkes
           image: YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
           # Rest of spec remains the same
   ```

3. Commit and push:
   ```bash
   git add k8s/deployment.yaml
   git commit -m "Deploy Buildpack-built image"
   git push
   ```

4. Watch the rollout:
   ```bash
   kubectl rollout status deployment/hello-fawkes -n my-first-app
   ```

5. Verify the new pods are running:
   ```bash
   kubectl get pods -n my-first-app
   ```

6. Test the deployed service:
   ```bash
   curl https://hello-fawkes.127.0.0.1.nip.io/
   ```

!!! success "Checkpoint"
    Your service is now running with a Buildpack-built image on Fawkes!

## Step 8: Understand Rebasing

One of the key benefits of Buildpacks is "rebasing" - updating base images without rebuilding.

1. Check the current base image:
   ```bash
   pack inspect YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```
   
   Note the "Run Image" section.

2. Rebase to the latest base image (simulating a security update):
   ```bash
   pack rebase YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```

3. Compare the speed:
   - **Rebuild**: 2-5 minutes (downloads dependencies, runs build)
   - **Rebase**: 5-10 seconds (only updates base layers)

4. Push the rebased image:
   ```bash
   docker push YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
   ```

5. Trigger a rollout in Kubernetes:
   ```bash
   kubectl rollout restart deployment/hello-fawkes -n my-first-app
   ```

!!! info "Rebasing in Production"
    In a mature platform, rebasing is automated:
    - CI/CD pipeline runs `pack rebase` nightly
    - Images get security updates without code changes
    - ArgoCD deploys updated images automatically
    
    This is how you patch 100 microservices in minutes, not weeks.

!!! success "Checkpoint"
    You've rebased your image and understand the power of this feature!

## Step 9: Remove the Dockerfile

Now that you're using Buildpacks, the Dockerfile is obsolete.

1. Remove the Dockerfile:
   ```bash
   rm Dockerfile
   ```

2. Optional: Add a `project.toml` for Buildpack configuration:
   ```toml
   [_]
   schema-version = "0.2"

   [[io.buildpacks.build.env]]
   name = "BP_NODE_VERSION"
   value = "18"

   [[io.buildpacks.build.env]]
   name = "BP_NPM_INSTALL_ARGS"
   value = "--production"
   ```

3. Update your CI/CD pipeline to use `pack build` instead of `docker build`.

   Example Jenkins pipeline snippet:
   ```groovy
   stage('Build Image') {
     steps {
       sh '''
         pack build ${IMAGE_NAME}:${VERSION} \
           --builder paketobuildpacks/builder:base \
           --publish
       '''
     }
   }
   ```

4. Commit the changes:
   ```bash
   git add Dockerfile project.toml
   git commit -m "Remove Dockerfile, migrate to Buildpacks"
   git push
   ```

!!! success "Checkpoint"
    You've fully migrated from Dockerfiles to Cloud Native Buildpacks!

## What You've Accomplished

Congratulations! You've successfully:

- ✅ Understood the benefits of Buildpacks over Dockerfiles
- ✅ Built a container image using Cloud Native Buildpacks
- ✅ Deployed a Buildpack-built image to Fawkes
- ✅ Learned about rebasing for fast security updates
- ✅ Migrated away from manual Dockerfile maintenance

## Benefits You've Gained

1. **Automated Security** - Base images update automatically
2. **Consistency** - All Node.js apps use the same buildpack
3. **Best Practices** - Non-root user, minimal layers, optimal caching
4. **Fast Patching** - Rebase 100 images in minutes
5. **Less Maintenance** - No Dockerfiles to update across teams

## What's Next?

Continue your Fawkes journey:

1. **[Create Golden Path Template](5-create-golden-path-template.md)** - Make Buildpacks the default for new services
2. **[Measure DORA Metrics](6-measure-dora-metrics.md)** - Track deployment frequency improvements
3. **[Buildpacks Philosophy](../explanation/containers/buildpacks-philosophy.md)** - Deep dive into the trade-offs

## Troubleshooting

### Pack Build Fails to Detect Buildpack

```bash
# Ensure package.json is in the root directory
ls -la package.json

# Try specifying the buildpack explicitly
pack build myimage --buildpack paketo-buildpacks/nodejs
```

### Image Larger Than Expected

- Buildpacks use Ubuntu, not Alpine
- Includes build tools for maximum compatibility
- Trade-off: Larger size for better security and maintainability
- Consider multi-stage builds if size is critical

### Application Won't Start

```bash
# Check the buildpack-detected start command
pack inspect YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack

# Verify your package.json "start" script
cat package.json | grep -A2 scripts

# Test locally first
docker run -it YOUR-USERNAME/hello-fawkes:v4.0.0-buildpack
```

### Need to Customize Build Process

- Use `project.toml` for buildpack configuration
- Set environment variables: `--env BP_NODE_VERSION=18`
- Add build-time arguments: `--env BP_BUILD_ARGS="--verbose"`
- See [Paketo Node.js Buildpack docs](https://paketo.io/docs/howto/nodejs/)

## Learn More

- **[Buildpacks Philosophy](../explanation/containers/buildpacks-philosophy.md)** - Understand the security vs. control trade-off
- **[Cloud Native Buildpacks Documentation](https://buildpacks.io/)** - Official CNB docs
- **[Paketo Buildpacks](https://paketo.io/)** - Enterprise-grade buildpacks for Java, Node.js, Go, Python, and more

## Feedback

How was your experience migrating to Buildpacks? Did you encounter any issues? Share your feedback in the [Fawkes Community Mattermost](https://fawkes-community.mattermost.com)!
