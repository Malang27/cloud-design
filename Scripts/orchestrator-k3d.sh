#!/usr/bin/env bash

#===============================================================================
# Orchestrator Script for K3d Microservices Deployment
# Usage: ./orchestrator-k3d.sh {create|start|stop|delete|status|deploy}
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFESTS_DIR="$PROJECT_ROOT/Manifests"
CLUSTER_NAME="orchestrator"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#===============================================================================
# Helper Functions
#===============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if k3d is installed
    if ! command -v k3d &> /dev/null; then
        log_error "k3d is not installed. Please install k3d first."
        echo "Installation: curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash"
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    # Check if docker is running
    if ! docker ps &> /dev/null; then
        log_error "Docker is not running. Please start Docker Desktop."
        exit 1
    fi

    log_success "All prerequisites are met"
}

wait_for_cluster() {
    log_info "Waiting for K3d cluster to be ready..."
    local max_attempts=30
    local attempt=0

    while [ $attempt -lt $max_attempts ]; do
        if kubectl get nodes &> /dev/null; then
            log_success "Cluster is ready!"
            kubectl get nodes
            return 0
        fi
        attempt=$((attempt + 1))
        echo "Waiting for cluster... ($attempt/$max_attempts)"
        sleep 5
    done

    log_error "Cluster failed to become ready"
    return 1
}

wait_for_pods() {
    local namespace=${1:-default}
    log_info "Waiting for all pods to be ready in namespace '$namespace'..."

    kubectl wait --for=condition=ready pod --all -n $namespace --timeout=300s || true
    kubectl get pods -n $namespace
}

import_docker_images() {
    log_info "Checking if Docker images need to be imported..."

    local images=(
        "malang27/inventory-db:latest"
        "malang27/billing-db:latest"
        "malang27/inventory-app:latest"
        "malang27/billing-app:latest"
        "malang27/rabbitmq:latest"
        "malang27/api-gateway:latest"
    )

    # Check if images exist locally
    local missing_images=false
    for image in "${images[@]}"; do
        if ! docker image inspect "$image" &> /dev/null; then
            log_warning "Image $image not found locally"
            missing_images=true
        fi
    done

    if [ "$missing_images" = true ]; then
        log_warning "Some images are missing. They will be pulled from Docker Hub during deployment."
        return 0
    fi

    log_info "Importing Docker images into K3d cluster..."
    k3d image import "${images[@]}" --cluster "$CLUSTER_NAME"
    log_success "Docker images imported successfully"
}

#===============================================================================
# Main Functions
#===============================================================================

create_cluster() {
    log_info "Creating K3d cluster '$CLUSTER_NAME'..."

    # Check if cluster already exists
    if k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_warning "Cluster '$CLUSTER_NAME' already exists. Use 'start' to start it or 'delete' to remove it first."
        exit 1
    fi

    # Create K3d cluster
    log_info "Creating K3d cluster with 1 server and 1 agent..."
    k3d cluster create "$CLUSTER_NAME" \
        --servers 1 \
        --agents 1 \
        --port "30000:30000@loadbalancer" \
        --k3s-arg "--disable=traefik@server:0"

    # Wait for cluster to be ready
    wait_for_cluster

    # Import Docker images
    import_docker_images

    # Deploy applications
    deploy_applications

    log_success "Cluster created and applications deployed successfully!"
    echo ""
    log_info "API Gateway accessible at: http://localhost:30000/health"
}

deploy_applications() {
    log_info "Deploying applications to K3d cluster..."

    # Apply secrets first
    log_info "Creating secrets..."
    kubectl apply -f "$MANIFESTS_DIR/secrets.yaml"

    # Deploy StatefulSets (databases)
    log_info "Deploying databases (StatefulSets)..."
    kubectl apply -f "$MANIFESTS_DIR/statefulsets/"

    # Wait for databases
    log_info "Waiting for databases to be ready (this may take 1-2 minutes)..."
    sleep 30
    kubectl wait --for=condition=ready pod -l app=inventory-db --timeout=180s || true
    kubectl wait --for=condition=ready pod -l app=billing-db --timeout=180s || true

    # Deploy applications
    log_info "Deploying applications..."
    kubectl apply -f "$MANIFESTS_DIR/deployments/"

    # Deploy services
    log_info "Creating services..."
    kubectl apply -f "$MANIFESTS_DIR/services/"

    # Deploy HPA
    log_info "Configuring auto-scaling (HPA)..."
    kubectl apply -f "$MANIFESTS_DIR/hpa/"

    # Wait for all pods
    log_info "Waiting for all applications to be ready..."
    sleep 20
    wait_for_pods default

    # Display deployment status
    log_success "Applications deployed successfully!"
    echo ""
    log_info "Deployment status:"
    kubectl get all
    echo ""
    log_info "API Gateway: http://localhost:30000/health"
}

