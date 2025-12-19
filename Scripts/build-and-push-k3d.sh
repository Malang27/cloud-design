#!/bin/bash

# Script pour build et push les images Docker vers Docker Hub
# Usage: ./Scripts/build-and-push-k3d.sh <votre-username-dockerhub>

set -e

if [ -z "$1" ]; then
    echo "Usage: ./Scripts/build-and-push-k3d.sh <dockerhub-username>"
    echo "Example: ./Scripts/build-and-push-k3d.sh johndoe"
    exit 1
fi

DOCKERHUB_USERNAME=$1

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Build et Push des Images Docker vers Docker Hub      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Docker Hub Username: $DOCKERHUB_USERNAME"
echo ""

# Liste des images à build
IMAGES=("inventory-db" "billing-db" "inventory-app" "billing-app" "rabbitmq" "api-gateway")

for IMAGE in "${IMAGES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Building $IMAGE..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    cd Dockerfiles/$IMAGE

    # Build l'image
    docker build -t $DOCKERHUB_USERNAME/$IMAGE:latest .

    if [ $? -eq 0 ]; then
        echo "✓ Build réussi pour $IMAGE"

        # Push l'image
        echo "Pushing $DOCKERHUB_USERNAME/$IMAGE:latest..."
        docker push $DOCKERHUB_USERNAME/$IMAGE:latest

        if [ $? -eq 0 ]; then
            echo "✓ Push réussi pour $IMAGE"
        else
            echo "✗ Échec du push pour $IMAGE"
            cd ../..
            exit 1
        fi
    else
        echo "✗ Échec du build pour $IMAGE"
        cd ../..
        exit 1
    fi

    cd ../..
    echo ""
done

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Toutes les Images sont sur Docker Hub !         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Images disponibles:"
for IMAGE in "${IMAGES[@]}"; do
    echo "  - $DOCKERHUB_USERNAME/$IMAGE:latest"
done
echo ""
echo "Prochaine étape:"
echo "  1. Mettre à jour les manifestes:"
echo "     find Manifests/ -name '*.yaml' -exec sed -i 's/<YOUR_DOCKERHUB_USERNAME>/$DOCKERHUB_USERNAME/g' {} +"
echo ""
echo "  2. Déployer les applications:"
echo "     kubectl apply -f Manifests/"
