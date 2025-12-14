# Multi-stage Dockerfile for Node.js Express
# Stage 1: Build
FROM node:20-alpine AS build
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Stage 2: Runtime
FROM node:20-alpine
WORKDIR /app

# Create non-root user
RUN addgroup -g 65534 appuser && \
    adduser -D -u 65534 -G appuser appuser

# Copy dependencies from build stage
COPY --from=build /app/node_modules ./node_modules

# Copy application code
COPY src ./src
COPY package*.json ./

# Change ownership
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => { process.exit(r.statusCode === 200 ? 0 : 1); });"

# Run application
CMD ["node", "src/index.js"]
