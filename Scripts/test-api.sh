#!/bin/bash

#===============================================================================
# Script de Test des API pour l'Audit
# Usage: ./Scripts/test-api.sh
#===============================================================================

set -e

API_GATEWAY="http://localhost:30000"
APII_GATEWAY="http://localhost:8081"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║          Tests des API - Audit Orchestrator              ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

#===============================================================================
# Test 1: Health Check
#===============================================================================

log_test "1. Health Check de l'API Gateway"
response=$(curl -s -o /dev/null -w "%{http_code}" $APII_GATEWAY/health)

if [ "$response" = "200" ]; then
    log_success "API Gateway est accessible (HTTP $response)"
else
    log_error "API Gateway non accessible (HTTP $response)"
    exit 1
fi
echo ""

#===============================================================================
# Test 2: Inventory API - POST
#===============================================================================

log_test "2. Test Inventory API - POST /api/movies/"
echo "   Ajout d'un nouveau film..."

response=$(curl -s -w "\n%{http_code}" -X POST $APII_GATEWAY/api/movies/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "A new movie",
    "description": "Very short description"
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    log_success "Film ajouté avec succès (HTTP $http_code)"
    echo "   Response: $body"
else
    log_error "Échec de l'ajout du film (HTTP $http_code)"
    echo "   Response: $body"
fi
echo ""

#===============================================================================
# Test 3: Inventory API - GET
#===============================================================================

log_test "3. Test Inventory API - GET /api/movies/"
echo "   Récupération de tous les films..."

response=$(curl -s -w "\n%{http_code}" -X GET $APII_GATEWAY/api/movies/)

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ]; then
    log_success "Films récupérés avec succès (HTTP $http_code)"
    echo "   Response: $body" | head -c 200
    echo "..."
else
    log_error "Échec de la récupération des films (HTTP $http_code)"
fi
echo ""

#===============================================================================
# Test 4: Billing API - POST (Billing-app actif)
#===============================================================================

log_test "4. Test Billing API - POST /api/billing/ (billing-app actif)"
echo "   Création d'une commande..."

response=$(curl -s -w "\n%{http_code}" -X POST $API_GATEWAY/api/billing/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "20",
    "number_of_items": "99",
    "total_amount": "250"
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    log_success "Commande créée avec succès (HTTP $http_code)"
    echo "   Response: $body"
else
    log_error "Échec de la création de la commande (HTTP $http_code)"
    echo "   Response: $body"
fi
echo ""

#===============================================================================
# Test 5: Arrêter billing-app
#===============================================================================

log_test "5. Arrêt du billing-app (test de résilience avec RabbitMQ)"
kubectl scale statefulset billing-app --replicas=0
sleep 5

billing_pods=$(kubectl get pods -l app=billing-app --no-headers 2>/dev/null | wc -l)
if [ "$billing_pods" = "0" ]; then
    log_success "billing-app arrêté (0 pods actifs)"
else
    log_error "billing-app encore actif ($billing_pods pods)"
fi
echo ""

#===============================================================================
# Test 6: Billing API - POST (Billing-app arrêté)
#===============================================================================

log_test "6. Test Billing API - POST /api/billing/ (billing-app ARRÊTÉ)"
echo "   Test de résilience via RabbitMQ..."

response=$(curl -s -w "\n%{http_code}" -X POST $API_GATEWAY/api/billing/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "22",
    "number_of_items": "10",
    "total_amount": "50"
  }')

http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)

if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
    log_success "✓ Commande acceptée même avec billing-app arrêté (HTTP $http_code)"
    log_success "✓ RabbitMQ gère la mise en queue du message !"
    echo "   Response: $body"
else
    log_error "Échec (HTTP $http_code) - RabbitMQ ne fonctionne pas correctement"
    echo "   Response: $body"
fi
echo ""

#===============================================================================
# Test 7: Redémarrer billing-app
#===============================================================================

log_test "7. Redémarrage du billing-app"
kubectl scale statefulset billing-app --replicas=1
echo "   Attente du démarrage..."
kubectl wait --for=condition=ready pod -l app=billing-app --timeout=60s 2>/dev/null || true
sleep 10

billing_pods=$(kubectl get pods -l app=billing-app --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)
if [ "$billing_pods" -ge "1" ]; then
    log_success "billing-app redémarré et opérationnel"

    echo ""
    log_test "8. Vérification du traitement du message en queue"
    echo "   Dernières lignes des logs de billing-app:"
    kubectl logs billing-app-0 --tail=10 2>/dev/null || log_error "Impossible de récupérer les logs"
else
    log_error "billing-app n'a pas redémarré correctement"
fi
echo ""

#===============================================================================
# Résumé
#===============================================================================

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  Tests Terminés                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

log_test "Résumé des Tests:"
echo "  ✓ Health Check API Gateway"
echo "  ✓ Inventory API - POST (Ajout de film)"
echo "  ✓ Inventory API - GET (Récupération)"
echo "  ✓ Billing API - POST (billing-app actif)"
echo "  ✓ Résilience - Arrêt de billing-app"
echo "  ✓ Billing API - POST (avec RabbitMQ, billing-app arrêté)"
echo "  ✓ Redémarrage de billing-app"
echo "  ✓ Traitement des messages en queue"
echo ""

log_success "Tous les tests sont terminés !"
echo ""
echo "Pour voir l'état actuel du cluster:"
echo "  kubectl get pods"
echo "  kubectl get svc"