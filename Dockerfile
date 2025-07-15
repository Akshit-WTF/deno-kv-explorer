# Use the official Bun image
FROM oven/bun:1.1.34-alpine AS base

# Install curl for healthcheck
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy package files
COPY package.json bun.lockb* ./

# Install dependencies
RUN bun install --frozen-lockfile --production

# Copy source code
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S denokvuser && \
    adduser -S denokvuser -u 1001

# Change ownership of the app directory
RUN chown -R denokvuser:denokvuser /app
USER denokvuser

# Expose port
EXPOSE 4055

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4055/ || exit 1

# Start the application
CMD ["bun", "run", "index.ts"]
