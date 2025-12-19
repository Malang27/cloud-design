#!/bin/bash

# Script pour démarrer le cluster K3s de manière robuste
# Usage: ./Scripts/start-cluster.sh

set -e

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         Démarrage du Cluster K3s - Version Robuste       ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Vérifier qu'on est dans le bon dossier
if [ ! -f "Vagrantfile" ]; then
    log_error "Vagrantfile non trouvé. Exécutez ce script depuis le dossier orchestrator."
    exit 1
fi

# Nettoyer l'état précédent si demandé
if [ "$1" == "--clean" ]; then
    log_info "Nettoyage de l'état précédent..."
    vagrant destroy -f 2>/dev/null || true
    rm -rf .vagrant/ .kube/ .k3s-token
    log_info "Nettoyage terminé."
    echo ""
fi

# Vérifier l'état des VMs
log_info "Vérification de l'état des VMs..."
MASTER_STATE=$(vagrant status k3s-master | grep "k3s-master" | awk '{print $2}')
AGENT_STATE=$(vagrant status k3s-agent | grep "k3s-agent" | awk '{print $2}')

echo "  Master: $MASTER_STATE"
echo "  Agent: $AGENT_STATE"
echo ""

# Démarrer le master en premier
if [ "$MASTER_STATE" != "running" ]; then
    log_info "Démarrage du master (cela prend 3-5 minutes)..."
    vagrant up k3s-master

    if [ $? -ne 0 ]; then
        log_error "Échec du démarrage du master"
        exit 1
    fi

    log_info "✓ Master démarré avec succès"
    echo ""
else
    log_info "Master déjà en cours d'exécution"
    echo ""
fi

# Attendre que le master soit prêt
log_info "Attente que le master soit prêt..."
sleep 10

# Vérifier que le token existe
if [ ! -f ".k3s-token" ]; then
    log_error "Token K3s non trouvé. Le master n'a pas terminé son installation."
    exit 1
fi

log_info "✓ Token K3s trouvé"
echo ""

# Démarrer l'agent
if [ "$AGENT_STATE" != "running" ]; then
    log_info "Démarrage de l'agent (cela prend 3-5 minutes)..."

    # Essayer de démarrer l'agent avec retry
    MAX_RETRIES=3
    RETRY=0

    while [ $RETRY -lt $MAX_RETRIES ]; do
        log_info "Tentative $(($RETRY + 1))/$MAX_RETRIES..."

        vagrant up k3s-agent

        if [ $? -eq 0 ]; then
            log_info "✓ Agent démarré avec succès"
            break
        else
            RETRY=$(($RETRY + 1))

            if [ $RETRY -lt $MAX_RETRIES ]; then
                log_warn "Échec du démarrage. Nouvelle tentative dans 10 secondes..."
                vagrant destroy k3s-agent -f 2>/dev/null || true
                sleep 10
            else
                log_error "Échec du démarrage de l'agent après $MAX_RETRIES tentatives"
                log_error "Essayez d'augmenter la RAM dans le Vagrantfile"
                exit 1
            fi
        fi
    done

    echo ""
else
    log_info "Agent déjà en cours d'exécution"
    echo ""
fi

# Vérifier que le kubeconfig existe
if [ ! -f ".kube/config" ]; then
    log_error "Fichier kubeconfig non trouvé"
    exit 1
fi

log_info "Configuration de kubectl..."
export KUBECONFIG=$(pwd)/.kube/config

# Attendre que les nœuds soient prêts
log_info "Attente que les nœuds soient prêts (peut prendre 1-2 minutes)..."
TIMEOUT=120
ELAPSED=0

while [ $ELAPSED -lt $TIMEOUT ]; do
    READY_NODES=$(kubectl get nodes 2>/dev/null | grep -c " Ready " || echo "0")

    if [ "$READY_NODES" -eq "2" ]; then
        log_info "✓ Les 2 nœuds sont prêts !"
        break
    fi

    echo -n "."
    sleep 5
    ELAPSED=$(($ELAPSED + 5))
done

echo ""

if [ $ELAPSED -ge $TIMEOUT ]; then
    log_warn "Timeout: Les nœuds ne sont pas tous prêts après 2 minutes"
    log_warn "Cela peut prendre plus de temps, vérifiez avec: kubectl get nodes"
else
    echo ""
    log_info "État du cluster:"
    kubectl get nodes
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Cluster K3s Prêt !                     ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Configuration kubectl:"
echo "  export KUBECONFIG=$(pwd)/.kube/config"
echo ""
echo "Commandes utiles:"
echo "  kubectl get nodes          # Voir les nœuds"
echo "  kubectl get pods           # Voir les pods"
echo "  vagrant ssh k3s-master     # SSH vers le master"
echo ""
echo "Pour déployer les applications:"
echo "  ./Scripts/orchestrator.sh create"
echo ""
