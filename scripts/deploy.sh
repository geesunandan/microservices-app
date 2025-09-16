#!/bin/bash

echo "=== Minikube Deployment Script ==="

# Make sure we're using Minikube's Docker daemon
eval $(minikube -p minikube docker-env)

echo "Building Docker images..."
docker build -t api-service:latest ./api-service
docker build -t worker-service:latest ./worker-service
docker build -t frontend-service:latest ./frontend-service

echo "Verifying images are built..."
docker images | grep -E "(api-service|worker-service|frontend-service)"

echo "Creating namespace..."
kubectl apply -f k8s/namespace.yaml

echo "Creating ConfigMaps and Secrets..."
kubectl apply -f k8s/database/postgres-configmap.yaml
kubectl apply -f k8s/database/postgres-secret.yaml

echo "Creating init SQL ConfigMap..."
kubectl create configmap postgres-init --from-file=init.sql -n microservices --dry-run=client -o yaml | kubectl apply -f -

echo "Deploying database..."
kubectl apply -f k8s/database/

echo "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l app=postgres -n microservices --timeout=120s

echo "Deploying API service..."
kubectl apply -f k8s/api-service/

echo "Deploying worker service..."
kubectl apply -f k8s/worker-service/

echo "Deploying frontend service..."
kubectl apply -f k8s/frontend-service/

echo "Creating ingress..."
kubectl apply -f k8s/ingress.yaml

echo "Deployment complete!"

echo ""
echo "=== Access Information ==="
echo "Minikube IP: $(minikube ip)"
echo ""
echo "To access the application:"
echo "1. Frontend: minikube service frontend-service -n microservices --url"
echo "2. API: minikube service api-service -n microservices --url"
echo ""
echo "Or use port forwarding:"
echo "kubectl port-forward service/frontend-service 8080:8080 -n microservices"
echo "kubectl port-forward service/api-service 3000:3000 -n microservices"
echo ""

# Show service URLs
echo "Getting service URLs..."
minikube service list -n microservices

kubectl get services -n microservices