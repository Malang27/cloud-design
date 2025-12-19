# 🚀 Cloud Design - Microservices sur AWS

**Projet**: Déploiement de microservices sur AWS avec EKS, RDS, et Amazon MQ
**Infrastructure**: Amazon Web Services (AWS)
**IaC**: Terraform
**Orchestration**: Amazon EKS (Elastic Kubernetes Service)

---

## 📋 Vue d'ensemble

Application microservices complète déployée sur AWS avec:
- **Amazon EKS** - Kubernetes managé
- **RDS PostgreSQL** - 2 databases Multi-AZ (inventory + billing)
- **Amazon MQ** - RabbitMQ managé pour messaging
- **ALB** - Application Load Balancer avec HTTPS
- **Cognito** - Authentication managée
- **CloudWatch** - Monitoring et logging
- **Auto-Scaling** - HPA + Cluster Autoscaler + KEDA

---

## 🏗️ Architecture

```
                          Internet
                             │
                             ▼
                    ┌─────────────────┐
                    │  Route 53 (DNS) │
                    │  + CloudFront   │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │   AWS ALB       │
                    │   (HTTPS)       │
                    └────────┬────────┘
                             │
                   ┌─────────┴─────────┐
                   │                   │
                   ▼                   ▼
        ┌──────────────────┐ ┌──────────────────┐
        │   AZ 1           │ │   AZ 2           │
        │                  │ │                  │
        │  ┌────────────┐  │ │  ┌────────────┐  │
        │  │  EKS Nodes │  │ │  │  EKS Nodes │  │
        │  │            │  │ │  │            │  │
        │  │ API Gateway│  │ │  │ API Gateway│  │
        │  │ Inventory  │  │ │  │ Inventory  │  │
        │  │ Billing    │  │ │  │ Billing    │  │
        │  └────────────┘  │ │  └────────────┘  │
        └──────────────────┘ └──────────────────┘
                   │                   │
                   ▼                   ▼
        ┌──────────────────────────────────────┐
        │      Amazon MQ (RabbitMQ)            │
        │         Multi-AZ Cluster             │
        └──────────────────────────────────────┘
                   │                   │
                   ▼                   ▼
        ┌──────────────┐       ┌──────────────┐
        │ RDS PostgreSQL│       │ RDS PostgreSQL│
        │  Inventory DB │       │  Billing DB  │
        │   Multi-AZ    │       │   Multi-AZ   │
        └──────────────┘       └──────────────┘
```

---

## 🚀 Quick Start

### Prérequis

