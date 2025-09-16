# Build stage
FROM node:18-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

# Production stage with Nginx
FROM nginx:1.21-alpine AS production

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built application (for React, it's usually in 'build' directory, for Vite it's 'dist')
COPY --from=builder /app/build /usr/share/nginx/html

# If using Vite instead of Create React App, uncomment the line below and comment the line above
# COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
