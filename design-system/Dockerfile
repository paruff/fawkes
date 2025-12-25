# Stage 1: Build
FROM node:18-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci

# Copy source files
COPY . .

# Build Storybook
RUN npm run build-storybook

# Stage 2: Serve
FROM nginx:alpine

# Copy built Storybook to nginx
COPY --from=builder /app/storybook-static /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 6006

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:6006/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
