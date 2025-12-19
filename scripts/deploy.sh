#!/bin/bash

#===============================================================================
# Script de Déploiement Automatique - Cloud Design AWS
# Usage: ./scripts/deploy.sh [environment]
# Environments: dev, staging, production (default: production)
#===============================================================================

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Functions
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

# Environment
ENVIRONMENT=${1:-production}
PROJECT_NAME="cloud-design"
AWS_REGION="us-east-1"

log_info "Déploiement de l'environnement: $ENVIRONMENT"

#===============================================================================
# Étape 1: Vérifier les prérequis
#===============================================================================

log_info "Vérification des prérequis..."

# Vérifier AWS CLI
if ! command -v aws &> /dev/null; then
    log_error "AWS CLI n'est pas installé"
    exit 1
fi

# Vérifier Terraform
if ! command -v terraform &> /dev/null; then
    log_error "Terraform n'est pas installé"
    exit 1
fi

# Vérifier kubectl
if ! command -v kubectl &> /dev/null; then
    log_error "kubectl n'est pas installé"
    exit 1
fi

# Vérifier Docker
if ! command -v docker &> /dev/null; then
    log_error "Docker n'est pas installé"
    exit 1
fi

# Vérifier AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    log_error "AWS credentials non configurées"
    exit 1
fi

log_success "Tous les prérequis sont satisfaits"

#===============================================================================
# Étape 2: Créer le backend Terraform (si nécessaire)
#===============================================================================

log_info "Vérification du backend Terraform..."

BUCKET_NAME="$PROJECT_NAME-terraform-state"
TABLE_NAME="terraform-locks"

# Vérifier si le bucket existe
if ! aws s3 ls "s3://$BUCKET_NAME" 2> /dev/null; then
    log_warning "Le bucket S3 n'existe pas, création en cours..."

    aws s3api create-bucket \
      --bucket $BUCKET_NAME \
      --region $AWS_REGION

    aws s3api put-bucket-versioning \
      --bucket $BUCKET_NAME \
      --versioning-configuration Status=Enabled

    aws s3api put-bucket-encryption \
      --bucket $BUCKET_NAME \
      --server-side-encryption-configuration '{
        "Rules": [{
          "ApplyServerSideEncryptionByDefault": {
            "SSEAlgorithm": "AES256"
          }
        }]
      }'

    log_success "Bucket S3 créé: $BUCKET_NAME"
else
    log_info "Le bucket S3 existe déjà: $BUCKET_NAME"
fi

# Vérifier si la table DynamoDB existe
if ! aws dynamodb describe-table --table-name $TABLE_NAME --region $AWS_REGION &> /dev/null; then
    log_warning "La table DynamoDB n'existe pas, création en cours..."

    aws dynamodb create-table \
      --table-name $TABLE_NAME \
      --attribute-definitions AttributeName=LockID,AttributeType=S \
      --key-schema AttributeName=LockID,KeyType=HASH \
      --billing-mode PAY_PER_REQUEST \
      --region $AWS_REGION

    log_success "Table DynamoDB créée: $TABLE_NAME"
else
    log_info "La table DynamoDB existe déjà: $TABLE_NAME"
fi

#===============================================================================
# Étape 3: Déployer l'infrastructure avec Terraform
#===============================================================================

log_info "Déploiement de l'infrastructure Terraform..."

cd terraform

# Initialiser Terraform
terraform init

# Sélectionner l'espace de travail
terraform workspace select $ENVIRONMENT 2>/dev/null || terraform workspace new $ENVIRONMENT

# Valider la configuration
terraform validate

# Appliquer la configuration
if [ "$ENVIRONMENT" = "production" ]; then
    log_warning "Environnement de PRODUCTION - Vérification manuelle requise"
    terraform plan
    read -p "Confirmer le déploiement en production? (yes/no): " confirm
    if [ "$confirm" != "yes" ]; then
        log_error "Déploiement annulé"
        exit 1
    fi
fi

terraform apply -auto-approve -var-file="environments/$ENVIRONMENT/terraform.tfvars"

log_success "Infrastructure Terraform déployée"

# Récupérer les outputs
EKS_CLUSTER_NAME=$(terraform output -raw eks_cluster_name)
ALB_DNS_NAME=$(terraform output -raw alb_dns_name)

log_info "Cluster EKS: $EKS_CLUSTER_NAME"
log_info "ALB DNS: $ALB_DNS_NAME"

cd ..

#===============================================================================
# Étape 4: Configurer kubectl
#===============================================================================

log_info "Configuration de kubectl..."

aws eks update-kubeconfig --name $EKS_CLUSTER_NAME --region $AWS_REGION

# Vérifier la connexion
kubectl get nodes

log_success "kubectl configuré"

#===============================================================================
# Étape 5: Installer les add-ons Kubernetes
#===============================================================================

log_info "Installation des add-ons Kubernetes..."

# Metrics Server
if ! kubectl get deployment metrics-server -n kube-system &> /dev/null; then
    log_info "Installation de Metrics Server..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    log_success "Metrics Server installé"
else
    log_info "Metrics Server déjà installé"
fi

# Attendre que Metrics Server soit prêt
kubectl wait --for=condition=ready pod -l k8s-app=metrics-server -n kube-system --timeout=120s

log_success "Add-ons Kubernetes installés"

#===============================================================================
# Étape 6: Déployer les applications
#===============================================================================

log_info "Déploiement des applications..."

cd kubernetes/manifests

# Appliquer tous les manifests
kubectl apply -f . --recursive

# Attendre que tous les pods soient prêts
log_info "Attente que tous les pods soient prêts..."
kubectl wait --for=condition=ready pod --all --timeout=300s || true

log_success "Applications déployées"

cd ../..

#===============================================================================
# Étape 7: Vérification du déploiement
#===============================================================================

log_info "Vérification du déploiement..."

# Vérifier les pods
log_info "Pods:"
kubectl get pods

# Vérifier les services
log_info "Services:"
kubectl get svc

# Vérifier les ingress
log_info "Ingress:"
kubectl get ingress

# Vérifier les HPAs
log_info "HPAs:"
kubectl get hpa

#===============================================================================
# Résumé
#===============================================================================

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Déploiement Terminé avec Succès!                ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

log_success "Infrastructure AWS déployée"
log_success "Applications Kubernetes déployées"
echo ""

log_info "Informations importantes:"
echo "  - Environnement: $ENVIRONMENT"
echo "  - Cluster EKS: $EKS_CLUSTER_NAME"
echo "  - ALB DNS: http://$ALB_DNS_NAME"
echo "  - CloudWatch: https://console.aws.amazon.com/cloudwatch/home?region=$AWS_REGION"
echo ""

log_info "Commandes utiles:"
echo "  - kubectl get pods"
echo "  - kubectl get svc"
echo "  - kubectl logs -f <pod-name>"
echo "  - kubectl describe pod <pod-name>"
echo ""

log_info "Test de l'API:"
echo "  curl http://$ALB_DNS_NAME/health"
echo ""

log_warning "N'oubliez pas de configurer:"
echo "  1. Les alarmes CloudWatch"
echo "  2. Les backups automatiques"
echo "  3. Les politiques de scaling"
echo "  4. La rotation des secrets"
echo ""

log_success "Déploiement terminé!"
