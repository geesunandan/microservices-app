# Microservices Deployment Manual & Debugging Guide

## 📋 Available Scripts

Your repository includes these helpful scripts:
- **`scripts/deploy.sh`** - Complete deployment automation (builds images, creates namespace, deploys all services)
- **`scripts/health-check.sh`** - Verifies all services are running and healthy
- **`scripts/rollback.sh`** - Quick rollback to previous deployment version

## 🔧 Minikube Setup (Local Kubernetes)

### Step 1: Install Minikube

**For macOS:**
```bash
# Using Homebrew
brew install minikube

# Or using curl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube
```

**For Linux:**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
```

**For Windows:**
```bash
# Using Chocolatey
choco install minikube

# Or download from: https://minikube.sigs.k8s.io/docs/start/
```

### Step 2: Start Minikube

```bash
# Start minikube with Docker driver and sufficient resources
minikube start --driver=docker --cpus=4 --memory=8192

# Verify minikube is running
minikube status
```

**Expected Output:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
kubeconfig: Configured
```

### Step 3: Enable Required Addons

```bash
# Enable ingress addon (for routing)
minikube addons enable ingress

# Enable metrics server (for monitoring)
minikube addons enable metrics-server

# Verify addons are enabled
minikube addons list | grep enabled
```

### Step 4: Configure Docker Environment

```bash
# Point Docker CLI to minikube's Docker daemon
eval $(minikube docker-env)

# Verify Docker is pointing to minikube
docker context ls
```

**⚠️ Critical**: This step is essential - without it, your locally built images won't be available to Kubernetes.

## 🔄 CI/CD Pipeline Flow (Production)

Your repository includes an advanced GitHub Actions workflow with smart change detection and manual deployment options:

```
Code Push/Manual → Change Detection → Tests → Build Changed → Deploy → Verify
     ↓               ↓                ↓         ↓              ↓        ↓
  master/develop   Path Filters    Conditional  Matrix Build   kubectl   Health Check
  or Manual        (api/worker/    Testing      (Only Changed   apply    + Rollout
  Dispatch         frontend)       Services     Services)               Status
```

**Key Workflow Features:**

1. **Smart Change Detection**: Only builds/deploys services that actually changed
2. **Manual Deployment**: Workflow dispatch with options to:
   - Choose specific service (`all`, `api-service`, `worker-service`, `frontend-service`)
   - Select branch (`master`, `develop`)
   - Force build even without changes
   - Skip tests for hotfixes

3. **Conditional Processing**: 
   - Tests run only for changed services
   - Matrix builds run in parallel for efficiency
   - Skip unchanged services automatically

4. **Environment Management**:
   - Environment-specific secrets and variables
   - Branch-based environment selection
   - Kubernetes config per environment

5. **Deployment Safety**:
   - Waits for rollout completion with timeout
   - Shows deployment summary
   - Rollback capability (via `scripts/rollback.sh`)

**Typical Flow:**
- **Automatic**: Push to `master` → Detect changes → Test → Build changed services → Deploy
- **Manual**: GitHub UI → Select service & branch → Force build option → Deploy specific service

## 🚀 One-Command Deployment

### Step 5: Run Deployment Script

```bash
# Navigate to your project root
cd microservices-app

# Make the deployment script executable (if not already)
chmod +x scripts/deploy.sh

# Run the complete deployment
./scripts/deploy.sh
```

**Expected Output:**
```
=== Minikube Deployment Script ===
Building Docker images...
[+] Building 2.3s (10/10) FINISHED
Creating namespace...
namespace/microservices created
Deploying database...
deployment.apps/postgres created
service/postgres-service created
Waiting for database to be ready...
pod/postgres-686b698df8-ksx87 condition met
Deploying API service...
deployment.apps/api-service created
service/api-service created
Deploying worker service...
deployment.apps/worker-service created
Deploying frontend service...
deployment.apps/frontend-service created
service/frontend-service created
Deployment complete!
=== Access Information ===
Minikube IP: 192.168.49.2
```

### Step 6: Verify Deployment Health

```bash
# Run health check script
./scripts/health-check.sh
```

### Step 7: Access Your Application

```bash
# Get service URLs
minikube service list -n microservices

# Access frontend (opens in browser or shows URL)
minikube service frontend-service -n microservices --url

# Access API (may need to run in separate terminal tab)  
minikube service api-service -n microservices --url
```

**💡 Pro Tip**: You may need to run the frontend and API service access commands in different terminal tabs since `minikube service` can occupy the terminal session.

