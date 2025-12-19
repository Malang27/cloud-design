# 🚀 Guide de Démarrage - Cloud Design AWS

Ce guide vous accompagne étape par étape pour déployer l'infrastructure complète sur AWS.

---

## 📋 Prérequis

### Outils requis

| Outil | Version | Installation |
|-------|---------|--------------|
| **AWS CLI** | >= 2.x | [Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) |
| **Terraform** | >= 1.6.0 | [Guide](https://learn.hashicorp.com/tutorials/terraform/install-cli) |
| **kubectl** | >= 1.28 | [Guide](https://kubernetes.io/docs/tasks/tools/) |
| **Docker** | >= 20.x | [Guide](https://docs.docker.com/get-docker/) |
| **Helm** | >= 3.x | [Guide](https://helm.sh/docs/intro/install/) |

### Compte AWS

- Compte AWS avec permissions AdministratorAccess (ou équivalent)
- Access Key ID et Secret Access Key
- Crédit suffisant (environ $150-300/mois pour la production)

---

## 🔧 Étape 1: Configuration AWS CLI

```bash
# Configurer AWS CLI
aws configure

# Entrer vos credentials
AWS Access Key ID: VOTRE_ACCESS_KEY
AWS Secret Access Key: VOTRE_SECRET_KEY
Default region name: us-east-1
Default output format: json

# Vérifier la configuration
aws sts get-caller-identity
```

**Résultat attendu**:
```json
{
    "UserId": "AIDAXXXXXXXXXXXXXXXXX",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/votre-user"
}
```

---

## 🗄️ Étape 2: Créer le Backend Terraform

Avant de déployer l'infrastructure, vous devez créer le backend S3 pour stocker l'état Terraform.

```bash
# 1. Créer le bucket S3
aws s3api create-bucket \
  --bucket cloud-design-terraform-state \
  --region us-east-1

# 2. Activer le versioning
aws s3api put-bucket-versioning \
  --bucket cloud-design-terraform-state \
  --versioning-configuration Status=Enabled

# 3. Activer le chiffrement
aws s3api put-bucket-encryption \
  --bucket cloud-design-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# 4. Bloquer l'accès public
aws s3api put-public-access-block \
  --bucket cloud-design-terraform-state \
  --public-access-block-configuration \
    BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

# 5. Créer la table DynamoDB pour le locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

# 6. Vérifier la création
aws s3 ls | grep cloud-design-terraform-state
aws dynamodb describe-table --table-name terraform-locks --query 'Table.TableStatus'
```

---

## 🏗️ Étape 3: Déployer l'Infrastructure avec Terraform

```bash
# 1. Cloner le repository
git clone https://github.com/your-org/cloud-design-aws.git
cd cloud-design-aws

# 2. Aller dans le dossier Terraform
cd terraform

# 3. Initialiser Terraform
terraform init

# Résultat attendu:
# Terraform has been successfully initialized!

# 4. Valider la configuration
terraform validate

# 5. Formater le code (optionnel)
terraform fmt -recursive

# 6. Voir le plan d'exécution
terraform plan

# 7. Appliquer la configuration (15-20 minutes)
terraform apply

# Confirmer avec: yes
```

**Durée approximative**: 15-20 minutes

**Ressources créées**:
- 1 VPC avec 6 subnets (2 publics, 2 privés, 2 database)
- 2 NAT Gateways
- 1 EKS Cluster avec 3 nodes
- 2 RDS PostgreSQL Multi-AZ
- 1 Amazon MQ (RabbitMQ) Cluster Multi-AZ
- 1 Application Load Balancer
- 1 Cognito User Pool
- CloudWatch Log Groups et Alarms
- Security Groups et IAM Roles

---

## ⚙️ Étape 4: Configurer kubectl

```bash
# 1. Configurer kubectl pour EKS
aws eks update-kubeconfig \
  --name cloud-design-production \
  --region us-east-1

# 2. Vérifier la connexion
kubectl get nodes

# Résultat attendu:
# NAME                          STATUS   ROLES    AGE   VERSION
# ip-10-0-10-xxx.ec2.internal   Ready    <none>   5m    v1.28.x
# ip-10-0-11-xxx.ec2.internal   Ready    <none>   5m    v1.28.x
# ip-10-0-10-yyy.ec2.internal   Ready    <none>   5m    v1.28.x

# 3. Vérifier les namespaces
kubectl get namespaces
```

---

## 🛠️ Étape 5: Installer les Add-ons Kubernetes

### 5.1 Metrics Server (requis pour HPA)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Vérifier
kubectl get deployment metrics-server -n kube-system
kubectl top nodes
```

### 5.2 AWS Load Balancer Controller

```bash
# 1. Créer l'IAM policy
curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.6.0/docs/install/iam_policy.json

aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam_policy.json

# 2. Installer avec Helm
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=cloud-design-production \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 5.3 Cluster Autoscaler

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/autoscaler/master/cluster-autoscaler/cloudprovider/aws/examples/cluster-autoscaler-autodiscover.yaml

# Éditer pour ajouter le nom du cluster
kubectl -n kube-system edit deployment cluster-autoscaler

# Ajouter: --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/cloud-design-production
```

### 5.4 External Secrets Operator (pour AWS Secrets Manager)

```bash
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets \
   external-secrets/external-secrets \
    -n external-secrets-system \
    --create-namespace
```

---

## 📦 Étape 6: Build et Push des Images Docker

```bash
# Retourner à la racine du projet
cd ..

# Login Docker Hub (ou ECR)
docker login

# Ou pour ECR:
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com

# Build et push API Gateway
cd apps/api-gateway
docker build -t your-username/api-gateway:latest .
docker push your-username/api-gateway:latest

# Build et push Inventory App
cd ../inventory-app
docker build -t your-username/inventory-app:latest .
docker push your-username/inventory-app:latest

# Build et push Billing App
cd ../billing-app
docker build -t your-username/billing-app:latest .
docker push your-username/billing-app:latest

cd ../..
```

---

## 🚀 Étape 7: Déployer les Applications

```bash
# 1. Aller dans le dossier Kubernetes
cd kubernetes/manifests

# 2. Créer les secrets (via External Secrets)
kubectl apply -f secrets/

# 3. Créer les ConfigMaps
kubectl apply -f configmaps/

# 4. Déployer les applications
kubectl apply -f deployments/

# 5. Créer les services
kubectl apply -f services/

# 6. Créer les HPAs
kubectl apply -f hpa/

# 7. Créer l'Ingress
kubectl apply -f ingress/

# 8. Attendre que tous les pods soient Running
kubectl wait --for=condition=ready pod --all --timeout=300s

# 9. Vérifier le déploiement
kubectl get pods
kubectl get svc
kubectl get ingress
```

---

## ✅ Étape 8: Vérification et Tests

### 8.1 Vérifier les Pods

```bash
kubectl get pods

# Résultat attendu:
# NAME                           READY   STATUS    RESTARTS   AGE
# api-gateway-xxxx-yyyy          1/1     Running   0          2m
# api-gateway-xxxx-zzzz          1/1     Running   0          2m
# inventory-app-xxxx-yyyy        1/1     Running   0          2m
# billing-app-xxxx-yyyy          1/1     Running   0          2m
```

### 8.2 Vérifier les Services

```bash
kubectl get svc

# Vérifier que l'ALB est créé
kubectl get ingress
```

### 8.3 Tester les APIs

```bash
# Obtenir l'URL de l'ALB
ALB_URL=$(kubectl get ingress api-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "ALB URL: http://$ALB_URL"

# Test Health Check
curl http://$ALB_URL/health

# Test Inventory API
curl http://$ALB_URL/api/movies/

# Test Billing API
curl -X POST http://$ALB_URL/api/billing/ \
  -H "Content-Type: application/json" \
  -d '{"user_id":"1","number_of_items":"5","total_amount":"100"}'
```

---

## 📊 Étape 9: Monitoring

### 9.1 CloudWatch Dashboard

```bash
# Ouvrir le dashboard
echo "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=cloud-design-production"
```

### 9.2 Installer Prometheus + Grafana (optionnel)

```bash
# Installer kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  -n monitoring \
  --create-namespace

# Accéder à Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# Login: admin / prom-operator
```

---

## 🧹 Étape 10: Cleanup (si nécessaire)

```bash
# ATTENTION: Ceci supprimera TOUTE l'infrastructure

# 1. Supprimer les applications Kubernetes
kubectl delete -f kubernetes/manifests/ --recursive

# 2. Attendre que l'ALB soit supprimé
kubectl get ingress --watch

# 3. Détruire l'infrastructure Terraform
cd terraform
terraform destroy

# Confirmer avec: yes

# 4. Supprimer le backend (optionnel)
aws s3 rm s3://cloud-design-terraform-state --recursive
aws s3 rb s3://cloud-design-terraform-state --force
aws dynamodb delete-table --table-name terraform-locks
```

---

## 🚨 Troubleshooting

### Pods en CrashLoopBackOff

```bash
# Vérifier les logs
kubectl logs <pod-name>

# Vérifier les events
kubectl describe pod <pod-name>

# Vérifier les events du cluster
kubectl get events --sort-by='.lastTimestamp'
```

### Terraform errors

```bash
# Rafraîchir l'état
terraform refresh

# Re-initialiser
terraform init -upgrade

# Voir l'état
terraform show
```

### kubectl ne se connecte pas

```bash
# Re-configurer
aws eks update-kubeconfig --name cloud-design-production --region us-east-1

# Vérifier le contexte
kubectl config current-context

# Lister les contextes
kubectl config get-contexts
```

---

## 📞 Support

- **Email**: devops@example.com
- **Slack**: #cloud-design
- **Documentation**: [Wiki](https://wiki.example.com/cloud-design)

---

## 🎉 Félicitations!

Votre infrastructure AWS est maintenant déployée et opérationnelle!

**Prochaines étapes**:
1. Configurer les alertes CloudWatch
2. Mettre en place le CI/CD
3. Configurer les backups automatiques
4. Documenter les procédures opérationnelles
5. Former l'équipe

---

**Version**: 1.0.0
**Dernière mise à jour**: 2025-12-19
