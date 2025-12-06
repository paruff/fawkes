---
title: Add Distributed Tracing with Tempo
description: Instrument your service with OpenTelemetry and view traces in Grafana Tempo
---

# Add Distributed Tracing with Tempo

**Time to Complete**: 20-25 minutes  
**Goal**: Add OpenTelemetry instrumentation to your service and view distributed traces in Grafana Tempo.

## What You'll Learn

By the end of this tutorial, you will have:

1. ✅ Instrumented your application with OpenTelemetry
2. ✅ Configured trace export to Grafana Tempo
3. ✅ Generated traces by making requests to your service
4. ✅ Viewed and analyzed traces in the Grafana UI

## Prerequisites

Before you begin, ensure you have:

- [ ] Completed [Tutorial 1: Deploy Your First Service](1-deploy-first-service.md)
- [ ] Your `hello-fawkes` service running and accessible
- [ ] Access to Grafana (typically at `https://grafana.127.0.0.1.nip.io`)
- [ ] Basic understanding of distributed tracing concepts (helpful but not required)

!!! info "What is Distributed Tracing?"
    Distributed tracing tracks requests as they flow through multiple services. Each request gets a unique trace ID, and each service operation creates a "span". This helps you debug performance issues and understand system behavior. [Learn more about Unified Telemetry](../explanation/observability/unified-telemetry.md).

## Step 1: Install OpenTelemetry Dependencies

We'll add OpenTelemetry instrumentation to the Node.js application we created in Tutorial 1.

1. Navigate to your `hello-fawkes` directory:
   ```bash
   cd hello-fawkes
   ```

2. Install OpenTelemetry packages:
   ```bash
   npm install --save \
     @opentelemetry/api \
     @opentelemetry/sdk-node \
     @opentelemetry/auto-instrumentations-node \
     @opentelemetry/exporter-trace-otlp-http
   ```

3. Update `package.json` to save the dependencies:
   ```bash
   git add package.json package-lock.json
   git commit -m "Add OpenTelemetry dependencies"
   ```

!!! success "Checkpoint"
    OpenTelemetry dependencies are installed and ready to use.

## Step 2: Create OpenTelemetry Configuration

1. Create a new file `tracing.js` in your project root:
   ```javascript
   const { NodeSDK } = require('@opentelemetry/sdk-node');
   const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
   const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');
   const { Resource } = require('@opentelemetry/resources');
   const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

   // Configure the trace exporter
   const traceExporter = new OTLPTraceExporter({
     url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://tempo.fawkes-platform.svc.cluster.local:4318/v1/traces',
   });

   // Create resource with service information
   const resource = new Resource({
     [SemanticResourceAttributes.SERVICE_NAME]: process.env.OTEL_SERVICE_NAME || 'hello-fawkes',
     [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
     [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.ENVIRONMENT || 'development',
   });

   // Initialize the SDK
   const sdk = new NodeSDK({
     resource: resource,
     traceExporter: traceExporter,
     instrumentations: [
       getNodeAutoInstrumentations({
         // Customize instrumentation
         '@opentelemetry/instrumentation-fs': {
           enabled: false, // Disable file system instrumentation for cleaner traces
         },
       }),
     ],
   });

   // Start the SDK
   sdk.start();

   // Graceful shutdown
   process.on('SIGTERM', () => {
     sdk.shutdown()
       .then(() => console.log('Tracing terminated'))
       .catch((error) => console.log('Error terminating tracing', error))
       .finally(() => process.exit(0));
   });

   console.log('OpenTelemetry tracing initialized');
   ```

2. Update `server.js` to load tracing first:
   ```javascript
   // Load tracing before anything else
   require('./tracing');

   const express = require('express');
   const app = express();
   const PORT = process.env.PORT || 8080;

   app.get('/', (req, res) => {
     res.json({
       message: 'Hello from Fawkes!',
       timestamp: new Date().toISOString(),
       version: '1.0.0',
       tracing: 'enabled'
     });
   });

   app.get('/health', (req, res) => {
     res.json({ status: 'healthy' });
   });

   // Add a new endpoint to simulate a traced operation
   app.get('/api/data', async (req, res) => {
     // Simulate some work
     await new Promise(resolve => setTimeout(resolve, 100));
     
     res.json({
       data: [
         { id: 1, name: 'Item 1' },
         { id: 2, name: 'Item 2' },
         { id: 3, name: 'Item 3' }
       ],
       traceId: req.headers['x-trace-id'] || 'auto-generated'
     });
   });

   app.listen(PORT, '0.0.0.0', () => {
     console.log(`Server running on port ${PORT}`);
   });
   ```

