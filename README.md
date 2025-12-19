# Orchestrator - Kubernetes Microservices Deployment

A complete Kubernetes (K3s) deployment solution for a microservices architecture with auto-scaling, persistent storage, and high availability.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Configuration](#configuration)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)
- [Kubernetes Concepts](#kubernetes-concepts)
- [Security](#security)
- [Contributing](#contributing)

## Overview

This project deploys a complete microservices architecture on a K3s Kubernetes cluster using:

- **K3s**: Lightweight Kubernetes distribution
- **Vagrant**: Infrastructure provisioning (2 VMs: master + agent)
- **Docker**: Container runtime
- **Kubernetes Manifests**: Infrastructure as Code (IaC)

### Services Deployed

| Service | Type | Port | Auto-scaling | Replicas |
|---------|------|------|--------------|----------|
| **inventory-db** | StatefulSet | 5432 | No | 1 |
| **billing-db** | StatefulSet | 5432 | No | 1 |
| **inventory-app** | Deployment | 8080 | Yes (1-3) | 1-3 |
| **billing-app** | StatefulSet | 8080 | No | 1 |
| **rabbitmq** | Deployment | 5672 | No | 1 |
| **api-gateway** | Deployment | 3000 | Yes (1-3) | 1-3 |

## Architecture

```
                     ┌─────────────────┐
                     │  API Gateway    │  ← NodePort 30000
                     │  (Deployment)   │     (External Access)
                     └────────┬────────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
        ┌────────▼────────┐       ┌───────▼────────┐
        │  Inventory App  │       │  Billing App   │
        │  (Deployment)   │       │  (StatefulSet) │
        │  HPA: 1-3       │       │  Replicas: 1   │
        └────────┬────────┘       └───────┬────────┘
                 │                        │
      ┌──────────▼──────────┐    ┌────────▼────────┐
      │  Inventory DB       │    │  Billing DB     │
      │  (StatefulSet)      │    │  (StatefulSet)  │
      │  PVC: 1Gi           │    │  PVC: 1Gi       │
      └─────────────────────┘    └─────────────────┘
                                         │
                                  ┌──────▼──────┐
                                  │  RabbitMQ   │
                                  │ (Deployment)│
                                  └─────────────┘
```

### Network Architecture

- **Master Node**: 192.168.56.110
- **Agent Node**: 192.168.56.111
- **API Gateway External Access**: http://192.168.56.110:30000
- **Pod Network**: 10.42.0.0/16
- **Service Network**: 10.43.0.0/16

## Prerequisites

### Required Software

| Software | Version | Purpose |
|----------|---------|---------|
| **Vagrant** | 2.3+ | VM provisioning |
| **VirtualBox** | 6.1+ | Virtualization |
| **kubectl** | 1.28+ | Kubernetes CLI |
| **Docker** | 20.10+ | Image building |

### System Requirements

- **RAM**: Minimum 6GB (4GB for VMs + 2GB for host)
- **CPU**: 4+ cores recommended
- **Disk**: 20GB free space
- **OS**: Linux, macOS, or Windows with WSL2

### Installation Commands

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y vagrant virtualbox kubectl docker.io

# macOS (using Homebrew)
brew install vagrant virtualbox kubectl docker

# Windows (using Chocolatey)
choco install vagrant virtualbox kubernetes-cli docker-desktop
```

### Verify Installation

```bash
vagrant --version
vboxmanage --version
kubectl version --client
docker --version
```

## Project Structure

```
orchestrator/
├── Manifests/                    # Kubernetes manifests
│   ├── secrets.yaml             # Credentials (passwords, tokens)
│   ├── statefulsets/            # Stateful applications
│   │   ├── inventory-db.yaml
│   │   ├── billing-db.yaml
│   │   └── billing-app.yaml
│   ├── deployments/             # Stateless applications
│   │   ├── inventory-app.yaml
│   │   ├── api-gateway.yaml
│   │   └── rabbitmq.yaml
│   ├── services/                # Service definitions
│   │   ├── inventory-db-service.yaml
│   │   ├── billing-db-service.yaml
│   │   ├── inventory-app-service.yaml
│   │   ├── billing-app-service.yaml
│   │   ├── rabbitmq-service.yaml
│   │   └── api-gateway-service.yaml
│   └── hpa/                     # Horizontal Pod Autoscalers
│       ├── api-gateway-hpa.yaml
│       └── inventory-app-hpa.yaml
├── Scripts/                     # Automation scripts
│   ├── orchestrator.sh          # Main orchestration script
│   └── build-and-push.sh        # Docker build & push
├── Dockerfiles/                 # Docker images
│   ├── inventory-db/
│   ├── billing-db/
│   ├── rabbitmq/
│   ├── inventory-app/
│   ├── billing-app/
│   └── api-gateway/
├── Vagrantfile                  # VM configuration
└── README.md                    # This file
```

## Configuration

### 1. Docker Hub Setup

Create a Docker Hub account if you don't have one:
https://hub.docker.com/signup

### 2. Build and Push Docker Images

```bash
# Build all images and push to Docker Hub
cd Scripts/
./build-and-push.sh <your-dockerhub-username>

# Example:
./build-and-push.sh johndoe
```

### 3. Update Kubernetes Manifests

After pushing images, update the manifests with your Docker Hub username:

```bash
# Automated update (Linux/macOS)
find Manifests/ -type f -name '*.yaml' -exec sed -i 's/<YOUR_DOCKERHUB_USERNAME>/johndoe/g' {} +

# On macOS (BSD sed)
find Manifests/ -type f -name '*.yaml' -exec sed -i '' 's/<YOUR_DOCKERHUB_USERNAME>/johndoe/g' {} +

# Manual update
# Edit each */*.yaml file and replace <YOUR_DOCKERHUB_USERNAME> with your username
```

### 4. Customize Secrets (Optional)

Edit `Manifests/secrets.yaml` to change default passwords:

```yaml
stringData:
  INVENTORY_DB_PASSWORD: your_secure_password_here
  BILLING_DB_PASSWORD: your_secure_password_here
  RABBITMQ_PASSWORD: your_secure_password_here
```

**Important**: Never commit real passwords to Git!

## Installation

### Quick Start

```bash
# 1. Clone the repository
git clone <repository-url>
cd orchestrator

# 2. Build and push Docker images
./Scripts/build-and-push.sh <your-dockerhub-username>

# 3. Update manifests with your Docker Hub username
find Manifests/ -type f -name '*.yaml' -exec sed -i 's/<YOUR_DOCKERHUB_USERNAME>/yourusername/g' {} +

# 4. Create and deploy the cluster
./Scripts/orchestrator.sh create
```

This will:
1. Start 2 Vagrant VMs (master + agent)
2. Install K3s on both nodes
3. Deploy all microservices
4. Configure auto-scaling (HPA)
5. Setup persistent volumes

### Step-by-Step Installation

#### Step 1: Start the K3s Cluster

```bash
vagrant up
```

This takes approximately 5-10 minutes.

#### Step 2: Verify Cluster Status

```bash
# Set KUBECONFIG
export KUBECONFIG=$(pwd)/.kube/config

# Check nodes
kubectl get nodes

# Expected output:
# NAME         STATUS   ROLES                  AGE   VERSION
# k3s-master   Ready    control-plane,master   5m    v1.28.5+k3s1
# k3s-agent    Ready    <none>                 4m    v1.28.5+k3s1
```

#### Step 3: Deploy Applications

```bash
./Scripts/orchestrator.sh create
```

Or manually:

```bash
# Apply secrets
kubectl apply -f Manifests/secrets.yaml

# Deploy databases (StatefulSets)
kubectl apply -f Manifests/statefulsets/

# Deploy applications (Deployments)
kubectl apply -f Manifests/deployments/

# Create services
kubectl apply -f Manifests/services/

# Enable auto-scaling
kubectl apply -f Manifests/hpa/
```

#### Step 4: Verify Deployment

```bash
# Check all resources
kubectl get all

# Check pods
kubectl get pods

# Check services
kubectl get services

# Check HPA
kubectl get hpa
```

## Usage

### Orchestrator Script Commands

```bash
# Create cluster and deploy applications
./Scripts/orchestrator.sh create

# Start existing cluster
./Scripts/orchestrator.sh start

# Stop cluster (keep VMs)
./Scripts/orchestrator.sh stop

# Delete everything
./Scripts/orchestrator.sh delete

# Check cluster status
./Scripts/orchestrator.sh status
```

### Accessing Services

#### API Gateway (External Access)

```bash
# Get node IP
kubectl get nodes -o wide

# Access API Gateway
curl http://192.168.56.110:30000/health

# Or use the NodePort
curl http://192.168.56.110:30000/api/movies
```

#### Internal Service Access (from within cluster)

```bash
# SSH to master node
vagrant ssh k3s-master

# Access services by DNS
curl http://inventory-app.default.svc.cluster.local:8080/health
curl http://billing-app.default.svc.cluster.local:8080/health
curl http://api-gateway.default.svc.cluster.local:3000/health
```

### kubectl Common Commands

```bash
# Get all resources
kubectl get all

# Get pods with details
kubectl get pods -o wide

# Get specific resource
kubectl get deployment inventory-app

# Describe resource
kubectl describe pod <pod-name>

# View logs
kubectl logs <pod-name>

# Follow logs
kubectl logs -f <pod-name>

# Execute command in pod
kubectl exec -it <pod-name> -- /bin/sh

# Port forwarding (local access)
kubectl port-forward service/api-gateway 3000:3000

# Scale manually (overrides HPA temporarily)
kubectl scale deployment inventory-app --replicas=2
```

## Testing

### API Testing

#### 1. Create a Movie (POST)

```bash
curl -X POST http://192.168.56.110:30000/api/movies \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Inception",
    "description": "A mind-bending thriller"
  }'

# Expected: 200 OK
```

#### 2. List Movies (GET)

```bash
curl http://192.168.56.110:30000/api/movies

# Expected: JSON array with movies
```

#### 3. Create Billing Order (POST)

```bash
curl -X POST http://192.168.56.110:30000/api/billing \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "123",
    "number_of_items": "5",
    "total_amount": "99.99"
  }'

# Expected: 200 OK
```

### RabbitMQ Resilience Test

Test that messages are queued even when billing-app is down:

```bash
# 1. Stop billing-app
kubectl scale statefulset billing-app --replicas=0

# 2. Send billing request (should succeed)
curl -X POST http://192.168.56.110:30000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "999", "number_of_items": "10", "total_amount": "250"}'

# 3. Restart billing-app
kubectl scale statefulset billing-app --replicas=1

# 4. Wait for pod to be ready
kubectl wait --for=condition=ready pod -l app=billing-app --timeout=120s

# 5. Check database - order should be processed
kubectl exec -it billing-db-0 -- psql -U billing_user -d orders -c "SELECT * FROM orders WHERE user_id='999';"
```

### Auto-Scaling Test

Test HPA (Horizontal Pod Autoscaler):

```bash
# 1. Check current HPA status
kubectl get hpa

# 2. Generate load (install hey or ab)
hey -z 60s -c 50 http://192.168.56.110:30000/api/movies

# 3. Watch HPA scale up
kubectl get hpa -w

# 4. Watch pods scale
kubectl get pods -w

# Should scale from 1 to 2-3 replicas when CPU > 60%
```

### Database Persistence Test

Test that data survives pod restarts:

```bash
# 1. Create a movie
curl -X POST http://192.168.56.110:30000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Movie", "description": "Persistence test"}'

# 2. Delete inventory-db pod
kubectl delete pod inventory-db-0

# 3. Wait for pod to restart
kubectl wait --for=condition=ready pod/inventory-db-0 --timeout=180s

# 4. Verify movie still exists
curl http://192.168.56.110:30000/api/movies | grep "Test Movie"
```

## Monitoring

### Cluster Health

```bash
# Node status
kubectl get nodes

# Resource usage
kubectl top nodes
kubectl top pods

# Events
kubectl get events --sort-by='.lastTimestamp'

# Component status
kubectl get componentstatuses
```

### Application Logs

```bash
# View logs
kubectl logs -l app=api-gateway
kubectl logs -l app=inventory-app
kubectl logs -l app=billing-app

# Follow logs
kubectl logs -f <pod-name>

# Logs from all containers in pod
kubectl logs <pod-name> --all-containers=true

# Previous container logs (if crashed)
kubectl logs <pod-name> --previous
```

### Persistent Volumes

```bash
# List PVCs
kubectl get pvc

# Describe PVC
kubectl describe pvc postgres-data-inventory-db-0

# Check PV
kubectl get pv
```

## Troubleshooting

### Common Issues

#### Issue: Pods stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name>

# Common causes:
# - Insufficient resources
# - PVC not bound
# - Image pull errors
```

**Solution**:
```bash
# Check node resources
kubectl describe nodes

# Check PVC status
kubectl get pvc

# Check image name
kubectl describe pod <pod-name> | grep Image
```

#### Issue: Pods CrashLoopBackOff

```bash
# View logs
kubectl logs <pod-name>

# Common causes:
# - Application errors
# - Missing environment variables
# - Database not ready
```

**Solution**:
```bash
# Check environment variables
kubectl exec <pod-name> -- env

# Check secrets
kubectl get secrets
kubectl describe secret postgres-credentials

# Restart pod
kubectl delete pod <pod-name>
```

#### Issue: Services not accessible

```bash
# Check service
kubectl get svc api-gateway

# Check endpoints
kubectl get endpoints api-gateway

# Check pod labels
kubectl get pods --show-labels
```

**Solution**:
```bash
# Ensure pod labels match service selector
kubectl describe svc api-gateway
kubectl describe pod <pod-name>
```

#### Issue: HPA not scaling

```bash
# Check metrics-server
kubectl get deployment metrics-server -n kube-system

# Check HPA status
kubectl describe hpa api-gateway-hpa
```

**Solution**:
```bash
# In K3s, metrics-server is built-in but may need time to collect metrics
# Wait 2-3 minutes after deployment

# Verify metrics are available
kubectl top pods
```

#### Issue: Database connection failed

```bash
# Check database pod status
kubectl get pods -l app=inventory-db

# Check database service
kubectl get svc inventory-db

# Test connection from app pod
kubectl exec -it <inventory-app-pod> -- nc -zv inventory-db-0.inventory-db 5432
```

**Solution**:
```bash
# Verify StatefulSet DNS
# Format: <pod-name>.<service-name>.<namespace>.svc.cluster.local
# Example: inventory-db-0.inventory-db.default.svc.cluster.local

# Check app environment variable
kubectl exec <inventory-app-pod> -- env | grep DB_HOST
```

### Reset Cluster

If everything goes wrong:

```bash
# Delete all resources
./Scripts/orchestrator.sh delete

# Recreate from scratch
./Scripts/orchestrator.sh create
```

### Debug Mode

```bash
# SSH to master node
vagrant ssh k3s-master

# Check K3s status
sudo systemctl status k3s

# Check K3s logs
sudo journalctl -u k3s -f

# Check containerd
sudo k3s crictl ps
```

## Kubernetes Concepts

### Container Orchestration

**Container orchestration** is the automated process of managing, deploying, scaling, and networking containers.

**Benefits**:
- Automated deployment and scaling
- Load balancing
- Self-healing (restart failed containers)
- Service discovery
- Configuration management
- Storage orchestration

### Kubernetes (K8s)

**Kubernetes** is an open-source container orchestration platform for automating deployment, scaling, and management of containerized applications.

**Main roles**:
- Cluster management
- Container scheduling
- Service discovery and load balancing
- Auto-scaling
- Self-healing
- Storage orchestration
- Configuration and secret management

### K3s

**K3s** is a lightweight, certified Kubernetes distribution designed for IoT, edge, and resource-constrained environments.

**Main roles**:
- Simplified Kubernetes installation
- Reduced memory footprint (~512MB vs 4GB for full K8s)
- Single binary (<100MB)
- Perfect for development and testing

### Kubernetes Components

#### Control Plane Components

1. **kube-apiserver**: Frontend for Kubernetes API
2. **etcd**: Key-value store for cluster data
3. **kube-scheduler**: Assigns pods to nodes
4. **kube-controller-manager**: Runs controller processes
5. **cloud-controller-manager**: Links cluster to cloud provider APIs

#### Node Components

1. **kubelet**: Agent running on each node
2. **kube-proxy**: Network proxy
3. **container-runtime**: Docker/containerd/CRI-O

### Infrastructure as Code (IaC)

**Infrastructure as Code** is managing and provisioning infrastructure through machine-readable definition files.

**Advantages**:
- Version control
- Reproducibility
- Automation
- Documentation
- Collaboration
- Disaster recovery

### K8s Manifests

**Kubernetes manifests** are YAML/JSON files that describe desired state of Kubernetes resources.

**Components**:
- **apiVersion**: API version
- **kind**: Resource type (Pod, Service, Deployment, etc.)
- **metadata**: Name, labels, annotations
- **spec**: Desired state specification

**Example**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-app
  template:
    metadata:
      labels:
        app: my-app
    spec:
      containers:
      - name: app
        image: myimage:latest
```

### Deployment vs StatefulSet

#### Deployment

**Purpose**: For stateless applications

**Characteristics**:
- Pods are interchangeable
- No persistent identity
- Can scale up/down freely
- Rolling updates
- Random pod names

**Use cases**: Web servers, API services, stateless microservices

#### StatefulSet

**Purpose**: For stateful applications

**Characteristics**:
- Stable, unique network identities
- Persistent storage
- Ordered deployment and scaling
- Stable pod names (app-0, app-1, ...)
- Ordered updates

**Use cases**: Databases, message queues, any app requiring persistent state

**Why databases aren't deployments**:
- Databases need persistent storage
- Each instance needs stable network identity
- Data must survive pod restarts
- Ordered shutdown prevents data corruption

### Scaling

**Scaling** is adjusting the number of application instances to match load.

**Types**:
1. **Horizontal scaling** (scale out): Add more pods
2. **Vertical scaling** (scale up): Increase CPU/memory per pod

**Why we use it**:
- Handle varying load
- Ensure availability
- Optimize resource usage
- Cost efficiency
- Performance improvement

**Horizontal Pod Autoscaler (HPA)**:
- Automatically scales pods based on CPU/memory
- Min/max replicas defined
- Checks metrics every 15s (default)

### Load Balancer

**A load balancer** distributes network traffic across multiple servers/pods.

**Role**:
- Distribute load evenly
- Ensure high availability
- Improve responsiveness
- Prevent overload
- Enable horizontal scaling

**In Kubernetes**:
- **ClusterIP**: Internal load balancing (default)
- **NodePort**: Exposes service on each node's IP
- **LoadBalancer**: Creates external load balancer (cloud)

## Security

### Best Practices

1. **Secrets Management**
   - Never commit secrets to Git
   - Use Kubernetes Secrets
   - Consider external secret managers (Vault, AWS Secrets Manager)

2. **RBAC (Role-Based Access Control)**
   - Principle of least privilege
   - Separate service accounts per application

3. **Network Policies**
   - Restrict pod-to-pod communication
   - Whitelist allowed traffic

4. **Image Security**
   - Use specific image tags (not `latest`)
   - Scan images for vulnerabilities
   - Use trusted registries

5. **Resource Limits**
   - Set CPU/memory requests and limits
   - Prevent resource exhaustion

### Security Checklist

- [ ] Secrets stored in Kubernetes Secrets
- [ ] Resource limits defined for all pods
- [ ] Non-root containers where possible
- [ ] Image tags specified (not `latest`)
- [ ] Network policies configured
- [ ] RBAC enabled
- [ ] Audit logging enabled
- [ ] Regular security updates

## Contributing

### Development Workflow

1. Fork the repository
2. Create a feature branch
3. Make changes
4. Test locally
5. Submit pull request

### Testing Before Commit

```bash
# Validate YAML syntax
for f in Manifests/**/*.yaml; do
  kubectl apply --dry-run=client -f $f
done

# Test deployment
./Scripts/orchestrator.sh create
./Scripts/orchestrator.sh status
```

---

## License

MIT License - See LICENSE file for details

## Support

For issues, questions, or contributions:
- Open an issue on GitHub
- Contact: your-email@example.com

## Acknowledgments

- Built on top of the [play-with-containers](../play-with-containers) Docker Compose solution
- Uses Dockerfiles from the validated play-with-containers project
- K3s: https://k3s.io/
- Kubernetes: https://kubernetes.io/

---

**Made with ❤️ for learning Kubernetes and DevOps**
