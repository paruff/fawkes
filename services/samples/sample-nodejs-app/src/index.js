const express = require('express');
const promClient = require('prom-client');
const winston = require('winston');

// Configure logger
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.json(),
  transports: [
    new winston.transports.Console({
      format: winston.format.simple()
    })
  ]
});

// Create Express app
const app = express();
const port = process.env.PORT || 3000;

// Prometheus metrics
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

const httpRequestCounter = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total HTTP requests',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP request latency',
  labelNames: ['method', 'route', 'status'],
  registers: [register]
});

// Middleware
app.use(express.json());

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    httpRequestCounter.labels(req.method, req.route?.path || req.path, res.statusCode).inc();
    httpRequestDuration.labels(req.method, req.route?.path || req.path, res.statusCode).observe(duration);
  });
  
  next();
});

// Logging middleware
app.use((req, res, next) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// Routes
app.get('/', (req, res) => {
  res.json({
    service: 'sample-nodejs-app',
    status: 'running',
    version: '0.1.0'
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'UP',
    service: 'sample-nodejs-app'
  });
});

app.get('/ready', (req, res) => {
  // Add any readiness checks here (database connection, etc.)
  res.json({
    status: 'READY',
    service: 'sample-nodejs-app'
  });
});

app.get('/info', (req, res) => {
  res.json({
    name: 'sample-nodejs-app',
    description: 'Sample Node.js Express application for testing',
    version: '0.1.0'
  });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// Error handler
app.use((err, req, res, next) => {
  logger.error('Error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// Start server
if (require.main === module) {
  app.listen(port, () => {
    logger.info(`sample-nodejs-app listening on port ${port}`);
  });
}

module.exports = app;
