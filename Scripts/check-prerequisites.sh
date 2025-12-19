#!/bin/bash

# Script de vérification des prérequis pour le projet Orchestrator
# Usage: ./Scripts/check-prerequisites.sh

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║     Vérification des Prérequis - Orchestrator K3s        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Fonction pour vérifier une commande
check_command() {
    local cmd=$1
    local name=$2
    local install_url=$3

    echo -n "Vérification de $name... "
    if command -v $cmd &> /dev/null; then
        version=$($cmd --version 2>&1 | head -n 1)
        echo -e "${GREEN}✓ Installé${NC}"
        echo "   Version: $version"
        return 0
    else
        echo -e "${RED}✗ Non installé${NC}"
        echo -e "   ${YELLOW}Installation:${NC} $install_url"
        return 1
    fi
}

# Fonction pour vérifier un fichier
check_file() {
    local file=$1
    local description=$2

    echo -n "Vérification de $description... "
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ Présent${NC}"
        return 0
    else
        echo -e "${RED}✗ Absent${NC}"
        return 1
    fi
}

# Fonction pour vérifier un dossier
check_directory() {
    local dir=$1
    local description=$2

    echo -n "Vérification de $description... "
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ Présent${NC}"
        return 0
    else
        echo -e "${RED}✗ Absent${NC}"
        return 1
    fi
}

# Variables
all_ok=true

echo "═══════════════════════════════════════════════════════════"
echo " 1. LOGICIELS REQUIS"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Vérifier Vagrant
if ! check_command "vagrant" "Vagrant" "https://www.vagrantup.com/downloads"; then
    all_ok=false
fi
echo ""

# Vérifier VirtualBox
if ! check_command "vboxmanage" "VirtualBox" "https://www.virtualbox.org/wiki/Downloads"; then
    all_ok=false
fi
echo ""

# Vérifier kubectl
if ! check_command "kubectl" "kubectl" "https://kubernetes.io/docs/tasks/tools/"; then
    all_ok=false
fi
echo ""

# Vérifier Docker
if ! check_command "docker" "Docker" "https://docs.docker.com/get-docker/"; then
    all_ok=false
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo " 2. STRUCTURE DU PROJET"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Vérifier les fichiers importants
if ! check_file "Vagrantfile" "Vagrantfile"; then
    all_ok=false
fi
echo ""

if ! check_file "README.md" "README.md"; then
    all_ok=false
fi
echo ""

if ! check_file "Scripts/orchestrator.sh" "Script orchestrator.sh"; then
    all_ok=false
fi
echo ""

# Vérifier les dossiers
if ! check_directory "Manifests" "Dossier Manifests"; then
    all_ok=false
fi
echo ""

if ! check_directory "Scripts" "Dossier Scripts"; then
    all_ok=false
fi
echo ""

if ! check_directory "Dockerfiles" "Dossier Dockerfiles"; then
    all_ok=false
fi
echo ""

echo "═══════════════════════════════════════════════════════════"
echo " 3. ÉTAT DU CLUSTER"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Vérifier si le cluster est démarré
echo -n "Vérification du cluster K3s... "
if [ -f ".kube/config" ]; then
    echo -e "${GREEN}✓ Configuré${NC}"
    echo "   Fichier kubeconfig trouvé: .kube/config"

    # Vérifier si le cluster répond
    export KUBECONFIG=".kube/config"
    if kubectl get nodes &> /dev/null; then
        echo -e "${GREEN}✓ Cluster accessible${NC}"
        echo ""
        echo "Nœuds du cluster:"
        kubectl get nodes
    else
        echo -e "${YELLOW}⚠ Cluster non accessible${NC}"
        echo "   Le fichier kubeconfig existe mais le cluster ne répond pas."
        echo "   Vérifiez que les VMs Vagrant sont démarrées: vagrant status"
        all_ok=false
    fi
else
    echo -e "${YELLOW}⚠ Non configuré${NC}"
    echo "   Le cluster n'a pas encore été démarré."
    echo "   Exécutez: vagrant up"
fi
echo ""

# Vérifier l'état des VMs Vagrant
if command -v vagrant &> /dev/null; then
    echo "État des VMs Vagrant:"
    vagrant status 2>/dev/null || echo "Aucune VM Vagrant trouvée"
    echo ""
fi

echo "═══════════════════════════════════════════════════════════"
echo " 4. RÉSUMÉ"
echo "═══════════════════════════════════════════════════════════"
echo ""

if [ "$all_ok" = true ]; then
    echo -e "${GREEN}✓ Tous les prérequis sont satisfaits !${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "  1. Si le cluster n'est pas démarré: vagrant up"
    echo "  2. Configurer kubectl: export KUBECONFIG=\$(pwd)/.kube/config"
    echo "  3. Déployer les applications: ./Scripts/orchestrator.sh create"
else
    echo -e "${RED}✗ Certains prérequis sont manquants${NC}"
    echo ""
    echo "Actions requises:"
    echo "  1. Installer les logiciels manquants (voir ci-dessus)"
    echo "  2. Redémarrer votre terminal après installation"
    echo "  3. Re-exécuter ce script pour vérifier"
    echo ""
    echo "Documentation:"
    echo "  - README.md pour le guide complet"
    echo "  - AUDIT_GUIDE.md pour les instructions détaillées"
fi
echo ""
echo "═══════════════════════════════════════════════════════════"