3. Commit the changes:
   ```bash
   git add tracing.js server.js
   git commit -m "Add OpenTelemetry instrumentation"
   ```

!!! success "Checkpoint"
    Your application is now instrumented with OpenTelemetry!

## Step 3: Update Kubernetes Deployment

We need to configure environment variables for the OpenTelemetry exporter.

1. Update `k8s/deployment.yaml` to add environment variables:
   ```yaml
   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: hello-fawkes
     namespace: my-first-app
     labels:
       app: hello-fawkes
       version: v2
   spec:
     replicas: 2
     selector:
       matchLabels:
         app: hello-fawkes
     template:
       metadata:
         labels:
           app: hello-fawkes
           version: v2
       spec:
         containers:
         - name: hello-fawkes
           image: YOUR-USERNAME/hello-fawkes:v2.0.0  # Update version
           ports:
           - containerPort: 8080
             name: http
           env:
           - name: PORT
             value: "8080"
           - name: OTEL_SERVICE_NAME
             value: "hello-fawkes"
           - name: SERVICE_VERSION
             value: "2.0.0"
           - name: ENVIRONMENT
             value: "development"
           - name: OTEL_EXPORTER_OTLP_ENDPOINT
             value: "http://tempo.fawkes-platform.svc.cluster.local:4318/v1/traces"
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
               memory: "128Mi"  # Increased for tracing overhead
               cpu: "100m"
             limits:
               memory: "256Mi"  # Increased for tracing overhead
               cpu: "200m"
           securityContext:
             runAsNonRoot: true
             runAsUser: 1000
             allowPrivilegeEscalation: false
             readOnlyRootFilesystem: true
   ```

2. Commit the updated manifest:
   ```bash
   git add k8s/deployment.yaml
   git commit -m "Configure OpenTelemetry environment variables"
   ```

!!! info "Why These Environment Variables?"
    - `OTEL_SERVICE_NAME`: Identifies your service in traces
    - `OTEL_EXPORTER_OTLP_ENDPOINT`: Where to send traces (Tempo endpoint)
    - `ENVIRONMENT`: Helps filter traces by environment (dev/staging/prod)

!!! success "Checkpoint"
    Deployment is configured to export traces to Tempo.

## Step 4: Build and Deploy Updated Application

1. Build the new version of your container:
   ```bash
   docker build -t YOUR-USERNAME/hello-fawkes:v2.0.0 .
   ```

2. Push the image:
   ```bash
   docker push YOUR-USERNAME/hello-fawkes:v2.0.0
   ```

3. Push your code changes to Git:
   ```bash
   git push
   ```

4. If using ArgoCD, it will automatically sync. If not, apply manually:
   ```bash
   kubectl apply -f k8s/deployment.yaml
   ```

5. Watch the rollout:
   ```bash
   kubectl rollout status deployment/hello-fawkes -n my-first-app
   ```

6. Verify the new pods are running:
   ```bash
   kubectl get pods -n my-first-app
   ```

!!! success "Checkpoint"
    Your updated application with tracing is deployed and running!

## Step 5: Generate Traces

Now let's create some traces by making requests to our service.

1. Make some requests to generate traces:
   ```bash
   # Make multiple requests
   for i in {1..10}; do
     curl https://hello-fawkes.127.0.0.1.nip.io/
     sleep 1
   done
   ```

2. Make requests to the new `/api/data` endpoint:
   ```bash
   # Generate traces with the data endpoint
   for i in {1..10}; do
     curl https://hello-fawkes.127.0.0.1.nip.io/api/data
     sleep 1
   done
   ```

3. Mix in some health check requests:
   ```bash
   curl https://hello-fawkes.127.0.0.1.nip.io/health
   ```

!!! tip "Generate Realistic Traffic"
    The more varied your requests, the more interesting your traces will be. Try different endpoints and patterns.

!!! success "Checkpoint"
    You've generated trace data that should now be visible in Grafana Tempo!

## Step 6: View Traces in Grafana

Now for the exciting part - seeing your traces visualized!

1. Open Grafana in your browser:
   ```
   https://grafana.127.0.0.1.nip.io
   ```