**Alternative - Get URLs without blocking terminal:**
```bash
# Get all service URLs at once
minikube service list -n microservices

# Or get specific URLs
echo "Frontend: http://$(minikube ip):$(kubectl get svc frontend-service -n microservices -o jsonpath='{.spec.ports[0].nodePort}')"
echo "API: http://$(minikube ip):$(kubectl get svc api-service -n microservices -o jsonpath='{.spec.ports[0].nodePort}')/api"
```

## 🔧 Common Issues & Debugging Guide

### Issue 1: "ImagePullBackOff" or "ErrImagePull"

**Symptoms:**
```bash
kubectl get pods -n microservices
NAME                               READY   STATUS             RESTARTS   AGE
api-service-xxx                    0/1     ImagePullBackOff   0          1m
```

**Root Cause:** Kubernetes can't find your Docker images because they were built in local Docker, not Minikube's Docker.

**Solution:**
```bash
# 1. Set Minikube Docker environment (if not done)
eval $(minikube docker-env)

# 2. Rebuild images
docker build -t api-service:latest ./api-service
docker build -t frontend-service:latest ./frontend-service
docker build -t worker-service:latest ./worker-service

# 3. Verify images exist in Minikube
docker images | grep -E "(frontend-service|api-service|worker-service)"

# 4. Restart the failed deployment
kubectl rollout restart deployment/api-service -n microservices
```

**Debugging Commands:**
```bash
# Check detailed pod description
kubectl describe pod api-service-xxx -n microservices

# Look for "Events" section - it will show image pull errors
```

### Issue 2: Database Connection Failures

**Symptoms:**
```bash
kubectl logs api-service-xxx -n microservices
# Error: connect ECONNREFUSED postgres-service:5432
```

**Root Cause:** API service trying to connect before PostgreSQL is fully ready.

**Solution:**
```bash
# 1. Check if postgres pod is running
kubectl get pods -n microservices | grep postgres

# 2. Check postgres logs for startup completion
kubectl logs postgres-xxx -n microservices | tail -20

# 3. Test database connectivity
kubectl exec -it postgres-xxx -n microservices -- pg_isready -U postgres

# 4. If postgres is ready, restart API service
kubectl rollout restart deployment/api-service -n microservices
```

**Advanced Debugging:**
```bash
# Test connection from API pod to postgres
kubectl exec -it api-service-xxx -n microservices -- nslookup postgres-service

# Check if postgres service endpoints are available
kubectl get endpoints postgres-service -n microservices
```

### Issue 3: "CrashLoopBackOff" Status

**Symptoms:**
```bash
kubectl get pods -n microservices
NAME                               READY   STATUS             RESTARTS   AGE
worker-service-xxx                 0/1     CrashLoopBackOff   5          5m
```

**Debugging Steps:**
```bash
# 1. Check pod logs (most important)
kubectl logs worker-service-xxx -n microservices

# 2. Check previous container logs if current container crashed
kubectl logs worker-service-xxx -n microservices --previous

# 3. Check pod events
kubectl describe pod worker-service-xxx -n microservices

# 4. Check resource limits (common cause)
kubectl top pod worker-service-xxx -n microservices
```

**Common Fixes:**
- **Memory issues**: Increase memory limits in deployment.yaml
- **Missing environment variables**: Check configmap/secret references
- **Application errors**: Fix code issues and rebuild image

### Issue 4: Services Not Accessible

**Symptoms:**
- `minikube service` command doesn't work
- Can't access application URLs
- Terminal gets blocked by service commands

**Debugging:**
```bash
# 1. Check if minikube is running
minikube status

# 2. Check service configuration
kubectl get svc -n microservices -o wide

# 3. Check if NodePort is assigned
kubectl describe svc frontend-service -n microservices

# 4. Get minikube IP
minikube ip

# 5. Check ingress status (if using ingress)
kubectl get ingress -n microservices
```

**Solutions:**
```bash
# Option 1: Use port-forward for testing (run in separate terminal)
kubectl port-forward svc/frontend-service 8080:80 -n microservices
# Then access: http://localhost:8080

# Option 2: Get URLs without blocking terminal
minikube service list -n microservices

# Option 3: Use minikube tunnel (for LoadBalancer services - separate terminal)
minikube tunnel

# Option 4: Direct IP access
echo "Frontend: http://$(minikube ip):$(kubectl get svc frontend-service -n microservices -o jsonpath='{.spec.ports[0].nodePort}')"
```

**💡 Remember**: Commands like `minikube service`, `kubectl port-forward`, and `minikube tunnel` occupy the terminal. Run them in separate terminal tabs or use the direct IP access method.

### Issue 5: Persistent Volume Issues

