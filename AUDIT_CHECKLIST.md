# 📋 Checklist d'Audit Kubernetes/K3s - Version Imprimable

**Projet** : Orchestration de Conteneurs avec K3s
**Étudiant** : ___________________________
**Date** : ___________________________
**Auditeur** : ___________________________

---

## 🎯 Score Global : _____ / 150 points (+ _____ / 10 bonus)

---

## 1️⃣ Structure du Projet (10 pts) _____ / 10

### Fichiers Requis
- [ ] `README.md` présent et complet
- [ ] `Vagrantfile` présent
- [ ] Script `orchestrator.sh` présent et exécutable
- [ ] Dossier `Manifests/` avec tous les YAML
- [ ] Dossier `Scripts/` avec les scripts d'automatisation
- [ ] Dossier `Dockerfiles/` avec les 6 images

### Questions Théoriques de Base
- [ ] Q1 : Orchestration de conteneurs et avantages ?
- [ ] Q2 : Qu'est-ce que Kubernetes et son rôle ?
- [ ] Q3 : Qu'est-ce que K3s et son rôle ?

**Notes** : _______________________________________________

---

## 2️⃣ Documentation (10 pts) _____ / 10

- [ ] Prérequis clairement listés (Vagrant, VirtualBox, kubectl, Docker)
- [ ] Instructions d'installation pas à pas
- [ ] Guide d'utilisation complet
- [ ] Section de tests documentée
- [ ] Section de dépannage présente

**Notes** : _______________________________________________

---

## 3️⃣ Images Docker (10 pts) _____ / 10

- [ ] Images hébergées sur Docker Hub de l'étudiant
- [ ] Toutes les 6 images sont disponibles :
  - [ ] `inventory-db`
  - [ ] `billing-db`
  - [ ] `inventory-app`
  - [ ] `billing-app`
  - [ ] `rabbitmq`
  - [ ] `api-gateway`

**Username Docker Hub** : ___________________________

**Notes** : _______________________________________________

---

## 4️⃣ Cluster K3s (15 pts) _____ / 15

### Configuration
- [ ] `kubectl` installé et configuré
- [ ] Cluster créé via Vagrantfile
- [ ] Exactement 2 nœuds présents (master + agent)
- [ ] Les deux nœuds sont en status `Ready`

### Test
```bash
kubectl get nodes -A
```

**Résultat** :
□ Master : _____________ | Status : _____________
□ Agent : _____________ | Status : _____________

**Notes** : _______________________________________________

---

## 5️⃣ Infrastructure (15 pts) _____ / 15

### Déploiement
- [ ] `./orchestrator.sh create` fonctionne sans erreur
- [ ] L'architecture respecte le schéma demandé
- [ ] Tous les services sont accessibles

### Test
```bash
kubectl get all
```

**Notes** : _______________________________________________

---

## 6️⃣ Manifestes Kubernetes (10 pts) _____ / 10

### Questions Théoriques
- [ ] Q1 : Qu'est-ce que l'Infrastructure as Code (IaC) ?
- [ ] Q2 : Expliquer ce qu'est un manifeste K8s
- [ ] Q3 : Expliquer chaque manifeste du projet

### Vérifications
- [ ] Un manifeste YAML pour chaque service (6 services)
- [ ] Aucun credential en clair (sauf `secrets.yaml`)
- [ ] Labels cohérents utilisés
- [ ] Ressources CPU/mémoire définies

**Notes** : _______________________________________________

---

## 7️⃣ Secrets et Sécurité (5 pts) _____ / 5

- [ ] Secrets Kubernetes créés (`kubectl get secrets`)
- [ ] Tous les credentials sont dans les secrets
- [ ] Aucun mot de passe en clair dans les manifestes

### Test
```bash
kubectl get secrets -o json
```

**Notes** : _______________________________________________

---

## 8️⃣ Ressources Déployées (15 pts) _____ / 15

### Services Requis
- [ ] `inventory-database` (StatefulSet, port 5432)
- [ ] `billing-database` (StatefulSet, port 5432)
- [ ] `inventory-app` (Deployment, port 8080)
- [ ] `billing-app` (StatefulSet, port 8080)
- [ ] `rabbitmq` (Deployment, port 5672)
- [ ] `api-gateway` (Deployment, port 3000)

### Configuration StatefulSet vs Deployment
- [ ] Bases de données en StatefulSet avec PVC
- [ ] `api-gateway` et `inventory-app` en Deployment
- [ ] `billing-app` en StatefulSet

### HPA (Horizontal Pod Autoscaler)
- [ ] HPA sur `api-gateway` (min:1, max:3, CPU:60%)
- [ ] HPA sur `inventory-app` (min:1, max:3, CPU:60%)

### Test
```bash
kubectl get hpa
```

### Questions Théoriques
- [ ] Q1 : Qu'est-ce qu'un StatefulSet ?
- [ ] Q2 : Qu'est-ce qu'un Deployment ?
- [ ] Q3 : Différence entre Deployment et StatefulSet ?
- [ ] Q4 : Qu'est-ce que le scaling et pourquoi ?
- [ ] Q5 : Qu'est-ce qu'un load balancer et son rôle ?
- [ ] Q6 : Pourquoi ne pas déployer la DB en Deployment ?

**Notes** : _______________________________________________

---

## 9️⃣ Tests de la Solution (30 pts) _____ / 30

### Test 1 : API Inventaire - POST (5 pts) _____ / 5
```bash
curl -X POST http://[IP]:30000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "A new movie", "description": "Very short description"}'
```
- [ ] Code réponse : `200 OK`

### Test 2 : API Inventaire - GET (5 pts) _____ / 5
```bash
curl http://[IP]:30000/api/movies
```
- [ ] Code réponse : `200 OK`
- [ ] Le film créé est listé dans la réponse JSON

