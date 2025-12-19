# 🧪 Tests de l'API avec curl

**API Gateway**: http://localhost:30000

---

## ✅ Test Préliminaire

### Health Check de l'API Gateway
```bash
curl http://localhost:30000/health
```

**Résultat attendu**:
```json
{"status":"OK","service":"API Gateway","timestamp":"...","uptime":...}
```

---

## 🎬 Tests de l'API Inventory (Movies)

### Test 1: POST - Ajouter un film
```bash
curl -X POST http://localhost:30000/api/movies/ \
  -H "Content-Type: application/json" \
  -d '{
    "title": "A new movie",
    "description": "Very short description"
  }'
```

**Résultat attendu**: HTTP 200/201
```json
{
  "id": 1,
  "title": "A new movie",
  "description": "Very short description",
  ...
}
```

### Test 2: GET - Récupérer tous les films
```bash
curl http://localhost:30000/api/movies/
```

**Résultat attendu**: HTTP 200
```json
[
  {
    "id": 1,
    "title": "A new movie",
    "description": "Very short description",
    ...
  }
]
```

### Test 3: GET - Récupérer un film spécifique
```bash
curl http://localhost:30000/api/movies/1
```

**Résultat attendu**: HTTP 200
```json
{
  "id": 1,
  "title": "A new movie",
  "description": "Very short description"
}
```

---

## 💰 Tests de l'API Billing

### Test 4: POST - Créer une commande (Billing-app actif)
```bash
curl -X POST http://localhost:30000/api/billing/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "20",
    "number_of_items": "99",
    "total_amount": "250"
  }'
```

**Résultat attendu**: HTTP 200/201
```json
{
  "success": true,
  "message": "Commande reçue et envoyée pour traitement",
  "data": {
    "user_id": "20",
    "number_of_items": "99",
    "total_amount": "250"
  }
}
```

---

## 🔄 Test de Résilience avec RabbitMQ

### Test 5: Arrêter billing-app
```bash
kubectl scale statefulset billing-app --replicas=0
```

**Vérifier l'arrêt**:
```bash
kubectl get pods | grep billing-app
```

**Résultat attendu**: Aucun pod billing-app (ou 0/1)

### Test 6: POST - Créer une commande (Billing-app ARRÊTÉ)
```bash
curl -X POST http://localhost:30000/api/billing/ \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "22",
    "number_of_items": "10",
    "total_amount": "50"
  }'
```

**Résultat attendu**: HTTP 200 ✅
```json
{
  "success": true,
  "message": "Commande reçue et envoyée pour traitement",
  "data": {
    "user_id": "22",
    "number_of_items": "10",
    "total_amount": "50"
  }
}
```

**Explication**: La commande est acceptée grâce à **RabbitMQ** qui met le message en queue !

### Test 7: Redémarrer billing-app
```bash
kubectl scale statefulset billing-app --replicas=1
```

**Attendre le démarrage**:
```bash
kubectl wait --for=condition=ready pod -l app=billing-app --timeout=60s
```

### Test 8: Vérifier le traitement du message en queue
```bash
kubectl logs billing-app-0 --tail=20
```

**Résultat attendu**: Le message en queue a été traité
```
✅ Nouvelle commande créée: { id: X, user_id: '22', number_of_items: '10', total_amount: '50' }
✅ Message traité et acquitté
```

---

## 📋 Script Automatisé

Pour exécuter tous les tests automatiquement:
```bash
./Scripts/test-api.sh
```

---

## 🧪 Tests Directs des Pods (Sans API Gateway)

### Inventory App
```bash
# Port-forward
kubectl port-forward deployment/inventory-app 8081:8080 &

# Test
curl http://localhost:8081/health
curl http://localhost:8081/api/movies/

# Arrêter port-forward
kill %1
```

### Billing App
```bash
# Port-forward
kubectl port-forward billing-app-0 8082:8080 &

# Test
curl http://localhost:8082/health

# Arrêter port-forward
kill %1
```

---

## ⚠️ Si l'Inventory API ne fonctionne pas via API Gateway

### Test direct du service
```bash
kubectl exec deployment/api-gateway -- wget -q -O- http://inventory-app:8080/health
```

### Vérifier le service
```bash
kubectl get svc inventory-app
kubectl describe svc inventory-app
```

### Vérifier les endpoints
```bash
kubectl get endpoints inventory-app
```

---

## 📊 Résumé des Tests d'Audit

| Test | Endpoint | Méthode | Statut Attendu | Validation |
|------|----------|---------|----------------|------------|
| Health Check | /health | GET | 200 | API Gateway actif |
| Ajouter un film | /api/movies/ | POST | 200/201 | Film créé |
| Lister les films | /api/movies/ | GET | 200 | Liste retournée |
| Créer commande (actif) | /api/billing/ | POST | 200/201 | Commande créée |
| Arrêter billing-app | kubectl scale | - | - | Pod arrêté |
| Créer commande (arrêté) | /api/billing/ | POST | 200 | RabbitMQ OK ✅ |
| Redémarrer billing-app | kubectl scale | - | - | Pod démarré |
| Vérifier traitement | kubectl logs | - | - | Message traité |

---

## ✅ Critères de Validation

### Test Inventory API
- [x] POST crée un nouveau film (HTTP 200/201)
- [x] GET retourne la liste des films (HTTP 200)
- [x] Le film ajouté est dans la liste

### Test Billing API
- [x] POST crée une commande (HTTP 200/201)
- [x] billing-app peut être arrêté sans erreur
- [x] POST fonctionne même avec billing-app arrêté (HTTP 200) ✅
- [x] RabbitMQ met le message en queue
- [x] Le message est traité après redémarrage de billing-app

---

## 🎯 Pour l'Audit

Ces tests démontrent:

1. **Fonctionnalité**: Les API fonctionnent correctement
2. **Persistance**: Les données sont stockées dans PostgreSQL
3. **Résilience**: RabbitMQ assure la mise en queue des messages
4. **Architecture**: Communication asynchrone fonctionnelle
5. **Scalabilité**: HPA fonctionne (3 replicas de l'API Gateway)

**Tout est opérationnel ! ✅**