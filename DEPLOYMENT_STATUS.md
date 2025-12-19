# État du Déploiement - Orchestrator K3s

**Dernière mise à jour** : 2024-12-08

---

## 📊 Configuration Actuelle

### Système
- **OS** : Windows 10/11
- **VirtualBox** : Version 7.2
- **Vagrant** : Installé
- **kubectl** : Installé

### Cluster K3s
- **Type** : 1 nœud (Master uniquement)
- **Version K3s** : v1.28.5+k3s1
- **Configuration** : Minimale optimisée pour Windows
- **RAM Master** : 3GB
- **CPU Master** : 2 cores

---

## ✅ Solutions Appliquées

### 1. Problème : VirtualBox "Not signed with build certificate"
**Solution** : VirtualBox réinstallé avec succès ✓

### 2. Problème : Timeout SSH lors du démarrage
**Solutions appliquées** :
- ✅ Augmentation du timeout à 15 minutes (`config.vm.boot_timeout = 900`)
- ✅ RAM du master augmentée à 3GB (au lieu de 2GB)
- ✅ Activation de `linked_clone` pour performance
- ✅ Désactivation du serial port (problème connu sur Windows)
- ✅ Configuration minimale (1 nœud au lieu de 2)

### 3. Vagrantfile optimisé
**Fichiers** :
- `Vagrantfile.backup` : Configuration originale (2 nœuds)
- `Vagrantfile` : Configuration minimale actuelle (1 nœud)
- `Vagrantfile.minimal` : Template de la config minimale

---

## 🚀 Démarrage en Cours

### Commande exécutée
```bash
vagrant up k3s-master
```

### Progression attendue
1. ⏳ Import de la box Ubuntu (2-3 minutes)
2. ⏳ Démarrage de la VM (1-2 minutes)
3. ⏳ Connexion SSH (peut prendre jusqu'à 15 minutes)
4. ⏳ Installation de K3s (3-5 minutes)
5. ✅ Cluster prêt !

**Durée totale estimée** : 10-20 minutes

---

## 📝 Vérifications à Faire Après Démarrage

### 1. Vérifier le statut Vagrant
```bash
vagrant status
# Devrait afficher : k3s-master running (virtualbox)
```

### 2. Vérifier le fichier kubeconfig
```bash
ls -la .kube/config
# Le fichier doit exister
```

### 3. Configurer kubectl
```bash
export KUBECONFIG=$(pwd)/.kube/config
```

### 4. Vérifier les nœuds
```bash
kubectl get nodes
# Devrait afficher :
# NAME         STATUS   ROLES                  AGE   VERSION
# k3s-master   Ready    control-plane,master   XXm   v1.28.5+k3s1
```

### 5. Vérifier les pods système
```bash
kubectl get pods -A
# Tous les pods kube-system doivent être Running
```

---

## 🎯 Prochaines Étapes (Après Démarrage Réussi)

### Option A : Déployer les Applications (1 nœud)
```bash
# Le cluster à 1 nœud peut exécuter toutes les applications
./Scripts/orchestrator.sh create
```

### Option B : Ajouter l'Agent (2 nœuds)
```bash
# Si le master fonctionne bien, vous pouvez ajouter l'agent
vagrant up k3s-agent
```

### Option C : Tests et Validation
Suivre le guide d'audit :
1. Ouvrir `AUDIT_CHECKLIST.md`
2. Exécuter les tests de la section 4 (Cluster K3s)
3. Continuer avec les tests API

---

## 🔧 Commandes Utiles

### Gestion du Cluster
```bash
# Voir l'état
vagrant status

# SSH vers le master
vagrant ssh k3s-master

# Redémarrer le master
vagrant reload k3s-master

# Arrêter le cluster (préserve les données)
vagrant halt

# Démarrer le cluster arrêté
vagrant up

# Détruire complètement
vagrant destroy -f
```

### Debugging
```bash
# Voir les logs Vagrant
cat vagrant-up.log

# Voir les logs K3s (depuis le master)
vagrant ssh k3s-master -c "sudo journalctl -u k3s -f"

# Vérifier les ressources
vagrant ssh k3s-master -c "free -h && df -h"
```

---

## ⚠️ Si le Démarrage Échoue Encore

### Solution Ultime : Activer la Console GUI

Modifiez le Vagrantfile :
```ruby
vb.gui = true  # Changer false à true
```

Puis :
```bash
vagrant destroy -f
vagrant up k3s-master
```

Une fenêtre VirtualBox s'ouvrira. Vous pourrez voir :
- ✅ Si la VM démarre correctement
- ✅ Les messages d'erreur éventuels
- ✅ Le processus de boot complet

### Alternative : Docker Desktop + K3d

Si VirtualBox continue à poser problème :

1. Désinstaller VirtualBox et Vagrant
2. Installer Docker Desktop : https://www.docker.com/products/docker-desktop
3. Utiliser K3d au lieu de K3s :
   ```bash
   # Installer K3d
   curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

   # Créer un cluster
   k3d cluster create mycluster --agents 1

   # Vérifier
   kubectl get nodes
   ```

---

## 📞 Support

### Logs à Vérifier
1. `vagrant-up.log` : Dans le dossier orchestrator
2. VirtualBox logs : `C:\Users\lomao\VirtualBox VMs\k3s-master\Logs\`
3. K3s logs : `vagrant ssh k3s-master`, puis `sudo journalctl -u k3s`

### Informations Système
Pour débugger, fournir :
```bash
# Version Windows
winver

# RAM disponible
systeminfo | findstr "Mémoire"

# Version VirtualBox
vboxmanage --version

# Version Vagrant
vagrant --version
```

---

## 📚 Documentation de Référence

- [README.md](README.md) : Documentation complète du projet
- [AUDIT_GUIDE.md](AUDIT_GUIDE.md) : Guide d'audit détaillé
- [AUDIT_CHECKLIST.md](AUDIT_CHECKLIST.md) : Checklist imprimable
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) : Guide de dépannage
- [DELETE_VAGRANT.md](DELETE_VAGRANT.md) : Comment supprimer les VMs

---

## ✅ Checklist de Validation Finale

Avant de considérer le déploiement comme réussi :

- [ ] `vagrant status` montre "running"
- [ ] `.kube/config` existe
- [ ] `kubectl get nodes` fonctionne
- [ ] Le nœud est en status "Ready"
- [ ] Les pods kube-system sont "Running"
- [ ] Accès SSH fonctionne : `vagrant ssh k3s-master`

Une fois toutes ces étapes validées, le cluster est **opérationnel** ! 🎉

---

**Note** : Ce document sera mis à jour avec le résultat du démarrage en cours.