- **AWS CLI** >= 2.x ([Installation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html))
- **Terraform** >= 1.6.0 ([Installation](https://learn.hashicorp.com/tutorials/terraform/install-cli))
- **kubectl** >= 1.28 ([Installation](https://kubernetes.io/docs/tasks/tools/))
- **Docker Desktop** ([Installation](https://www.docker.com/products/docker-desktop))
- **Helm** >= 3.x ([Installation](https://helm.sh/docs/intro/install/))

### Installation rapide (5 minutes)

```bash
# 1. Cloner le repository
git clone https://github.com/your-org/cloud-design-aws.git
cd cloud-design-aws

# 2. Configurer AWS credentials
aws configure
# AWS Access Key ID: VOTRE_ACCESS_KEY
# AWS Secret Access Key: VOTRE_SECRET_KEY
# Default region: us-east-1

# 3. Initialiser Terraform
cd terraform
terraform init

# 4. Déployer l'infrastructure (15-20 minutes)
terraform plan
terraform apply

# 5. Configurer kubectl pour EKS
aws eks update-kubeconfig --name cloud-design-production --region us-east-1

# 6. Vérifier le cluster
kubectl get nodes
kubectl get pods --all-namespaces

# 7. Déployer les applications
cd ../kubernetes
kubectl apply -f manifests/

# 8. Attendre que tous les pods soient Running
kubectl wait --for=condition=ready pod --all --timeout=300s

# 9. Obtenir l'URL de l'ALB
kubectl get ingress
```

---

## 📊 Composants de l'infrastructure

| Composant | Type | Quantité | Coût mensuel |
|-----------|------|----------|--------------|
| **EKS Cluster** | Control Plane | 1 | $0 (Free Tier 1 an) |
| **EKS Nodes** | t3.medium | 3-10 (auto-scale) | $45-150 |
| **RDS Inventory** | db.t3.micro Multi-AZ | 1 | $27 |
| **RDS Billing** | db.t3.micro Multi-AZ | 1 | $27 |
| **Amazon MQ** | mq.t3.micro Cluster | 1 | $32 |
| **ALB** | Application Load Balancer | 1 | $16 |
| **NAT Gateway** | Multi-AZ | 2 | $66 |
| **S3 + CloudWatch** | Logs & Monitoring | - | $5-10 |
| **TOTAL** | | | **~$218-300/mois** |

**Optimisations possibles**: $150/mois avec Spot Instances, Reserved Instances, et VPC Endpoints

---

## 🔒 Sécurité

✅ **Network Security**
- VPC privé avec Security Groups restrictifs
- Databases et RabbitMQ dans sous-réseaux privés
- Pas d'accès Internet direct (NAT Gateway uniquement)

✅ **Data Security**
- Chiffrement at rest (KMS) pour RDS, EBS, S3
- Chiffrement in transit (TLS/SSL) partout
- Secrets dans AWS Secrets Manager avec rotation automatique

✅ **Access Control**
- IAM Roles avec principe du moindre privilège
- IRSA (IAM Roles for Service Accounts)
- Cognito pour authentication utilisateurs
- MFA optionnel

✅ **Monitoring & Audit**
- GuardDuty pour détection de menaces
- Security Hub pour conformité
- CloudTrail pour audit de toutes les actions

---

## 📈 Auto-Scaling

### Level 1: Horizontal Pod Autoscaler (HPA)
- **API Gateway**: 2-10 replicas (CPU 70%, Memory 80%)
- **Inventory App**: 1-5 replicas (CPU 75%)
- **Billing App**: 1-10 replicas (RabbitMQ queue depth)

### Level 2: Cluster Autoscaler
- **EKS Nodes**: 2-10 nodes t3.medium
- Scale up quand pods pending
- Scale down après 10min sous 50% utilization

### Level 3: RDS Auto Scaling
- **Read Replicas**: 1-5 replicas
- Scale basé sur CPU et connections

---

## 📊 Monitoring

### CloudWatch
- **Logs**: Tous les composants (EKS, RDS, ALB, Apps)
- **Metrics**: CPU, Memory, Network, Custom metrics
- **Alarms**: 15+ alarmes configurées
- **Dashboard**: Vue d'ensemble temps réel

### Prometheus + Grafana
- Métriques Kubernetes détaillées
- Dashboards custom pour chaque microservice
- Alerting Manager pour notifications

### AWS X-Ray
- Distributed tracing
- Analyse de latence end-to-end
- Identification des bottlenecks

---

## 🛠️ Scripts utiles

```bash
# Déployer une nouvelle version
./scripts/deploy.sh api-gateway v1.2.0

# Scale manuellement
./scripts/scale.sh api-gateway 10

# Backup manuel RDS
./scripts/backup-rds.sh inventory-db

# Tests de charge
./scripts/load-test.sh

# Health check quotidien
./scripts/daily-health-check.sh

# Cleanup des ressources anciennes
./scripts/cleanup.sh
```

---

## 📚 Documentation

- [**GETTING_STARTED.md**](docs/GETTING_STARTED.md) - Guide de démarrage détaillé
- [**ARCHITECTURE.md**](docs/ARCHITECTURE.md) - Architecture complète
- [**DEPLOYMENT.md**](docs/DEPLOYMENT.md) - Guide de déploiement
- [**SECURITY.md**](docs/SECURITY.md) - Pratiques de sécurité
- [**MONITORING.md**](docs/MONITORING.md) - Guide monitoring
- [**TROUBLESHOOTING.md**](docs/TROUBLESHOOTING.md) - Résolution de problèmes
- [**RUNBOOK.md**](docs/RUNBOOK.md) - Procédures opérationnelles
- [**DISASTER_RECOVERY.md**](docs/DISASTER_RECOVERY.md) - Plan de reprise

---

## 🧪 Tests

```bash
# Unit tests
npm test

# Integration tests
npm run test:integration

# Load tests (k6)
./scripts/load-test.sh

# Security scan (Trivy)
./scripts/security-scan.sh
```

---

## 🗂️ Structure du projet

```
cloud-design-aws/
├── terraform/                      # Infrastructure as Code
│   ├── main.tf                     # Configuration principale
│   ├── variables.tf                # Variables
│   ├── outputs.tf                  # Outputs
│   ├── backend.tf                  # S3 backend
│   ├── modules/                    # Modules réutilisables
│   │   ├── vpc/                    # VPC + Subnets
│   │   ├── eks/                    # EKS Cluster
│   │   ├── rds/                    # RDS PostgreSQL
│   │   ├── mq/                     # Amazon MQ
│   │   ├── alb/                    # Application Load Balancer
│   │   ├── cognito/                # Cognito User Pool
│   │   └── monitoring/             # CloudWatch + Alarms
│   └── environments/               # Configurations par environnement
│       ├── dev/
│       ├── staging/
│       └── production/
├── kubernetes/                     # Manifests Kubernetes
│   └── manifests/
│       ├── deployments/            # Deployments
│       ├── services/               # Services
│       ├── configmaps/             # ConfigMaps
│       ├── secrets/                # ExternalSecrets
│       ├── hpa/                    # HorizontalPodAutoscalers
│       ├── ingress/                # Ingress
│       └── network-policies/       # NetworkPolicies
├── apps/                           # Applications
│   ├── api-gateway/                # API Gateway
│   │   ├── Dockerfile
│   │   ├── src/
│   │   └── package.json
│   ├── inventory-app/              # Inventory App
│   │   ├── Dockerfile
│   │   ├── src/
│   │   └── package.json
│   └── billing-app/                # Billing App
│       ├── Dockerfile
│       ├── src/
│       └── package.json
├── scripts/                        # Scripts utilitaires
│   ├── deploy.sh
│   ├── scale.sh
│   ├── backup-rds.sh
│   ├── load-test.sh
│   └── cleanup.sh
├── docs/                           # Documentation
│   ├── ARCHITECTURE.md
│   ├── DEPLOYMENT.md
│   ├── SECURITY.md
│   └── RUNBOOK.md
├── .github/workflows/              # CI/CD GitHub Actions
│   └── deploy.yml
├── .gitignore
└── README.md
```

---

## 🚨 Troubleshooting

### Pods en CrashLoopBackOff
```bash
kubectl logs <pod-name>
kubectl describe pod <pod-name>
kubectl get events --sort-by='.lastTimestamp'
```

### RDS connection issues
```bash
# Vérifier Security Groups
aws ec2 describe-security-groups --group-ids <sg-id>

# Tester la connexion
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- psql -h <rds-endpoint> -U <user> -d <database>
```

### High costs
```bash
# Analyser les coûts
aws ce get-cost-and-usage --time-period Start=2025-01-01,End=2025-01-31 --granularity MONTHLY --metrics BlendedCost
```

---

## 📞 Support

- **Email**: devops@example.com
- **Slack**: #cloud-design
- **On-call**: PagerDuty
- **Documentation**: [Wiki interne](https://wiki.example.com/cloud-design)

---

## 🤝 Contribution

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

---

## 📝 License

MIT License - voir le fichier [LICENSE](LICENSE) pour plus de détails.

---

## 🏆 Auteurs

- **Équipe DevOps** - *Initial work*
- **Équipe Backend** - *Microservices*
- **Équipe SRE** - *Monitoring & Reliability*

---

**Version**: 1.0.0
**Dernière mise à jour**: 2025-12-19