2. Log in with your Grafana credentials (ask your platform team if you don't have them).

3. Navigate to **Explore** (compass icon in left sidebar).

4. Select **Tempo** as the data source from the dropdown at the top.

5. In the query builder:
   - Select **Search** tab
   - Service Name: `hello-fawkes`
   - Click **Run query**

6. You should see a list of traces! Click on one to expand it.

7. In the trace view, you'll see:
   - **Timeline**: Visual representation of span durations
   - **Span details**: Operation names, durations, tags
   - **Service map**: Shows service dependencies (even for a single service)

!!! tip "Understanding the Trace View"
    Each horizontal bar is a "span" representing an operation. Nested spans show parent-child relationships. Longer bars indicate slower operations.

!!! success "Checkpoint"
    You're viewing distributed traces in Grafana Tempo! 🎉

## Step 7: Analyze a Trace

Let's understand what you're seeing in the trace view.

1. Pick a trace for the `/api/data` endpoint.

2. Expand the spans to see the hierarchy:
   ```
   GET /api/data (root span)
   ├─ Express middleware
   ├─ Route handler
   └─ HTTP response
   ```

3. Look at the span details:
   - **Duration**: How long this operation took
   - **Tags**: Metadata like HTTP method, status code, URL
   - **Logs**: Any events recorded during this span

4. Compare traces:
   - Click on multiple traces to see timing variations
   - Look for patterns in slow requests

!!! info "What Makes a Good Trace?"
    A well-instrumented trace shows you exactly where time is spent. You should be able to answer: "Which operation is slow?" without looking at code.

## Step 8: Create a Grafana Dashboard (Optional)

For ongoing monitoring, create a dashboard to visualize trace metrics.

1. In Grafana, go to **Dashboards** → **New** → **New Dashboard**.

2. Click **Add visualization**.

3. Select **Tempo** as the data source.

4. Create a panel showing request rate:
   - Query: Use TraceQL: `{ service.name="hello-fawkes" }`
   - Visualization: Time series

5. Add another panel for duration percentiles:
   - This shows p50, p95, p99 latencies over time

6. Save the dashboard as "Hello Fawkes - Tracing".

!!! success "Checkpoint"
    You now have a dashboard to monitor your service's trace data continuously!

## What You've Accomplished

Congratulations! You've successfully:

- ✅ Instrumented a Node.js application with OpenTelemetry
- ✅ Configured trace export to Grafana Tempo
- ✅ Deployed the instrumented application to Fawkes
- ✅ Generated and viewed distributed traces
- ✅ Analyzed trace data to understand application behavior

## What's Next?

Continue your Fawkes journey:

1. **[Consume Vault Secrets](3-consume-vault-secret.md)** - Secure your application configuration
2. **[Measure DORA Metrics](6-measure-dora-metrics.md)** - See how tracing contributes to observability metrics
3. **[How to Trace Requests with Tempo](../how-to/observability/trace-request-tempo.md)** - Advanced tracing techniques

## Troubleshooting

### No Traces Appearing in Grafana

1. Check that Tempo is running:
   ```bash
   kubectl get pods -n fawkes-platform -l app=tempo
   ```

2. Verify your application can reach Tempo:
   ```bash
   kubectl exec -n my-first-app deployment/hello-fawkes -- \
     wget -O- http://tempo.fawkes-platform.svc.cluster.local:4318/v1/traces
   ```

3. Check application logs for tracing errors:
   ```bash
   kubectl logs -n my-first-app -l app=hello-fawkes | grep -i otel
   ```

### Traces Appear but Are Incomplete

- Ensure `tracing.js` is loaded before other modules in `server.js`
- Check that auto-instrumentation is enabled for Express
- Verify resource limits aren't too restrictive

### High Memory Usage After Adding Tracing

- Tracing adds ~20-30MB overhead per container
- Adjust resource limits if needed
- Consider sampling: only trace a percentage of requests in production

## Learn More

- **[Unified Telemetry Explanation](../explanation/observability/unified-telemetry.md)** - How metrics, logs, and traces work together
- **[How to Trace Requests with Tempo](../how-to/observability/trace-request-tempo.md)** - Advanced tracing patterns
- **[OpenTelemetry Documentation](https://opentelemetry.io/docs/)** - Official OpenTelemetry docs

## Feedback

How was this tutorial? Did you successfully view your traces? Share your experience in the [Fawkes Community Mattermost](https://fawkes-community.mattermost.com)!
