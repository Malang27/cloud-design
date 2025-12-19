# 🚀 Guide de Démarrage Rapide - Orchestrator K3d

**Durée**: 5 minutes pour vérifier que tout fonctionne  
**Infrastructure**: K3d (K3s dans Docker)

---

## ✅ Prérequis

Tout est déjà installé et fonctionnel:

- [x] Docker Desktop installé et démarré
- [x] K3d installé
- [x] kubectl installé
- [x] Cluster K3d créé et opérationnel
- [x] 6 applications déployées

---

## 🎯 Vérification Rapide (30 secondes)

### 1. Vérifier l'état du cluster

```bash
./Scripts/orchestrator-k3d.sh status
```

**Résultat attendu**:
- ✅ Cluster: orchestrator (running)
- ✅ Nodes: 2 Ready
- ✅ Pods: 6 Running
- ✅ API Gateway responding

### 2. Tester l'API Gateway

```bash
curl http://localhost:30000/health
```

**Résultat attendu**:
```json
{"status":"OK","service":"API Gateway","timestamp":"...","uptime":...}
```

### 3. Vérifier tous les pods

```bash
kubectl get pods
```

**Résultat attendu**: 6 pods avec status `Running`

---

## 📋 Commandes Essentielles

### Gestion du Cluster

```bash
# Voir l'état
./Scripts/orchestrator-k3d.sh status

# Arrêter le cluster (données préservées)
./Scripts/orchestrator-k3d.sh stop

# Redémarrer le cluster
./Scripts/orchestrator-k3d.sh start

# Redéployer les applications
./Scripts/orchestrator-k3d.sh deploy
```

### Surveillance

```bash
# Voir tous les pods
kubectl get pods

# Voir tous les services
kubectl get svc

# Voir les logs de l'API Gateway
kubectl logs -f deployment/api-gateway

# Voir les événements récents
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Tests

```bash
# Health check de l'API Gateway
curl http://localhost:30000/health

# Port-forward vers RabbitMQ Management
kubectl port-forward deployment/rabbitmq 15672:15672
# Puis: http://localhost:15672 (rabbitmq_user / secure_rabbitmq_pass_k8s)
```

---

## 🏗️ Architecture Déployée

```
┌─────────────────────────────────────────────┐
│         Cluster K3d (2 nœuds)              │
│                                             │
│  ┌──────────────────────────────────────┐  │
│  │  API Gateway (NodePort :30000)       │  │
│  │  http://localhost:30000              │  │
│  └────────┬────────────────────┬────────┘  │
│           │                    │            │
│  ┌────────▼────────┐  ┌────────▼────────┐  │
│  │ Inventory App   │  │  Billing App    │  │
│  │ (HPA: 1-3)      │  │  (StatefulSet)  │  │
│  └────────┬────────┘  └────────┬────────┘  │
│           │                    │            │
│  ┌────────▼────────┐  ┌────────▼────────┐  │
│  │ Inventory DB    │  │  Billing DB     │  │
│  │ (PostgreSQL)    │  │  (PostgreSQL)   │  │
│  │ PVC: 1Gi        │  │  PVC: 1Gi       │  │
│  └─────────────────┘  └─────────────────┘  │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  RabbitMQ (AMQP + Management UI)    │   │
│  └─────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## 📊 Ressources Déployées

| Ressource | Type | Nom | Status |
|-----------|------|-----|--------|
| Deployment | API Gateway | api-gateway | ✅ Running |
| Deployment | Inventory App | inventory-app | ✅ Running |
| StatefulSet | Billing App | billing-app | ✅ Running |
| Deployment | RabbitMQ | rabbitmq | ✅ Running |
| StatefulSet | Inventory DB | inventory-db | ✅ Running |
| StatefulSet | Billing DB | billing-db | ✅ Running |

### Services

| Service | Type | Port | Endpoint |
|---------|------|------|----------|
| api-gateway | NodePort | 30000 | http://localhost:30000 |
| inventory-app | ClusterIP | 8080 | Internal |
| billing-app | ClusterIP | 8080 | Internal |
| rabbitmq | ClusterIP | 5672, 15672 | Internal |
| inventory-db | Headless | 5432 | Internal |
| billing-db | Headless | 5432 | Internal |

### Auto-Scaling (HPA)

| Application | Min | Max | Target CPU | Current |
|-------------|-----|-----|------------|---------|
| api-gateway | 1 | 3 | 60% | ~2% |
| inventory-app | 1 | 3 | 60% | ~1% |

---

## 🧪 Tests pour l'Audit

### Test 1: Infrastructure
```bash
kubectl get nodes
# Attendu: 2 nœuds Ready
```

### Test 2: Applications
```bash
kubectl get pods
# Attendu: 6 pods Running
```

### Test 3: API Gateway
```bash
curl http://localhost:30000/health
# Attendu: {"status":"OK",...}
```

### Test 4: Services
```bash
kubectl get svc
# Attendu: 7 services (6 apps + kubernetes)
```

### Test 5: HPA
```bash
kubectl get hpa
# Attendu: 2 HPA (api-gateway, inventory-app)
```

### Test 6: Secrets
```bash
kubectl get secrets | grep -E "(postgres|rabbitmq)"
# Attendu: postgres-credentials, rabbitmq-credentials
```

### Test 7: PVC
```bash
kubectl get pvc
# Attendu: 2 PVC Bound (1Gi chacun)
```

---

## 🚨 Problèmes Courants

### Cluster ne répond pas
```bash
# Redémarrer le cluster
./Scripts/orchestrator-k3d.sh stop
./Scripts/orchestrator-k3d.sh start
```

### Pod en CrashLoopBackOff
```bash
# Voir les logs
kubectl logs <pod-name>

# Redémarrer le pod
kubectl delete pod <pod-name>
```

### API Gateway inaccessible
```bash
# Vérifier le service
kubectl get svc api-gateway

# Vérifier le pod
kubectl describe pod <api-gateway-pod>
```

---

## 📚 Documentation Complète

Pour plus de détails, consultez:

1. **[K3D_MIGRATION.md](K3D_MIGRATION.md)** - Pourquoi K3d au lieu de Vagrant
2. **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - Résumé complet du déploiement
3. **[QUICK_TESTS.md](QUICK_TESTS.md)** - Tests rapides
4. **[AUDIT_GUIDE.md](AUDIT_GUIDE.md)** - Guide d'audit détaillé
5. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Dépannage

---

## 🎓 Pour l'Audit

### Checklist Rapide

- [x] Cluster K3d opérationnel (2 nœuds)
- [x] 6 applications déployées et Running
- [x] API Gateway accessible (http://localhost:30000)
- [x] 2 HPA configurés
- [x] 2 PVC avec persistance des données
- [x] Secrets Kubernetes sécurisés
- [x] Architecture conforme aux spécifications

### Commande Ultime pour l'Audit

```bash
./Scripts/orchestrator-k3d.sh status
```

Cette commande affiche **tout** ce dont l'auditeur a besoin:
- État du cluster
- Nœuds
- Pods
- Services  
- PVC
- HPA
- Test de l'API Gateway

**Tout est prêt ! 🎉**
