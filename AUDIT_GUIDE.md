# Guide d'Audit - Orchestration Kubernetes

Ce document décrit le processus d'audit complet pour évaluer le projet d'orchestration de conteneurs avec Kubernetes/K3s.

## Table des Matières

- [1. Vérifications Générales](#1-vérifications-générales)
- [2. Documentation](#2-documentation)
- [3. Images Docker](#3-images-docker)
- [4. Cluster Kubernetes](#4-cluster-kubernetes)
- [5. Infrastructure](#5-infrastructure)
- [6. Manifestes Kubernetes](#6-manifestes-kubernetes)
- [7. Secrets et Sécurité](#7-secrets-et-sécurité)
- [8. Ressources Déployées](#8-ressources-déployées)
- [9. Tests de la Solution](#9-tests-de-la-solution)
- [10. Composants Kubernetes](#10-composants-kubernetes)
- [Grille d'Évaluation](#grille-dévaluation)

---

## 1. Vérifications Générales

### 1.1 Contenu du Dépôt

**Objectif** : Vérifier que tous les fichiers nécessaires sont présents et correctement organisés.

#### Checklist
- [ ] Le dépôt contient un fichier [README.md](README.md)
- [ ] Le script [orchestrator.sh](Scripts/orchestrator.sh) est présent
- [ ] Le fichier [Vagrantfile](Vagrantfile) existe
- [ ] Tous les fichiers supplémentaires nécessaires sont présents

#### Structure du Projet Attendue

```
orchestrator/
├── Manifests/                    # Manifestes Kubernetes
│   ├── secrets.yaml
│   ├── statefulsets/
│   ├── deployments/
│   ├── services/
│   └── hpa/
├── Scripts/                      # Scripts d'automatisation
│   └── orchestrator.sh
├── Dockerfiles/                  # Images Docker
│   ├── inventory-db/
│   ├── billing-db/
│   ├── inventory-app/
│   ├── billing-app/
│   ├── rabbitmq/
│   └── api-gateway/
├── Vagrantfile
└── README.md
```

**Questions à poser à l'étudiant** :

1. ❓ **Tous les fichiers requis sont-ils présents ?**
   - Réponse attendue : Oui, avec la structure ci-dessus ou une justification valide

2. ❓ **La structure du projet est-elle conforme ? Sinon, pouvez-vous justifier votre choix ?**
   - Si la structure diffère, demander les raisons techniques

---

### 1.2 Connaissances Théoriques de Base

**Questions à poser** :

#### Q1 : Qu'est-ce que l'orchestration de conteneurs et quels sont ses avantages ?

**Réponse attendue** :
- L'orchestration automatise le déploiement, la mise à l'échelle et la gestion des conteneurs
- **Avantages** :
  - Déploiement automatisé
  - Équilibrage de charge
  - Auto-réparation (restart automatique)
  - Découverte de services
  - Gestion de la configuration
  - Orchestration du stockage

#### Q2 : Qu'est-ce que Kubernetes et quel est son rôle principal ?

**Réponse attendue** :
- Plateforme open-source d'orchestration de conteneurs
- **Rôles principaux** :
  - Gestion de clusters
  - Ordonnancement des conteneurs
  - Découverte de services et load balancing
  - Auto-scaling
  - Auto-réparation
  - Gestion du stockage
  - Gestion des secrets et configurations

#### Q3 : Qu'est-ce que K3s et quel est son rôle principal ?

**Réponse attendue** :
- Distribution Kubernetes légère et certifiée
- **Caractéristiques** :
  - Installation simplifiée
  - Empreinte mémoire réduite (~512MB vs 4GB)
  - Binaire unique (<100MB)
  - Idéal pour développement, IoT, edge computing

**Critère de validation** :
- [ ] L'étudiant a répondu correctement aux 3 questions

---

## 2. Documentation

### 2.1 Vérification du README

**Objectif** : S'assurer que la documentation est complète et utilisable.

#### Checklist du README.md

Le README doit contenir :

- [ ] **Prérequis**
  - Logiciels requis (Vagrant, VirtualBox, kubectl, Docker)
  - Versions minimales
  - Configuration système requise

- [ ] **Configuration**
  - Instructions pour Docker Hub
  - Configuration des images
  - Personnalisation des secrets

- [ ] **Installation**
  - Guide d'installation pas à pas
  - Commandes à exécuter
  - Temps d'installation estimé

- [ ] **Usage**
  - Commandes du script orchestrator.sh
  - Comment accéder aux services
  - Exemples d'utilisation

- [ ] **Tests**
  - Comment tester les API
  - Tests de résilience
  - Tests d'auto-scaling

- [ ] **Dépannage**
  - Problèmes courants et solutions
  - Commandes de diagnostic
  - Logs et debugging

**Question** :
- ❓ **Le fichier README.md contient-il toutes les informations nécessaires ?**

---

## 3. Images Docker

### 3.1 Vérification Docker Hub

**Objectif** : Vérifier que les images sont hébergées sur Docker Hub.

#### Test

```bash
# Vérifier les images dans les manifestes
grep "image:" Manifests/**/*.yaml

# Exemple de sortie attendue :
# image: username/inventory-db:latest
# image: username/billing-db:latest
# image: username/inventory-app:latest
# image: username/billing-app:latest
# image: username/rabbitmq:latest
# image: username/api-gateway:latest
```

#### Validation

**Questions** :
- ❓ **Les images Docker sont-elles téléchargées depuis le compte Docker Hub de l'étudiant ?**
- ❓ **Toutes les images utilisées dans les manifestes sont-elles disponibles ?**

#### Vérification manuelle

Visitez : `https://hub.docker.com/u/<username>/`

Vérifiez que ces 6 images sont présentes :
1. `inventory-db`
2. `billing-db`
3. `inventory-app`
4. `billing-app`
5. `rabbitmq`
6. `api-gateway`

---

## 4. Cluster Kubernetes

### 4.1 Prérequis du Cluster

**Configuration attendue** :
- **2 machines virtuelles** via Vagrant :
  - `Master` : Maître du cluster K3s
  - `Agent` : Agent du cluster K3s
- **kubectl** installé et configuré

### 4.2 Vérification de kubectl

```bash
# Vérifier que kubectl est installé
kubectl version --client
```

**Critère** :
- [ ] kubectl est installé et configuré sur la machine de l'étudiant

### 4.3 Vérification du Cluster

```bash
# Lister les nœuds
kubectl get nodes -A

# Sortie attendue :
# NAME         STATUS   ROLES                  AGE    VERSION
# k3s-master   Ready    control-plane,master   XdXh   vX.XX.X+k3s1
# k3s-agent    Ready    <none>                 XdXh   vX.XX.X+k3s1
```

#### Checklist
- [ ] Le cluster a été créé par un fichier Vagrantfile
- [ ] Le cluster contient exactement 2 nœuds (master et agent)
- [ ] Les nœuds sont connectés et en status `Ready`
- [ ] Les versions K3s sont cohérentes

---

## 5. Infrastructure

### 5.1 Architecture Attendue

```
                     ┌─────────────────┐
                     │  API Gateway    │  ← NodePort 30000
                     │  (Deployment)   │     (Accès externe)
                     └────────┬────────┘
                              │
                 ┌────────────┴────────────┐
                 │                         │
        ┌────────▼────────┐       ┌───────▼────────┐
        │  Inventory App  │       │  Billing App   │
        │  (Deployment)   │       │  (StatefulSet) │
        │  HPA: 1-3       │       │  Replicas: 1   │
        └────────┬────────┘       └───────┬────────┘
                 │                        │
      ┌──────────▼──────────┐    ┌────────▼────────┐
      │  Inventory DB       │    │  Billing DB     │
      │  (StatefulSet)      │    │  (StatefulSet)  │
      │  PVC: 1Gi           │    │  PVC: 1Gi       │
      └─────────────────────┘    └─────────────────┘
                                         │
                                  ┌──────▼──────┐
                                  │  RabbitMQ   │
                                  │ (Deployment)│
                                  └─────────────┘
```

### 5.2 Test de Déploiement

```bash
# Créer l'infrastructure
./Scripts/orchestrator.sh create

# Sortie attendue :
# cluster created
```

#### Checklist
- [ ] L'étudiant a fourni un script `orchestrator.sh` fonctionnel
- [ ] Le script peut créer et gérer l'infrastructure
- [ ] L'étudiant a respecté l'architecture demandée
- [ ] L'infrastructure démarre correctement sans erreurs

---

## 6. Manifestes Kubernetes

### 6.1 Vérification des Manifestes

**Objectif** : S'assurer que chaque service a son manifeste et que les bonnes pratiques sont respectées.

#### Checklist
- [ ] Il existe un manifeste YAML pour **chaque service** (6 services)
- [ ] Les informations d'identification n'existent **PAS** dans les manifestes (sauf secrets.yaml)
- [ ] Les manifestes utilisent des labels cohérents
- [ ] Les ressources CPU/mémoire sont définies

### 6.2 Questions Théoriques

#### Q1 : Qu'est-ce que l'Infrastructure as Code (IaC) et quels sont ses avantages ?

**Réponse attendue** :
- Gestion de l'infrastructure via des fichiers de définition
- **Avantages** :
  - Contrôle de version
  - Reproductibilité
  - Automatisation
  - Documentation vivante
  - Collaboration
  - Récupération après sinistre

#### Q2 : Expliquez ce qu'est un manifeste Kubernetes

**Réponse attendue** :
- Fichier YAML/JSON décrivant l'état désiré des ressources
- **Composants** :
  - `apiVersion` : Version de l'API
  - `kind` : Type de ressource (Pod, Service, Deployment...)
  - `metadata` : Nom, labels, annotations
  - `spec` : Spécification de l'état désiré

#### Q3 : Expliquez chaque manifeste Kubernetes de votre projet

**L'étudiant doit expliquer** :
- Le rôle de chaque manifeste (secrets, deployments, services, statefulsets, hpa)
- Pourquoi tel service est un Deployment vs StatefulSet
- Configuration du HPA
- Configuration des PersistentVolumeClaims

**Critère** :
- [ ] L'étudiant a répondu correctement aux questions

---

## 7. Secrets et Sécurité

### 7.1 Vérification des Secrets

```bash
# Lister les secrets
kubectl get secrets

# Afficher les secrets en JSON
kubectl get secrets -o json
```

#### Checklist
- [ ] Tous les identifiants et mots de passe sont stockés dans les secrets
- [ ] Aucun mot de passe en clair dans les manifestes (sauf secrets.yaml)
- [ ] Les secrets sont correctement référencés dans les pods

#### Secrets Attendus
- `postgres-credentials` : Mots de passe PostgreSQL
- `rabbitmq-credentials` : Mot de passe RabbitMQ

**Vérification** :

```bash
# Décoder un secret
kubectl get secret postgres-credentials -o jsonpath='{.data.INVENTORY_DB_PASSWORD}' | base64 -d
```

---

## 8. Ressources Déployées

### 8.1 Vérification des Ressources

```bash
# Lister toutes les ressources
kubectl get all
```

### 8.2 Services Attendus

| Service | Type | Port | Description |
|---------|------|------|-------------|
| **inventory-database** | StatefulSet | 5432 | Base de données PostgreSQL pour l'inventaire |
| **billing-database** | StatefulSet | 5432 | Base de données PostgreSQL pour la facturation |
| **inventory-app** | Deployment | 8080 | Application d'inventaire |
| **billing-app** | StatefulSet | 8080 | Application de facturation |
| **rabbitmq** | Deployment | 5672 | File d'attente de messages |
| **api-gateway** | Deployment | 3000 | Passerelle API |

#### Checklist
- [ ] Toutes les 6 applications sont déployées
- [ ] Les bases de données sont déployées en **StatefulSet**
- [ ] Des volumes persistants (PVC) existent pour les bases de données
- [ ] `api-gateway` et `inventory-app` sont des **Deployments**
- [ ] `billing-app` est un **StatefulSet**

### 8.3 Configuration de l'Auto-Scaling

#### HPA (Horizontal Pod Autoscaler) Attendu

```bash
# Vérifier les HPA
kubectl get hpa
```

**Configuration requise** :

| Service | Type | Min Replicas | Max Replicas | CPU Trigger |
|---------|------|--------------|--------------|-------------|
| **api-gateway** | Deployment | 1 | 3 | 60% |
| **inventory-app** | Deployment | 1 | 3 | 60% |

#### Checklist
- [ ] HPA configuré pour `api-gateway`
- [ ] HPA configuré pour `inventory-app`
- [ ] Min replicas = 1, Max replicas = 3
- [ ] Seuil CPU = 60%

### 8.4 Questions Théoriques

#### Q1 : Qu'est-ce qu'un StatefulSet dans Kubernetes ?

**Réponse attendue** :
- Contrôleur pour applications stateful
- Identité réseau stable
- Stockage persistant
- Déploiement et scaling ordonnés
- Noms de pods stables (app-0, app-1...)

#### Q2 : Qu'est-ce qu'un Deployment dans Kubernetes ?

**Réponse attendue** :
- Contrôleur pour applications stateless
- Pods interchangeables
- Pas d'identité persistante
- Rolling updates
- Scaling libre

#### Q3 : Quelle est la différence entre Deployment et StatefulSet ?

**Réponse attendue** :

| Aspect | Deployment | StatefulSet |
|--------|------------|-------------|
| **État** | Stateless | Stateful |
| **Identité** | Aléatoire | Stable |
| **Stockage** | Éphémère | Persistant |
| **Ordre** | Non garanti | Ordonné |
| **Use case** | API, web apps | Bases de données |

#### Q4 : Qu'est-ce que le scaling et pourquoi l'utilisons-nous ?

**Réponse attendue** :
- Ajustement du nombre d'instances
- **Types** :
  - Horizontal : Ajout de pods
  - Vertical : Augmentation CPU/mémoire
- **Raisons** :
  - Gérer la charge variable
  - Haute disponibilité
  - Optimisation des ressources
  - Coût-efficacité

#### Q5 : Qu'est-ce qu'un load balancer et quel est son rôle ?

**Réponse attendue** :
- Distribue le trafic entre plusieurs serveurs/pods
- **Rôles** :
  - Distribution équitable de la charge
  - Haute disponibilité
  - Amélioration des performances
  - Prévention de surcharge
  - Support du scaling horizontal

#### Q6 : Pourquoi ne pas déployer la base de données en Deployment ?

**Réponse attendue** :
- Les bases de données nécessitent :
  - Stockage persistant
  - Identité réseau stable
  - Ordre de démarrage/arrêt
  - Prévention de la corruption de données
- StatefulSet garantit ces besoins

**Critères** :
- [ ] L'étudiant a répondu correctement à toutes les questions

---

## 9. Tests de la Solution

### 9.1 Tests des API d'Inventaire

#### Test 1 : Créer un Film (POST)

**Outil** : Postman ou curl

```bash
# Créer un film
curl -X POST http://[GATEWAY_IP]:30000/api/movies \
  -H "Content-Type: application/json" \
  -d '{
    "title": "A new movie",
    "description": "Very short description"
  }'
```

**Validation** :
- [ ] Code de réponse : `200 OK`
- [ ] Pas d'erreur dans les logs

#### Test 2 : Lister les Films (GET)

```bash
# Récupérer tous les films
curl http://[GATEWAY_IP]:30000/api/movies
```

**Validation** :
- [ ] Code de réponse : `200 OK`
- [ ] Le corps de réponse contient le film ajouté précédemment
- [ ] Format JSON valide

---

### 9.2 Tests de l'API de Facturation

#### Test 3 : Créer une Commande (POST)

```bash
# Créer une commande
curl -X POST http://[GATEWAY_IP]:30000/api/billing \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "20",
    "number_of_items": "99",
    "total_amount": "250"
  }'
```

**Validation** :
- [ ] Code de réponse : `200 OK`

---

### 9.3 Test de Résilience RabbitMQ

**Objectif** : Vérifier que les messages sont mis en file d'attente même lorsque billing-app est arrêté.

#### Étape 1 : Arrêter billing-app

```bash
# Arrêter le conteneur billing-app
kubectl scale statefulset billing-app --replicas=0

# Vérifier qu'il est arrêté
kubectl get pods | grep billing-app
```

**Validation** :
- [ ] Le conteneur `billing-app` est correctement arrêté

#### Étape 2 : Envoyer une Commande

```bash
# Envoyer une commande pendant que billing-app est arrêté
curl -X POST http://[GATEWAY_IP]:30000/api/billing \
  -H "Content-Type: application/json" \
  -d '{
    "user_id": "22",
    "number_of_items": "10",
    "total_amount": "50"
  }'
```

**Validation** :
- [ ] Code de réponse : `200 OK` même si `billing-app` ne fonctionne pas
- [ ] Cela prouve que le message est mis en file d'attente par RabbitMQ

#### Étape 3 : Vérifier la Base de Données

```bash
# Entrer dans le pod de la base de données
kubectl exec -it billing-db-0 -- sh

# Se connecter en tant que postgres
sudo -i -u postgres

# Ouvrir psql
psql

# Lister les bases de données
\l

# Se connecter à la base orders
\c orders

# Lister les commandes
TABLE orders;
```

**Validation** :
- [ ] La base de données `orders` est listée
- [ ] La commande avec `user_id = 20` est enregistrée
- [ ] La commande avec `user_id = 22` n'est **PAS** encore listée (car billing-app est arrêté)

#### Étape 4 : Redémarrer billing-app

```bash
# Redémarrer billing-app
kubectl scale statefulset billing-app --replicas=1

# Attendre que le pod soit prêt
kubectl wait --for=condition=ready pod -l app=billing-app --timeout=120s
```

**Validation** :
- [ ] Le conteneur `billing-app` a correctement redémarré

#### Étape 5 : Vérifier que la Commande a été Traitée

```bash
# Revérifier la base de données
kubectl exec -it billing-db-0 -- psql -U billing_user -d orders -c "SELECT * FROM orders WHERE user_id='22';"
```

**Validation** :
- [ ] La commande avec `user_id = 22` est **maintenant** correctement affichée
- [ ] Cela prouve que RabbitMQ a conservé le message et que billing-app l'a traité après redémarrage

---

### 9.4 Test d'Auto-Scaling

**Objectif** : Vérifier que le HPA fonctionne correctement.

```bash
# 1. Vérifier l'état initial du HPA
kubectl get hpa

# 2. Générer de la charge (installer hey ou apache-bench)
hey -z 60s -c 50 http://[GATEWAY_IP]:30000/api/movies

# 3. Observer le scaling en temps réel
kubectl get hpa -w

# 4. Observer les pods
kubectl get pods -w
```

**Validation** :
- [ ] Le nombre de replicas augmente de 1 à 2-3 quand CPU > 60%
- [ ] Les nouveaux pods sont créés automatiquement
- [ ] Le scaling se produit dans les 2-3 minutes

---

### 9.5 Test de Persistance des Données

**Objectif** : Vérifier que les données survivent au redémarrage des pods.

```bash
# 1. Créer un film
curl -X POST http://[GATEWAY_IP]:30000/api/movies \
  -H "Content-Type: application/json" \
  -d '{"title": "Test Persistence", "description": "Testing data persistence"}'

# 2. Supprimer le pod de la base de données
kubectl delete pod inventory-db-0

# 3. Attendre le redémarrage automatique
kubectl wait --for=condition=ready pod/inventory-db-0 --timeout=180s

# 4. Vérifier que le film existe toujours
curl http://[GATEWAY_IP]:30000/api/movies | grep "Test Persistence"
```

**Validation** :
- [ ] Le pod se recrée automatiquement (auto-healing)
- [ ] Les données sont toujours présentes après redémarrage
- [ ] Le PVC a correctement persisté les données

---

## 10. Composants Kubernetes

### 10.1 Test de Connaissance

**Format** : Présentation de 15 minutes avec l'aide de Google

**Objectif** : L'étudiant doit expliquer tous les composants de Kubernetes et leurs rôles.

### 10.2 Composants à Expliquer

#### Control Plane Components

| Composant | Rôle à Expliquer |
|-----------|------------------|
| **kube-apiserver** | Frontend de l'API Kubernetes, point d'entrée de toutes les opérations |
| **etcd** | Base de données clé-valeur pour stocker l'état du cluster |
| **kube-scheduler** | Assigne les pods aux nœuds en fonction des ressources |
| **kube-controller-manager** | Exécute les contrôleurs (ReplicaSet, Node, Service...) |
| **cloud-controller-manager** | Interface avec les API des fournisseurs cloud |

#### Node Components

| Composant | Rôle à Expliquer |
|-----------|------------------|
| **kubelet** | Agent qui s'exécute sur chaque nœud, gère les pods |
| **kube-proxy** | Proxy réseau, gère les règles de réseau sur les nœuds |
| **Container Runtime** | Logiciel qui exécute les conteneurs (Docker, containerd, CRI-O) |

#### Addons

| Composant | Rôle à Expliquer |
|-----------|------------------|
| **DNS** | Service de découverte pour les services Kubernetes |
| **Dashboard** | Interface web pour gérer le cluster |
| **Metrics Server** | Collecte les métriques de ressources pour HPA |
| **Ingress Controller** | Gère l'accès externe aux services |

### 10.3 Questions d'Approfondissement

L'auditeur peut poser ces questions :

1. **Que se passe-t-il quand vous exécutez `kubectl apply -f deployment.yaml` ?**
   - Décrivez le flux de la requête à travers les composants

2. **Comment fonctionne la découverte de services dans Kubernetes ?**
   - Expliquez le rôle du DNS et des Services

3. **Qu'est-ce qui se passe quand un pod crash ?**
   - Expliquez le rôle du kubelet et des controllers

4. **Comment le HPA sait-il quand scaler ?**
   - Expliquez le rôle du metrics-server

**Critère** :
- [ ] L'étudiant peut expliquer les composants K8s en moins de 15 minutes
- [ ] Les explications sont correctes et montrent une compréhension solide

---

## Grille d'Évaluation

### Résumé des Critères

| Section | Points | Validation |
|---------|--------|------------|
| **1. Structure du Projet** | 10 | □ Structure conforme ou justifiée |
| **2. Documentation** | 10 | □ README complet et clair |
| **3. Images Docker** | 10 | □ Images sur Docker Hub de l'étudiant |
| **4. Cluster K3s** | 15 | □ 2 nœuds fonctionnels avec kubectl |
| **5. Infrastructure** | 15 | □ Architecture conforme et déployable |
| **6. Manifestes K8s** | 10 | □ Manifestes corrects et sécurisés |
| **7. Secrets** | 5 | □ Credentials dans secrets uniquement |
| **8. Ressources** | 15 | □ Tous les services déployés correctement |
| **9. Tests** | 30 | □ Tous les tests passent |
| **10. Connaissances** | 30 | □ Questions théoriques réussies |
| **BONUS : Auto-scaling** | +10 | □ HPA fonctionne correctement |

**Total** : 150 points (+ 10 bonus)

---

## Checklist Finale pour l'Auditeur

### Avant de Commencer l'Audit
- [ ] Vérifier que l'étudiant a accès à sa machine
- [ ] Vérifier que Vagrant, kubectl et Docker sont installés
- [ ] Avoir Postman ou curl disponible pour les tests API
- [ ] Préparer un chronomètre pour la partie "Composants K8s"

### Pendant l'Audit
- [ ] Prendre des notes sur chaque section
- [ ] Poser des questions de clarification si nécessaire
- [ ] Vérifier visuellement les commandes exécutées
- [ ] Demander à l'étudiant d'expliquer ce qu'il fait

### Après l'Audit
- [ ] Remplir la grille d'évaluation
- [ ] Donner un feedback constructif
- [ ] Identifier les points forts et les axes d'amélioration
- [ ] Suggérer des améliorations potentielles

---

## Conseils pour l'Auditeur

### Bonnes Pratiques
1. **Soyez patient** : Certaines opérations (démarrage de VMs, déploiement) prennent du temps
2. **Posez des questions ouvertes** : "Expliquez-moi comment..." plutôt que "Est-ce que... ?"
3. **Vérifiez la compréhension** : Ne vous contentez pas de "ça marche", demandez "pourquoi ça marche ?"
4. **Soyez juste** : Si la solution diffère mais fonctionne, demandez la justification

### Points d'Attention
- ⚠️ Les identifiants en clair dans les manifestes (sauf secrets) = échec automatique
- ⚠️ Absence de HPA = perte de points importante
- ⚠️ Tests de résilience échoués = problème d'architecture
- ⚠️ Données perdues après restart = StatefulSet mal configuré

---

## Ressources pour l'Auditeur

### Documentation Officielle
- Kubernetes : https://kubernetes.io/docs/
- K3s : https://docs.k3s.io/
- Vagrant : https://www.vagrantup.com/docs

### Commandes Utiles

```bash
# Debugging rapide
kubectl get all
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl get events --sort-by='.lastTimestamp'

# Vérification des ressources
kubectl top nodes
kubectl top pods

# Inspection des secrets
kubectl get secrets
kubectl describe secret <secret-name>

# État du HPA
kubectl get hpa
kubectl describe hpa <hpa-name>
```

---

**Dernière mise à jour** : 2024

**Version** : 1.0

**Auteur** : Guide d'audit pour projet Kubernetes/K3s
