#!/bin/bash

NAMESPACE="microservices"

echo "Checking service health..."

services=("api-service" "worker-service" "frontend-service" "postgres")

for service in "${services[@]}"; do
    echo "Checking $service..."
    
    if kubectl get pods -n $NAMESPACE -l app=$service | grep -q "Running"; then
        echo "✅ $service is running"
    else
        echo "❌ $service is not running"
        kubectl get pods -n $NAMESPACE -l app=$service
    fi
done

echo -e "\nService endpoints:"
kubectl get services -n $NAMESPACE