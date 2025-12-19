#!/usr/bin/env bash

#===============================================================================
# Orchestrator Script for K3s Microservices Deployment
# Usage: ./orchestrator.sh {create|start|stop|delete|status}
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MANIFESTS_DIR="$PROJECT_ROOT/Manifests"

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

    # Check if vagrant is installed
    if ! command -v vagrant &> /dev/null; then
        log_error "Vagrant is not installed. Please install Vagrant first."
        exit 1
    fi

    # Check if kubectl is installed
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed. Please install kubectl first."
        exit 1
    fi

    log_success "All prerequisites are met"
}

wait_for_cluster() {
    log_info "Waiting for K3s cluster to be ready..."
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
        sleep 10
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

#===============================================================================
# Main Functions
#===============================================================================

create_cluster() {
    log_info "Creating K3s cluster..."

    cd "$PROJECT_ROOT"

    # Start Vagrant VMs
    log_info "Starting Vagrant VMs..."
    vagrant up

    # Set KUBECONFIG
    export KUBECONFIG="$PROJECT_ROOT/.kube/config"

    # Wait for cluster to be ready
    wait_for_cluster

    # Deploy applications
    deploy_applications

    log_success "Cluster created successfully!"
}

deploy_applications() {
    log_info "Deploying applications to K3s cluster..."

    export KUBECONFIG="$PROJECT_ROOT/.kube/config"

    # Apply secrets first
    log_info "Creating secrets..."
    kubectl apply -f "$MANIFESTS_DIR/secrets.yaml"

    # Deploy StatefulSets (databases)
    log_info "Deploying databases (StatefulSets)..."
    kubectl apply -f "$MANIFESTS_DIR/statefulsets/inventory-db.yaml"
    kubectl apply -f "$MANIFESTS_DIR/statefulsets/billing-db.yaml"

    # Wait for databases
    log_info "Waiting for databases to be ready..."
    sleep 20
    kubectl wait --for=condition=ready pod -l app=inventory-db --timeout=180s || true
    kubectl wait --for=condition=ready pod -l app=billing-db --timeout=180s || true

    # Deploy RabbitMQ
    log_info "Deploying RabbitMQ..."
    kubectl apply -f "$MANIFESTS_DIR/deployments/rabbitmq.yaml"
    kubectl apply -f "$MANIFESTS_DIR/services/rabbitmq-service.yaml"

    # Wait for RabbitMQ
    log_info "Waiting for RabbitMQ to be ready..."
    sleep 20
    kubectl wait --for=condition=ready pod -l app=rabbitmq --timeout=120s || true

    # Deploy applications
    log_info "Deploying applications..."
    kubectl apply -f "$MANIFESTS_DIR/deployments/inventory-app.yaml"
    kubectl apply -f "$MANIFESTS_DIR/statefulsets/billing-app.yaml"
    kubectl apply -f "$MANIFESTS_DIR/deployments/api-gateway.yaml"

    # Deploy services
    log_info "Creating services..."
    kubectl apply -f "$MANIFESTS_DIR/services/inventory-db-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/services/billing-db-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/services/inventory-app-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/services/billing-app-service.yaml"
    kubectl apply -f "$MANIFESTS_DIR/services/api-gateway-service.yaml"

    # Deploy HPA
    log_info "Configuring auto-scaling (HPA)..."
    kubectl apply -f "$MANIFESTS_DIR/hpa/api-gateway-hpa.yaml"
    kubectl apply -f "$MANIFESTS_DIR/hpa/inventory-app-hpa.yaml"

    # Wait for all pods
    log_info "Waiting for all applications to be ready..."
    sleep 30
    wait_for_pods default

    # Display deployment status
    log_success "Applications deployed successfully!"
    echo ""
    log_info "Deployment status:"
    kubectl get all
    echo ""
    log_info "API Gateway accessible at: http://192.168.56.110:30000"
}

start_cluster() {
    log_info "Starting K3s cluster..."

    cd "$PROJECT_ROOT"
    vagrant up

    export KUBECONFIG="$PROJECT_ROOT/.kube/config"
    wait_for_cluster

    log_success "Cluster started"
}

stop_cluster() {
    log_info "Stopping K3s cluster..."

    cd "$PROJECT_ROOT"
    vagrant halt

    log_success "Cluster stopped"
}

delete_cluster() {
    log_info "Deleting K3s cluster..."

    cd "$PROJECT_ROOT"

    # Delete all Kubernetes resources
    export KUBECONFIG="$PROJECT_ROOT/.kube/config"
    if kubectl get nodes &> /dev/null; then
        log_info "Cleaning up Kubernetes resources..."
        kubectl delete -f "$MANIFESTS_DIR/hpa/" --ignore-not-found=true || true
        kubectl delete -f "$MANIFESTS_DIR/services/" --ignore-not-found=true || true
        kubectl delete -f "$MANIFESTS_DIR/deployments/" --ignore-not-found=true || true
        kubectl delete -f "$MANIFESTS_DIR/statefulsets/" --ignore-not-found=true || true
        kubectl delete -f "$MANIFESTS_DIR/secrets.yaml" --ignore-not-found=true || true
        kubectl delete pvc --all --ignore-not-found=true || true
    fi

    # Destroy Vagrant VMs
    log_info "Destroying Vagrant VMs..."
    vagrant destroy -f

    # Clean up local files
    rm -rf "$PROJECT_ROOT/.kube" "$PROJECT_ROOT/.k3s-token" "$PROJECT_ROOT/.vagrant"

    log_success "Cluster deleted"
}

show_status() {
    export KUBECONFIG="$PROJECT_ROOT/.kube/config"

    if ! kubectl get nodes &> /dev/null; then
        log_warning "Cluster is not running"
        return 1
    fi

    echo "========================================="
    echo "           CLUSTER STATUS"
    echo "========================================="
    echo ""

    log_info "Nodes:"
    kubectl get nodes
    echo ""

    log_info "All resources:"
    kubectl get all
    echo ""

    log_info "PersistentVolumeClaims:"
    kubectl get pvc
    echo ""

    log_info "Horizontal Pod Autoscalers:"
    kubectl get hpa
    echo ""

    log_info "Secrets:"
    kubectl get secrets
}

show_usage() {
    cat << EOF
Usage: $0 {create|start|stop|delete|status}

Commands:
    create      Create and deploy the entire K3s cluster and applications
    start       Start the K3s cluster
    stop        Stop the K3s cluster
    delete      Delete the K3s cluster and all resources
    status      Show cluster status

Examples:
    $0 create      # Create new cluster and deploy apps
    $0 start       # Start existing cluster
    $0 stop        # Stop cluster (VMs still exist)
    $0 delete      # Completely remove cluster
    $0 status      # Check cluster status

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
    *)
        show_usage
        exit 1
        ;;
esac