**Symptoms:**
```bash
kubectl get pods -n microservices
NAME                               READY   STATUS    RESTARTS   AGE
postgres-xxx                       0/1     Pending   0          2m
```

**Check PVC Status:**
```bash
# Check if PVC is bound
kubectl get pvc -n microservices

# If status is "Pending", check storage class
kubectl get storageclass

# Check PVC details
kubectl describe pvc postgres-pvc -n microservices
```

**Solutions:**
```bash
# For minikube, ensure default storage class exists
kubectl get storageclass standard

# If no default storage class, create or patch existing
kubectl patch storageclass standard -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# Delete and recreate PVC if needed
kubectl delete pvc postgres-pvc -n microservices
kubectl apply -f k8s/database/postgres-pvc.yaml
```

## 🔍 Essential Debugging Commands

### Pod Debugging
```bash
# Get detailed pod information
kubectl describe pod <pod-name> -n microservices

# View pod logs (current)
kubectl logs <pod-name> -n microservices

# View pod logs (previous container)
kubectl logs <pod-name> -n microservices --previous

# Follow logs in real-time
kubectl logs -f <pod-name> -n microservices

# Execute commands inside pod
kubectl exec -it <pod-name> -n microservices -- /bin/sh
```

### Service & Network Debugging
```bash
# Test DNS resolution
kubectl exec -it <pod-name> -n microservices -- nslookup <service-name>

# Check service endpoints
kubectl get endpoints -n microservices

# Test connectivity between pods
kubectl exec -it <pod1> -n microservices -- curl http://<service-name>:port/health
```

### Resource Monitoring
```bash
# Check resource usage
kubectl top pods -n microservices
kubectl top nodes

# Check resource limits and requests
kubectl describe pod <pod-name> -n microservices | grep -A5 "Limits\|Requests"
```

## 🚦 Deployment Status Verification

### Health Check Sequence
```bash
# 1. All pods running?
kubectl get pods -n microservices

# 2. Services have endpoints?
kubectl get endpoints -n microservices

# 3. Database accessible?
kubectl exec -it postgres-xxx -n microservices -- pg_isready

# 4. API service responding?
kubectl exec -it api-service-xxx -n microservices -- curl localhost:3000/health

# 5. Frontend accessible via service?
minikube service frontend-service -n microservices --url
```

## 🔄 Quick Recovery Commands

### Rollback Deployment
```bash
# Use the rollback script for quick recovery
./scripts/rollback.sh

# Or manually rollback specific service
kubectl rollout undo deployment/api-service -n microservices
```

### Restart Deployments
```bash
# Restart specific service
kubectl rollout restart deployment/api-service -n microservices

# Restart all deployments
kubectl rollout restart deployment -n microservices

# Check rollout status
kubectl rollout status deployment/api-service -n microservices
```

### Clean Restart (Nuclear Option)
```bash
# Delete all pods (they will recreate)
kubectl delete pods --all -n microservices

# Or delete entire namespace and redeploy
kubectl delete namespace microservices
kubectl apply -f k8s/
```

## 💡 Pro Tips

1. **Always check logs first**: `kubectl logs <pod-name> -n microservices`
2. **Use describe for events**: `kubectl describe pod <pod-name> -n microservices`
3. **Verify Docker environment**: Run `eval $(minikube docker-env)` in each terminal session
4. **Wait for database**: Always ensure postgres is ready before deploying dependent services
5. **Check resource limits**: Many crashes are due to insufficient memory/CPU limits
6. **Use separate terminal tabs**: Commands like `minikube service`, `kubectl port-forward`, and `minikube tunnel` occupy the terminal - run them in separate tabs
7. **Keep minikube running**: Don't stop minikube between deployments unless necessary

## 🆘 When All Else Fails

```bash
# Complete cleanup and restart
minikube stop
minikube start --driver=docker --cpus=4 --memory=8192
eval $(minikube docker-env)

# Rebuild everything
docker build -t frontend-service:latest ./frontend-service
docker build -t api-service:latest ./api-service  
docker build -t worker-service:latest ./worker-service

# Redeploy step by step
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/database/
kubectl wait --for=condition=ready pod -l app=postgres -n microservices --timeout=300s
kubectl apply -f k8s/api-service/
kubectl apply -f k8s/worker-service/
kubectl apply -f k8s/frontend-service/
```

---

**Remember**: Most deployment issues are caused by:
1. Images not built in Minikube's Docker environment
2. Services trying to connect before dependencies are ready  
3. Resource constraints (memory/CPU)
4. Configuration errors in manifests

Always start debugging with `kubectl logs` and `kubectl describe` 