start_cluster() {
    log_info "Starting K3d cluster '$CLUSTER_NAME'..."

    # Check if cluster exists
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_error "Cluster '$CLUSTER_NAME' does not exist. Use 'create' to create it first."
        exit 1
    fi

    k3d cluster start "$CLUSTER_NAME"
    wait_for_cluster

    log_success "Cluster started"
    show_status
}

stop_cluster() {
    log_info "Stopping K3d cluster '$CLUSTER_NAME'..."

    # Check if cluster exists
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_error "Cluster '$CLUSTER_NAME' does not exist."
        exit 1
    fi

    k3d cluster stop "$CLUSTER_NAME"

    log_success "Cluster stopped"
}

delete_cluster() {
    log_info "Deleting K3d cluster '$CLUSTER_NAME'..."

    # Check if cluster exists
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_warning "Cluster '$CLUSTER_NAME' does not exist."
        exit 0
    fi

    k3d cluster delete "$CLUSTER_NAME"

    log_success "Cluster deleted"
}

show_status() {
    # Check if cluster exists
    if ! k3d cluster list | grep -q "$CLUSTER_NAME"; then
        log_warning "Cluster '$CLUSTER_NAME' does not exist"
        return 1
    fi

    # Check if cluster is running
    if ! kubectl get nodes &> /dev/null; then
        log_warning "Cluster is not running. Use './orchestrator-k3d.sh start' to start it."
        return 1
    fi

    echo "========================================="
    echo "           CLUSTER STATUS"
    echo "========================================="
    echo ""

    log_info "K3d Cluster:"
    k3d cluster list | grep "$CLUSTER_NAME" || true
    echo ""

    log_info "Nodes:"
    kubectl get nodes
    echo ""

    log_info "Pods:"
    kubectl get pods
    echo ""

    log_info "Services:"
    kubectl get svc
    echo ""

    log_info "PersistentVolumeClaims:"
    kubectl get pvc
    echo ""

    log_info "Horizontal Pod Autoscalers:"
    kubectl get hpa
    echo ""

    log_info "API Gateway:"
    echo "  Health Check: http://localhost:30000/health"
    echo ""

    # Test API Gateway
    if curl -s http://localhost:30000/health &> /dev/null; then
        log_success "API Gateway is responding!"
        curl -s http://localhost:30000/health | head -3
    else
        log_warning "API Gateway is not responding yet"
    fi
}

show_usage() {
    cat << EOF
Usage: $0 {create|start|stop|delete|status|deploy}

Commands:
    create      Create K3d cluster and deploy all applications
    start       Start existing K3d cluster
    stop        Stop K3d cluster (preserves data)
    delete      Delete K3d cluster completely
    status      Show cluster status
    deploy      Deploy/redeploy applications to existing cluster

Examples:
    $0 create      # Create new cluster and deploy apps
    $0 start       # Start existing cluster
    $0 stop        # Stop cluster (data preserved)
    $0 delete      # Completely remove cluster
    $0 status      # Check cluster status
    $0 deploy      # Deploy apps to existing cluster

Notes:
    - The cluster is named '$CLUSTER_NAME'
    - API Gateway is accessible at http://localhost:30000
    - Images are pulled from Docker Hub (malang27/*)

EOF
}

#===============================================================================
# Main Script Logic
#===============================================================================

case "${1:-}" in
    create)
        check_prerequisites
        create_cluster
        ;;
    start)
        start_cluster
        ;;
    stop)
        stop_cluster
        ;;
    delete)
        delete_cluster
        ;;
    status)
        show_status
        ;;
    deploy)
        check_prerequisites
        deploy_applications
        ;;
    *)
        show_usage
        exit 1
        ;;
esac