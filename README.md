# Microservices Application

A complete microservices application with Docker containerization, Kubernetes deployment, and CI/CD pipeline.

## Architecture

- **API Service**: Node.js REST API
- **Worker Service**: Python background job processor
- **Frontend Service**: React application served with Nginx
- **Database**: PostgreSQL with persistent storage

## Quick Start

### Local Development with Docker Compose
```bash
# Clone repository
git clone <repository-url>
cd microservices-app

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access application
open http://localhost:8080