### Test 3 : API Billing - POST (5 pts) _____ / 5
```bash
curl -X POST http://[IP]:30000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "20", "number_of_items": "99", "total_amount": "250"}'
```
- [ ] Code réponse : `200 OK`

### Test 4 : Résilience RabbitMQ (10 pts) _____ / 10

**Étape 1** : Arrêter billing-app
```bash
kubectl scale statefulset billing-app --replicas=0
```
- [ ] billing-app correctement arrêté

**Étape 2** : Envoyer une commande (user_id=22)
```bash
curl -X POST http://[IP]:30000/api/billing \
  -H "Content-Type: application/json" \
  -d '{"user_id": "22", "number_of_items": "10", "total_amount": "50"}'
```
- [ ] Code réponse : `200 OK` (même si billing-app est arrêté)

**Étape 3** : Vérifier la base de données
```bash
kubectl exec -it billing-db-0 -- psql -U postgres
\c orders
TABLE orders;
```
- [ ] La base `orders` existe
- [ ] Commande user_id=20 est enregistrée
- [ ] Commande user_id=22 N'EST PAS encore enregistrée

**Étape 4** : Redémarrer billing-app
```bash
kubectl scale statefulset billing-app --replicas=1
kubectl wait --for=condition=ready pod -l app=billing-app --timeout=120s
```
- [ ] billing-app redémarré correctement

**Étape 5** : Revérifier la base
- [ ] Commande user_id=22 est MAINTENANT enregistrée
- [ ] ✅ Preuve que RabbitMQ a conservé le message

### Test 5 : Persistance des Données (5 pts) _____ / 5
```bash
# Créer un film, supprimer le pod DB, vérifier que le film existe toujours
kubectl delete pod inventory-db-0
kubectl wait --for=condition=ready pod/inventory-db-0 --timeout=180s
```
- [ ] Le pod se recrée automatiquement
- [ ] Les données sont toujours présentes après redémarrage

**IP Gateway** : ___________________________

**Notes** : _______________________________________________

---

## 🔟 Composants Kubernetes (30 pts) _____ / 30

### Présentation de 15 minutes (avec Google autorisé)

**Temps écoulé** : _____ minutes

L'étudiant doit expliquer :

#### Control Plane Components (15 pts)
- [ ] `kube-apiserver` : Frontend de l'API K8s
- [ ] `etcd` : Base de données clé-valeur du cluster
- [ ] `kube-scheduler` : Assigne les pods aux nœuds
- [ ] `kube-controller-manager` : Exécute les contrôleurs
- [ ] `cloud-controller-manager` : Interface avec les cloud providers

#### Node Components (10 pts)
- [ ] `kubelet` : Agent sur chaque nœud
- [ ] `kube-proxy` : Proxy réseau
- [ ] `container-runtime` : Docker/containerd/CRI-O

#### Addons (5 pts)
- [ ] DNS, Dashboard, Metrics Server, Ingress Controller

**Qualité de l'explication** :
- [ ] Claire et structurée
- [ ] Compréhension démontrée
- [ ] Exemples pertinents donnés

**Notes** : _______________________________________________

---

## 🌟 BONUS : Auto-Scaling HPA (10 pts) _____ / 10

### Test de Charge
```bash
# Générer de la charge
hey -z 60s -c 50 http://[IP]:30000/api/movies

# Observer le scaling
kubectl get hpa -w
kubectl get pods -w
```

- [ ] HPA détecte l'augmentation de CPU
- [ ] Nombre de replicas passe de 1 à 2-3
- [ ] Scaling se produit en moins de 3 minutes
- [ ] Pods créés automatiquement

**Notes** : _______________________________________________

---

## 📊 Récapitulatif des Scores

| Section | Points Max | Score Obtenu |
|---------|------------|--------------|
| 1. Structure du Projet | 10 | _____ |
| 2. Documentation | 10 | _____ |
| 3. Images Docker | 10 | _____ |
| 4. Cluster K3s | 15 | _____ |
| 5. Infrastructure | 15 | _____ |
| 6. Manifestes K8s | 10 | _____ |
| 7. Secrets | 5 | _____ |
| 8. Ressources Déployées | 15 | _____ |
| 9. Tests de la Solution | 30 | _____ |
| 10. Composants K8s | 30 | _____ |
| **SOUS-TOTAL** | **150** | **_____** |
| **BONUS : Auto-scaling** | **10** | **_____** |
| **TOTAL FINAL** | **160** | **_____** |

---

## ⚠️ Points Critiques (Échec Automatique)

- [ ] ⛔ Credentials en clair dans les manifestes (sauf secrets.yaml)
- [ ] ⛔ Cluster ne démarre pas
- [ ] ⛔ Aucun service ne répond
- [ ] ⛔ Plagiat ou code non compris

**Si une case est cochée, l'audit est un ÉCHEC.**

---

## 💬 Feedback Global

### Points Forts
_______________________________________________
_______________________________________________
_______________________________________________

### Points à Améliorer
_______________________________________________
_______________________________________________
_______________________________________________

### Recommandations
_______________________________________________
_______________________________________________
_______________________________________________

---

## ✅ Décision Finale

**Note finale** : _____ / 150 (+ _____ bonus)

**Résultat** :
□ ✅ **VALIDÉ** (≥ 100/150)
□ ⚠️ **VALIDÉ AVEC RÉSERVES** (80-99/150)
□ ❌ **NON VALIDÉ** (< 80/150)

**Signature Auditeur** : ___________________________ **Date** : _______________

---

## 📌 Notes Complémentaires

_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________
_______________________________________________

---

**Version** : 1.0 | **Durée estimée d'audit** : 2-3 heures
