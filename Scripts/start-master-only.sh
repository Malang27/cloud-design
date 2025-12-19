#!/bin/bash

# Script pour démarrer seulement le master K3s
# Usage: ./Scripts/start-master-only.sh

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║      Démarrage du Master K3s uniquement (1 nœud)         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

if [ ! -f "Vagrantfile" ]; then
    log_error "Vagrantfile non trouvé"
    exit 1
fi

# Nettoyer complètement
log_info "Nettoyage complet..."
vagrant destroy -f 2>/dev/null || true
rm -rf .vagrant/ .kube/ .k3s-token

log_info "Démarrage du master seulement (cela peut prendre 5-10 minutes)..."
log_warn "Note: Ceci créera un cluster à 1 nœud (sans agent)"
echo ""

# Démarrer seulement le master
vagrant up k3s-master --provider=virtualbox

if [ $? -ne 0 ]; then
    log_error "Échec du démarrage du master"
    log_error ""
    log_error "Essayez de voir les logs avec: vagrant up k3s-master --debug"
    exit 1
fi

log_info "✓ Master démarré"
echo ""

# Vérifier le kubeconfig
if [ ! -f ".kube/config" ]; then
    log_error "Fichier kubeconfig non trouvé"
    log_error "Le master n'a peut-être pas terminé son provisioning"
    exit 1
fi

log_info "Configuration de kubectl..."
export KUBECONFIG=$(pwd)/.kube/config

# Attendre que le nœud soit prêt
log_info "Attente que le nœud master soit prêt..."
TIMEOUT=180
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    READY=$(kubectl get nodes 2>/dev/null | grep -c " Ready " || echo "0")

    if [ "$READY" -ge "1" ]; then
        log_info "✓ Le nœud master est prêt !"
        break
    fi

    echo -n "."
    sleep 5
    ELAPSED=$(($ELAPSED + 5))
done

echo ""

if [ $ELAPSED -ge $TIMEOUT ]; then
    log_warn "Timeout: Le nœud n'est pas prêt après 3 minutes"
    log_warn "Vérifiez manuellement avec:"
    log_warn "  export KUBECONFIG=\$(pwd)/.kube/config"
    log_warn "  kubectl get nodes"
    exit 1
fi

echo ""
log_info "État du cluster (1 nœud):"
kubectl get nodes
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            Cluster K3s Prêt (Master uniquement) !        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "✓ Cluster à 1 nœud fonctionnel"
echo ""
echo "Configuration kubectl:"
echo "  export KUBECONFIG=$(pwd)/.kube/config"
echo ""
echo "Commandes utiles:"
echo "  kubectl get nodes"
echo "  kubectl get pods -A"
echo "  vagrant ssh k3s-master"
echo ""
echo "Pour déployer les applications (sur 1 nœud):"
echo "  ./Scripts/orchestrator.sh create"
echo ""
echo "Pour ajouter l'agent plus tard:"
echo "  vagrant up k3s-agent"
echo ""
