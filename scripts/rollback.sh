#!/bin/bash

SERVICE=$1
REVISION=$2

if [ -z "$SERVICE" ] || [ -z "$REVISION" ]; then
    echo "Usage: $0 <service-name> <revision>"
    echo "Example: $0 api-service 1"
    exit 1
fi

echo "Rolling back $SERVICE to revision $REVISION..."

kubectl rollout undo deployment/$SERVICE --to-revision=$REVISION -n microservices

echo "Waiting for rollback to complete..."
kubectl rollout status deployment/$SERVICE -n microservices --timeout=300s

echo "Rollback complete!"
kubectl get pods -n microservices -l app=$SERVICE