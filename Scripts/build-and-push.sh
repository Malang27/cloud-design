#!/usr/bin/env bash

#===============================================================================
# Docker Image Build and Push Script
# Builds all Docker images and pushes them to Docker Hub
# Usage: ./build-and-push.sh <dockerhub-username>
#===============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKERFILES_DIR="$PROJECT_ROOT/Dockerfiles"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ -z "$1" ]; then
    log_error "Docker Hub username required"
    echo "Usage: $0 <dockerhub-username>"
    echo "Example: $0 myusername"
    exit 1
fi

DOCKERHUB_USERNAME="$1"

log_info "Docker Hub username: $DOCKERHUB_USERNAME"
log_info "Building and pushing Docker images..."

# Login to Docker Hub
log_info "Logging in to Docker Hub..."
docker login

# Array of services to build
declare -A SERVICES
SERVICES=(
    ["inventory-db"]="$DOCKERFILES_DIR/inventory-db"
    ["billing-db"]="$DOCKERFILES_DIR/billing-db"
    ["rabbitmq"]="$DOCKERFILES_DIR/rabbitmq"
    ["inventory-app"]="$DOCKERFILES_DIR/inventory-app"
    ["billing-app"]="$DOCKERFILES_DIR/billing-app"
    ["api-gateway"]="$DOCKERFILES_DIR/api-gateway"
)

# Build and push each service
for service in "${!SERVICES[@]}"; do
    context_dir="${SERVICES[$service]}"
    image_name="$DOCKERHUB_USERNAME/$service:latest"

    log_info "Building $service..."
    docker build -t "$image_name" "$context_dir"

    log_info "Pushing $image_name to Docker Hub..."
    docker push "$image_name"

    log_success "$service image built and pushed successfully"
    echo ""
done

log_success "All images have been built and pushed to Docker Hub!"

echo ""
echo "================================================================"
echo "  Update your Kubernetes manifests with your Docker Hub username"
echo "  Replace <YOUR_DOCKERHUB_USERNAME> with: $DOCKERHUB_USERNAME"
echo "================================================================"
echo ""
echo "Use this command to update all manifests:"
echo "find Manifests/ -type f -name '*.yaml' -exec sed -i 's/<YOUR_DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g' {} +"
