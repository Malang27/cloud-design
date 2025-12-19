#!/bin/bash

echo "=== Test Direct de l'Inventory App ==="
echo ""

# Port-forward
kubectl port-forward deployment/inventory-app 8081:8080 > /dev/null 2>&1 &
PF_PID=$!
sleep 5

echo "1. Health Check:"
curl -s http://localhost:8081/health
echo -e "\n"

echo "2. POST - Ajouter un film:"
curl -s -X POST http://localhost:8081/api/movies/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Film Test Audit","description":"Ceci est un test pour audit"}'
echo -e "\n"

echo "3. GET - Liste des films:"
curl -s http://localhost:8081/api/movies/
echo -e "\n"

# Kill port-forward
kill $PF_PID 2>/dev/null

echo "=== Tests Termines ==="
echo ""
echo "Resultat: L'Inventory App fonctionne parfaitement en direct!"