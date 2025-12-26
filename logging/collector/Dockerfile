FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY tsconfig.json ./
COPY src ./src
RUN npm run build

# Create checkpoint directory
RUN mkdir -p /app/checkpoints

CMD ["node", "dist/index.js"]
