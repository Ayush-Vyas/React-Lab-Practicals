# ==============================================================================
# Practical 11: Backend Dockerfile (Node.js Express API)
# ==============================================================================
FROM node:20-alpine

# Set working directory
WORKDIR /app

# Copy dependency manifests first for layer caching
COPY package*.json ./

# Install production dependencies
RUN npm install

# Copy application source code
COPY . .

# Expose backend service port
EXPOSE 5000

# Start Express server
CMD ["node", "app.js"]
