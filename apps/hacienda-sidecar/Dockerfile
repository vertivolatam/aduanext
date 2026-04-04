# =============================================================================
# AduaNext Hacienda gRPC Sidecar — Multi-stage Docker build
# =============================================================================

# Stage 1: Build
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json* ./

# Install all dependencies (including devDependencies for build)
RUN npm ci

# Copy source
COPY tsconfig.json ./
COPY src/ ./src/

# Build
RUN npx tsup src/index.ts --format esm --dts

# Stage 2: Production
FROM node:22-alpine AS production

WORKDIR /app

# Create non-root user
RUN addgroup -S sidecar && adduser -S sidecar -G sidecar

# Copy package files and install production-only deps
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev && npm cache clean --force

# Copy built output from builder
COPY --from=builder /app/dist ./dist

# Switch to non-root user
USER sidecar

# Expose gRPC port
EXPOSE 50051

# Health check (gRPC health probe could be added here)
ENV GRPC_PORT=50051
ENV GRPC_HOST=0.0.0.0
ENV NODE_ENV=production

CMD ["node", "dist/index.js"]
