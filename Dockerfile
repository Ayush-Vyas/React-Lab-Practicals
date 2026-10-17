# ==============================================================================
# Practical 11: Frontend Multi-Stage Dockerfile (React + Vite -> Nginx)
# ==============================================================================

# Stage 1: Build the React application with Vite
FROM node:20-alpine AS build

WORKDIR /app

# Copy dependency definitions and install
COPY package*.json ./
RUN npm install

# Copy application source code and run Vite build
COPY . .
RUN npm run build

# Stage 2: Serve production build via high-performance Nginx web server
FROM nginx:alpine

# Copy built static assets from build stage
COPY --from=build /app/dist /usr/share/nginx/html

# Copy Nginx SPA configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose web server port
EXPOSE 80

# Start Nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
