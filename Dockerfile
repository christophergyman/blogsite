# Stage 1: Build the Astro site
FROM node:20-alpine AS builder

# Install pnpm
RUN npm install -g pnpm@10.15.0

WORKDIR /app

# Copy package files and patches directory (needed for patched dependencies)
COPY package.json pnpm-lock.yaml ./
COPY patches/ ./patches/

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy source code
COPY . .

# Build the site
RUN pnpm build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy built site from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
