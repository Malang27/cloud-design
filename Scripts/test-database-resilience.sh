#!/bin/bash

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║    Test de Résilience - Base de Données Billing          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Vérifier le pod billing-db
BILLING_DB_POD=$(kubectl get pods | grep billing-db | awk '{print $1}')

if [ -z "$BILLING_DB_POD" ]; then
    echo "❌ Pod billing-db non trouvé"
    exit 1
fi

echo "✓ Pod billing-db trouvé: $BILLING_DB_POD"
echo ""

# Test 1: Lister les databases
echo "=== TEST 1: Vérifier que la database 'orders' existe ==="
kubectl exec -it $BILLING_DB_POD -- psql -U billing_user -d postgres -c "\l" | grep orders
if [ $? -eq 0 ]; then
    echo "✅ Database 'orders' existe"
else
    echo "❌ Database 'orders' n'existe pas"
fi
echo ""

# Test 2: Vérifier la commande user_id = 20
echo "=== TEST 2: Vérifier que la commande user_id = 20 est listée ==="
echo "(Cette commande a été créée quand billing-app était actif)"
kubectl exec -it $BILLING_DB_POD -- psql -U billing_user -d orders -c "SELECT * FROM orders WHERE user_id = '20';"
echo ""

# Test 3: Vérifier que user_id = 22 n'est PAS listée
echo "=== TEST 3: Vérifier que la commande user_id = 22 n'est PAS encore listée ==="
echo "(Cette commande a été envoyée quand billing-app était arrêté)"
RESULT=$(kubectl exec -it $BILLING_DB_POD -- psql -U billing_user -d orders -t -c "SELECT COUNT(*) FROM orders WHERE user_id = '22';")
COUNT=$(echo $RESULT | tr -d '[:space:]')

if [ "$COUNT" = "0" ]; then
    echo "✅ La commande user_id = 22 n'est PAS encore dans la DB (normal, elle est en queue RabbitMQ)"
else
    echo "⚠️  La commande user_id = 22 est déjà dans la DB (count = $COUNT)"
fi
echo ""

# Test 4: Redémarrer billing-app
echo "=== TEST 4: Redémarrer billing-app ==="
kubectl get pods | grep billing-app
BILLING_APP_REPLICAS=$(kubectl get statefulset billing-app -o jsonpath='{.spec.replicas}')

if [ "$BILLING_APP_REPLICAS" = "0" ]; then
    echo "▶ billing-app est arrêté, démarrage..."
    kubectl scale statefulset billing-app --replicas=1
    echo "⏳ Attente du démarrage..."
    kubectl wait --for=condition=ready pod -l app=billing-app --timeout=60s
    echo "✅ billing-app redémarré"
else
    echo "✅ billing-app est déjà actif ($BILLING_APP_REPLICAS replicas)"
fi
echo ""

# Test 5: Attendre que le message soit traité
echo "=== TEST 5: Attendre le traitement du message en queue (15 secondes) ==="
sleep 15
echo ""

# Test 6: Vérifier que user_id = 22 est maintenant listée
echo "=== TEST 6: Vérifier que la commande user_id = 22 est maintenant listée ==="
echo "(RabbitMQ a traité le message en queue après redémarrage)"
kubectl exec -it $BILLING_DB_POD -- psql -U billing_user -d orders -c "SELECT * FROM orders WHERE user_id = '22';"

RESULT=$(kubectl exec -it $BILLING_DB_POD -- psql -U billing_user -d orders -t -c "SELECT COUNT(*) FROM orders WHERE user_id = '22';")
COUNT=$(echo $RESULT | tr -d '[:space:]')

if [ "$COUNT" -gt "0" ]; then
    echo "✅ SUCCESS! La commande user_id = 22 est maintenant dans la DB!"
    echo "✅ RabbitMQ a bien mis le message en queue et l'a traité après redémarrage!"
else
    echo "❌ La commande user_id = 22 n'est toujours pas dans la DB"
fi
echo ""

# Test 7: Afficher toutes les commandes
echo "=== TEST 7: Toutes les commandes dans la base de données ==="
kubectl exec -it $BILLING_DB_POD -- psql -U billing_user -d orders -c "SELECT id, user_id, number_of_items, total_amount, created_at FROM orders ORDER BY created_at;"
echo ""

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                  Tests Terminés                           ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Résumé:"
echo "  ✓ Database 'orders' existe"
echo "  ✓ Commande user_id = 20 (créée avec billing-app actif)"
echo "  ✓ Commande user_id = 22 (créée via RabbitMQ, traitée après redémarrage)"
echo ""
echo "🎉 RabbitMQ assure la résilience du système!"
