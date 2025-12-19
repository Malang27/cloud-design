#!/bin/bash

# Script de diagnostic rapide du cluster K3s
# Usage: ./Scripts/check-cluster.sh

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║            Diagnostic du Cluster K3s                      ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[!]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

# 1. Vérifier Vagrant
echo "1. État des VMs Vagrant:"
vagrant status
echo ""

# 2. Vérifier le fichier kubeconfig
if [ -f ".kube/config" ]; then
    log_info "Fichier kubeconfig existe"
else
    log_error "Fichier kubeconfig manquant"
    exit 1
fi
echo ""

# 3. Vérifier la connexion SSH
echo "2. Test connexion SSH au master:"
if vagrant ssh k3s-master -c "echo 'SSH OK'" &>/dev/null; then
    log_info "SSH fonctionne"
else
    log_error "SSH ne fonctionne pas"
    echo "   Essayez: vagrant reload k3s-master"
    exit 1
fi
echo ""

# 4. Vérifier le service K3s
echo "3. État du service K3s:"
K3S_STATUS=$(vagrant ssh k3s-master -c "sudo systemctl is-active k3s" 2>/dev/null || echo "error")

if [ "$K3S_STATUS" == "active" ]; then
    log_info "Service K3s est actif"
elif [ "$K3S_STATUS" == "inactive" ]; then
    log_warn "Service K3s est inactif"
    echo "   Redémarrage..."
    vagrant ssh k3s-master -c "sudo systemctl start k3s"
    sleep 10
    log_info "Service K3s redémarré"
else
    log_error "Impossible de vérifier le service K3s"
fi
echo ""

# 5. Vérifier kubectl dans la VM
echo "4. Test kubectl dans la VM:"
if vagrant ssh k3s-master -c "kubectl get nodes" &>/dev/null; then
    log_info "kubectl fonctionne dans la VM"
    vagrant ssh k3s-master -c "kubectl get nodes"
else
    log_error "kubectl ne fonctionne pas dans la VM"
fi
echo ""

# 6. Vérifier kubectl depuis l'hôte
echo "5. Test kubectl depuis l'hôte:"
export KUBECONFIG=$(pwd)/.kube/config

if kubectl get nodes &>/dev/null; then
    log_info "kubectl fonctionne depuis l'hôte"
    kubectl get nodes
else
    log_error "kubectl ne fonctionne pas depuis l'hôte"
    echo ""
    echo "Solutions:"
    echo "  1. Attendre 30 secondes et réessayer"
    echo "  2. Redémarrer K3s: vagrant ssh k3s-master -c 'sudo systemctl restart k3s'"
    echo "  3. Reloader la VM: vagrant reload k3s-master"
fi
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Diagnostic Terminé                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
