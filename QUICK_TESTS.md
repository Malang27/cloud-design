# 🧪 Tests Rapides pour l'Audit

**Durée estimée**: 5-10 minutes  
**Prérequis**: Cluster K3d démarré

---

## 🚀 Démarrage Rapide

```bash
# 1. Vérifier que le cluster est actif
k3d cluster list

# 2. Vérifier les nœuds (doivent être 2 et Ready)
kubectl get nodes

# 3. Vérifier tous les pods (doivent être 6 et Running)
kubectl get pods
```

**Résultat attendu**:
```
NAME                             READY   STATUS    RESTARTS   AGE
api-gateway-xxx                  1/1     Running   0          Xm
billing-app-0                    1/1     Running   0          Xm
billing-db-0                     1/1     Running   0          Xm
inventory-app-xxx                1/1     Running   0          Xm
inventory-db-0                   1/1     Running   0          Xm
rabbitmq-xxx                     1/1     Running   0          Xm
```

---

## ✅ Tests de Base (Obligatoires)

### Test 1: API Gateway Health Check
```bash
curl http://localhost:30000/health
```
**Attendu**: `{"status":"OK","service":"API Gateway",...}`

### Test 2: Vérifier les Services
```bash
kubectl get svc
```
**Attendu**: 7 services (6 apps + kubernetes)

### Test 3: Vérifier les HPA
```bash
kubectl get hpa
```
**Attendu**: 2 HPA (api-gateway, inventory-app)

### Test 4: Vérifier les Secrets
```bash
kubectl get secrets
```
**Attendu**: postgres-credentials, rabbitmq-credentials

### Test 5: Vérifier les PVC
```bash
kubectl get pvc
```
**Attendu**: 2 PVC (postgres-data-inventory-db-0, postgres-data-billing-db-0)

---

## 🔍 Tests Avancés (Optionnels)

### Test 6: Logs des Applications
```bash
# API Gateway
kubectl logs deployment/api-gateway --tail=20

# Inventory App
kubectl logs deployment/inventory-app --tail=20

# Billing App
kubectl logs billing-app-0 --tail=20
```

### Test 7: Connexion aux Databases
```bash
# Inventory Database
kubectl exec -it inventory-db-0 -- psql -U inventory_user -d movies -c "\dt"

# Billing Database
kubectl exec -it billing-db-0 -- psql -U billing_user -d orders -c "\dt"
```

### Test 8: Test de Scalabilité HPA
```bash
# Voir l'état actuel
kubectl get hpa

# Simuler une charge (optionnel)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://api-gateway:3000/health; done"

# Observer le scaling (dans un autre terminal)
kubectl get hpa -w
```

### Test 9: RabbitMQ Management
```bash
# Port-forward vers RabbitMQ Management UI
kubectl port-forward deployment/rabbitmq 15672:15672

# Ouvrir dans le navigateur: http://localhost:15672
# User: rabbitmq_user
# Password: secure_rabbitmq_pass_k8s
```

---

## 📊 Commandes de Diagnostic

### Voir tous les événements récents
```bash
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Voir les ressources consommées
```bash
kubectl top nodes
kubectl top pods
```

### Voir la configuration complète d'un pod
```bash
kubectl describe pod api-gateway-xxx
```

### Voir les logs en temps réel
```bash
kubectl logs -f deployment/api-gateway
```

---

## 🎯 Checklist d'Audit Rapide

Cochez au fur et à mesure:

- [ ] Cluster K3d actif (k3d cluster list)
- [ ] 2 nœuds Ready (kubectl get nodes)
- [ ] 6 pods Running (kubectl get pods)
- [ ] API Gateway répond (curl localhost:30000/health)
- [ ] 7 services créés (kubectl get svc)
- [ ] 2 HPA configurés (kubectl get hpa)
- [ ] 2 Secrets créés (kubectl get secrets)
- [ ] 2 PVC créés (kubectl get pvc)
- [ ] Logs sans erreurs critiques
- [ ] Databases accessibles

---

## 🚨 En Cas de Problème

### Pod en CrashLoopBackOff
```bash
# Voir les logs
kubectl logs <pod-name>

# Voir les événements
kubectl describe pod <pod-name>

# Redémarrer
kubectl delete pod <pod-name>
```

### Service Inaccessible
```bash
# Vérifier le service
kubectl get svc
kubectl describe svc <service-name>

# Vérifier les endpoints
kubectl get endpoints
```

### HPA ne Scale Pas
```bash
# Vérifier les métriques
kubectl top pods

# Vérifier les HPA
kubectl describe hpa <hpa-name>

# Installer metrics-server si nécessaire
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

---

## 📞 Support

En cas de problème, consulter:
1. [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
2. [DEPLOYMENT_SUMMARY.md](DEPLOYMENT_SUMMARY.md)
3. Logs: `kubectl logs <pod-name>`

---

**Bon audit ! 🎉**
