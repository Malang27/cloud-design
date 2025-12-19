# Migration de Vagrant vers K3d

**Date**: 2025-12-09  
**Raison**: Problèmes de compatibilité VirtualBox sur Windows

---

## 📊 Changement d'Infrastructure

### Avant (Vagrant/VirtualBox)
- **Problème**: SSH timeout persistants
- **Problème**: Compatibilité VirtualBox sur Windows
- **Script**: `orchestrator.sh` (obsolète)

### Après (K3d)
- **Solution**: K3d (K3s dans Docker)
- **Avantage**: Plus rapide, plus fiable
- **Script**: `orchestrator-k3d.sh` (nouveau)

---

## 🚀 Utilisation du Nouveau Script

### Script Principal: orchestrator-k3d.sh

```bash
# Voir l'état actuel
./Scripts/orchestrator-k3d.sh status

# Commandes disponibles
./Scripts/orchestrator-k3d.sh create   # Créer un nouveau cluster
./Scripts/orchestrator-k3d.sh start    # Démarrer le cluster
./Scripts/orchestrator-k3d.sh stop     # Arrêter le cluster
./Scripts/orchestrator-k3d.sh delete   # Supprimer le cluster
./Scripts/orchestrator-k3d.sh deploy   # Déployer/redéployer les apps
```

### Cluster Actuel

Le cluster **orchestrator** est déjà créé et opérationnel:

```bash
$ ./Scripts/orchestrator-k3d.sh status
=========================================
           CLUSTER STATUS
=========================================

✅ Cluster: orchestrator (1 server + 1 agent)
✅ Nodes: 2 Ready
✅ Pods: 6/6 Running
✅ API Gateway: http://localhost:30000/health
```

---

## 🔄 Comparaison des Scripts

| Fonctionnalité | orchestrator.sh (Vagrant) | orchestrator-k3d.sh (K3d) |
|---------------|--------------------------|--------------------------|
| Infrastructure | VirtualBox VMs | Docker containers |
| Démarrage | 5-15 minutes | 30-60 secondes |
| Stabilité | ⚠️ Problèmes SSH | ✅ Stable |
| Windows | ⚠️ Incompatibilités | ✅ Compatible |
| Ressources | ~3GB RAM/VM | ~1GB RAM total |
| API Gateway | http://192.168.56.110:30000 | http://localhost:30000 |

---

## 📦 Ressources Déployées

Avec le nouveau script K3d, vous disposez de:

- **Cluster**: 2 nœuds (1 server + 1 agent)
- **Pods**: 6 applications
  - api-gateway
  - inventory-app + inventory-db
  - billing-app + billing-db
  - rabbitmq
- **Services**: 6 services (1 NodePort + 5 ClusterIP)
- **HPA**: 2 autoscalers (api-gateway, inventory-app)
- **Secrets**: postgres-credentials, rabbitmq-credentials
- **PVC**: 2 volumes persistants (1Gi chacun)

---

## 🧪 Tests Rapides

### Vérifier le Cluster
```bash
./Scripts/orchestrator-k3d.sh status
```

### Tester l'API Gateway
```bash
curl http://localhost:30000/health
```

### Voir les Logs
```bash
kubectl logs -f deployment/api-gateway
```

### Accéder à RabbitMQ
```bash
kubectl port-forward deployment/rabbitmq 15672:15672
# Puis ouvrir: http://localhost:15672
# User: rabbitmq_user
# Pass: secure_rabbitmq_pass_k8s
```

---

## 🔧 Gestion du Cluster

### Arrêter le Cluster (Préserve les Données)
```bash
./Scripts/orchestrator-k3d.sh stop
```

### Redémarrer le Cluster
```bash
./Scripts/orchestrator-k3d.sh start
```

### Redéployer les Applications
```bash
./Scripts/orchestrator-k3d.sh deploy
```

### Supprimer Complètement le Cluster
```bash
./Scripts/orchestrator-k3d.sh delete
```

### Recréer le Cluster
```bash
./Scripts/orchestrator-k3d.sh create
```

---

## 📚 Documentation

Pour plus de détails:

1. **[DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)** - État du déploiement
2. **[QUICK_TESTS.md](QUICK_TESTS.md)** - Tests rapides
3. **[AUDIT_GUIDE.md](AUDIT_GUIDE.md)** - Guide d'audit complet
4. **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Dépannage

---

## ⚠️ Ancien Script Vagrant

Le script `Scripts/orchestrator.sh` est **obsolète** et ne doit plus être utilisé.

Si vous avez encore des VMs Vagrant:

```bash
# Supprimer les VMs Vagrant
vagrant destroy -f

# Nettoyer les fichiers
rm -rf .vagrant .kube
```

---

## ✅ Validation

Le cluster K3d est maintenant votre infrastructure principale:

- [x] Cluster K3d créé et opérationnel
- [x] 6 applications déployées
- [x] API Gateway accessible
- [x] Tous les tests passent
- [x] Documentation à jour
- [x] Script orchestrator-k3d.sh fonctionnel

**Le projet est prêt pour l'audit ! 🎉**
