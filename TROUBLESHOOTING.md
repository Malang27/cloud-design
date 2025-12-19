# Guide de Dépannage - Orchestrator K3s

Ce document contient les solutions aux problèmes courants rencontrés lors du déploiement du cluster K3s.

---

## ❌ Erreur : VirtualBox "Not signed with the build certificate"

### Symptômes
```
VBoxManage.exe: error: The virtual machine 'k3s-master' has terminated unexpectedly
during startup with exit code 1 (0x1)
```

**Log VBoxHardening.log** :
```
VBoxDrvStub error: Signature #1/1: Not signed with the build certificate
```

### Cause
VirtualBox détecte que ses fichiers binaires n'ont pas la signature numérique attendue.

### Solutions

#### ✅ Solution 1 : Réinstaller VirtualBox (RECOMMANDÉ)

**Étape 1 : Désinstaller complètement VirtualBox**

```bash
# Détruire toutes les VMs Vagrant
cd /c/Users/lomao/Desktop/note/orchestrator
vagrant destroy -f

# Désinstaller VirtualBox via Windows :
# 1. Panneau de configuration > Désinstaller un programme
# 2. Trouver "Oracle VM VirtualBox" et désinstaller
# 3. Redémarrer l'ordinateur
```

**Étape 2 : Nettoyer les fichiers résiduels**

Supprimer manuellement :
- `C:\Program Files\Oracle\VirtualBox\`
- `C:\Users\<username>\VirtualBox VMs\`
- `C:\Users\<username>\.VirtualBox\`

**Étape 3 : Réinstaller VirtualBox**

1. Télécharger la dernière version : https://www.virtualbox.org/wiki/Downloads
2. **Exécuter l'installeur en tant qu'administrateur** (clic droit > "Exécuter en tant qu'administrateur")
3. Suivre l'installation par défaut
4. Redémarrer l'ordinateur

**Étape 4 : Vérifier l'installation**

```bash
# Vérifier que VirtualBox fonctionne
vboxmanage --version

# Devrait afficher : 7.x.x r...
```

**Étape 5 : Relancer Vagrant**

```bash
cd /c/Users/lomao/Desktop/note/orchestrator
vagrant up
```

---

#### ✅ Solution 2 : Désactiver le Hardening VirtualBox

**⚠️ ATTENTION** : Cette solution est moins sécurisée mais peut fonctionner temporairement.

**Windows (Exécuter en tant qu'administrateur PowerShell)** :

```powershell
# Ouvrir PowerShell en tant qu'administrateur

# Ajouter une variable d'environnement système
[System.Environment]::SetEnvironmentVariable("VBOX_USER_HOME", "$env:USERPROFILE\.VirtualBox", "User")
[System.Environment]::SetEnvironmentVariable("VBOX_HWVIRTEX_IGNORE_SVM_IN_USE", "1", "Machine")

# Désactiver le hardening (pas recommandé en production)
cd "C:\Program Files\Oracle\VirtualBox"
.\VBoxManage.exe setextradata global "VBoxInternal/CPUM/EnableHVP" 0
```

Puis redémarrer l'ordinateur et réessayer `vagrant up`.

---

#### ✅ Solution 3 : Vérifier l'Antivirus

Certains antivirus (Windows Defender, Avast, Kaspersky, etc.) peuvent bloquer ou modifier les fichiers VirtualBox.

**Étape 1 : Ajouter des exceptions dans l'antivirus**

Ajouter ces dossiers aux exceptions :
- `C:\Program Files\Oracle\VirtualBox\`
- `C:\Users\<username>\VirtualBox VMs\`
- `C:\Users\<username>\.vagrant.d\`

**Windows Defender** :
1. Paramètres > Mise à jour et sécurité > Sécurité Windows
2. Protection contre les virus et menaces
3. Gérer les paramètres > Exclusions
4. Ajouter une exclusion > Dossier
5. Ajouter les 3 dossiers ci-dessus

**Étape 2 : Désactiver temporairement l'antivirus** (pour tester)

Si le problème disparaît, c'est bien l'antivirus qui bloque VirtualBox.

---

#### ✅ Solution 4 : Vérifier Hyper-V (Windows 10/11)

Hyper-V et VirtualBox ne peuvent pas fonctionner en même temps.

**Vérifier si Hyper-V est activé** :

```powershell
# PowerShell en tant qu'administrateur
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V
```

**Si Hyper-V est activé, le désactiver** :

```powershell
# PowerShell en tant qu'administrateur
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All

# Redémarrer l'ordinateur
```

**Alternatives si vous devez garder Hyper-V** :
- Utiliser **Docker Desktop avec WSL2** au lieu de VirtualBox
- Utiliser **Hyper-V** comme provider pour Vagrant (modifier le Vagrantfile)

---

#### ✅ Solution 5 : Vérifier la Virtualisation dans le BIOS

VirtualBox nécessite que la virtualisation soit activée dans le BIOS.

**Vérifier si la virtualisation est activée** :

```powershell
# PowerShell
systeminfo | findstr /C:"Hyper-V"

# Devrait afficher : "Hyper-V Requirements: VM Monitor Mode Extensions: Yes"
```

**Si la virtualisation n'est pas activée** :

1. Redémarrer l'ordinateur
2. Entrer dans le BIOS (généralement F2, F10, Del, ou Esc au démarrage)
3. Chercher "Virtualization Technology" ou "Intel VT-x" ou "AMD-V"
4. Activer cette option
5. Sauvegarder et redémarrer

---

### Vérification après la Solution

Après avoir appliqué une solution, testez avec :

```bash
cd /c/Users/lomao/Desktop/note/orchestrator

# Nettoyer l'ancien état
vagrant destroy -f
rm -rf .vagrant/ .kube/ .k3s-token

# Redémarrer
vagrant up

# Vérifier les nœuds
export KUBECONFIG=$(pwd)/.kube/config
kubectl get nodes
```

---

## ❌ Erreur : kubectl "Unable to connect to the server: dial tcp [::1]:8080"

### Symptômes
```
Unable to connect to the server: dial tcp [::1]:8080: connectex: Aucune connexion n'a pu être établie
```

### Cause
`kubectl` n'est pas configuré pour utiliser le fichier kubeconfig du cluster K3s.

### Solutions

#### ✅ Solution : Configurer KUBECONFIG

```bash
cd /c/Users/lomao/Desktop/note/orchestrator

# Vérifier que le fichier kubeconfig existe
ls -la .kube/config

# Si le fichier existe, configurer kubectl
export KUBECONFIG=$(pwd)/.kube/config

# Tester
kubectl get nodes
```

**Rendre la configuration permanente** (Git Bash) :

```bash
# Ajouter à ~/.bashrc
echo "export KUBECONFIG=/c/Users/lomao/Desktop/note/orchestrator/.kube/config" >> ~/.bashrc

# Recharger
source ~/.bashrc
```

**Si le fichier .kube/config n'existe pas** :

Le cluster n'a pas été démarré. Exécutez :

```bash
vagrant up
```

---

## ❌ Erreur : Pods en status "Pending"

### Symptômes
```bash
kubectl get pods
# Certains pods sont en status Pending depuis longtemps
```

### Diagnostic

```bash
# Voir les détails du pod
kubectl describe pod <pod-name>

# Vérifier les événements
kubectl get events --sort-by='.lastTimestamp'
```

### Causes Courantes et Solutions

#### 1. Ressources insuffisantes

**Symptôme** : `Insufficient cpu` ou `Insufficient memory`

**Solution** : Augmenter les ressources dans le Vagrantfile

```ruby
config.vm.provider "virtualbox" do |vb|
  vb.memory = 4096  # Augmenter de 2048 à 4096
  vb.cpus = 4       # Augmenter de 2 à 4
end
```

Puis :
```bash
vagrant reload --provision
```

#### 2. PVC non lié

**Symptôme** : `waiting for persistent volume to be bound`

**Solution** : Vérifier les PersistentVolumes

```bash
# Vérifier les PVC
kubectl get pvc

# Vérifier les PV
kubectl get pv

# Supprimer et recréer le pod
kubectl delete pod <pod-name>
```

#### 3. Image non trouvée

**Symptôme** : `ImagePullBackOff` ou `ErrImagePull`

**Solution** : Vérifier le nom de l'image

```bash
# Vérifier les détails
kubectl describe pod <pod-name>

# Corriger dans le manifeste et réappliquer
kubectl apply -f Manifests/...
```

---

## ❌ Erreur : Pods en status "CrashLoopBackOff"

### Diagnostic

```bash
# Voir les logs
kubectl logs <pod-name>

# Si le pod a crashé
kubectl logs <pod-name> --previous
```

### Causes Courantes

#### 1. Variable d'environnement manquante

**Solution** : Vérifier les secrets

```bash
kubectl get secrets
kubectl describe secret <secret-name>

# Recréer le secret si nécessaire
kubectl delete secret <secret-name>
kubectl apply -f Manifests/secrets.yaml
```

#### 2. Base de données non prête

**Solution** : Attendre que les bases de données démarrent

```bash
# Vérifier les bases de données
kubectl get pods | grep db

# Les bases de données doivent être en Running avant les apps
```

#### 3. Erreur dans le code de l'application

**Solution** : Vérifier les logs de l'application

```bash
kubectl logs <pod-name> -f
```

---

## ❌ Erreur : Service non accessible

### Diagnostic

```bash
# Vérifier le service
kubectl get svc <service-name>

# Vérifier les endpoints
kubectl get endpoints <service-name>

# Vérifier les labels des pods
kubectl get pods --show-labels
```

### Solution

Les labels du pod doivent correspondre au sélecteur du service.

**Vérifier la correspondance** :

```bash
# Voir le sélecteur du service
kubectl describe svc <service-name>

# Comparer avec les labels du pod
kubectl describe pod <pod-name>
```

---

## ❌ Erreur : HPA ne scale pas

### Diagnostic

```bash
# Vérifier le HPA
kubectl get hpa
kubectl describe hpa <hpa-name>

# Vérifier que metrics-server fonctionne
kubectl top pods
kubectl top nodes
```

### Solutions

#### 1. Metrics-server non prêt

Le metrics-server a besoin de 2-3 minutes pour collecter les métriques.

**Solution** : Attendre et réessayer

```bash
# Attendre 3 minutes, puis :
kubectl top pods
```

#### 2. Ressources CPU/Mémoire non définies

Les pods doivent avoir des `requests` et `limits` définis.

**Solution** : Vérifier le manifeste

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 500m
    memory: 512Mi
```

---

## 🔧 Commandes de Diagnostic Utiles

### Vérifier l'état général

```bash
# Tout voir d'un coup
kubectl get all

# Pods
kubectl get pods -o wide

# Services
kubectl get svc

# Nœuds
kubectl get nodes

# Événements récents
kubectl get events --sort-by='.lastTimestamp' | tail -20
```

### Logs et debugging

```bash
# Logs d'un pod
kubectl logs <pod-name>

# Logs en temps réel
kubectl logs -f <pod-name>

# Logs du conteneur précédent (si crashé)
kubectl logs <pod-name> --previous

# Entrer dans un pod
kubectl exec -it <pod-name> -- /bin/sh
```

### Ressources

```bash
# Utilisation CPU/Mémoire des nœuds
kubectl top nodes

# Utilisation CPU/Mémoire des pods
kubectl top pods

# Description détaillée
kubectl describe pod <pod-name>
kubectl describe node <node-name>
```

### Vagrant

```bash
# État des VMs
vagrant status

# SSH dans le master
vagrant ssh k3s-master

# Redémarrer une VM
vagrant reload k3s-master

# Détruire tout
vagrant destroy -f
```

---

## 🆘 Réinitialisation Complète

Si tout échoue, réinitialisez complètement :

```bash
cd /c/Users/lomao/Desktop/note/orchestrator

# 1. Détruire les VMs Vagrant
vagrant destroy -f

# 2. Nettoyer les fichiers
rm -rf .vagrant/ .kube/ .k3s-token

# 3. Nettoyer VirtualBox
vboxmanage list vms
vboxmanage unregistervm "k3s-master" --delete 2>/dev/null
vboxmanage unregistervm "k3s-agent" --delete 2>/dev/null

# 4. Recommencer
vagrant up

# 5. Configurer kubectl
export KUBECONFIG=$(pwd)/.kube/config

# 6. Vérifier
kubectl get nodes
```

---

## 📞 Aide Supplémentaire

Si les problèmes persistent :

1. Vérifier les logs VirtualBox : `C:\Users\<username>\VirtualBox VMs\<vm-name>\Logs\`
2. Vérifier les logs Vagrant : `vagrant up --debug`
3. Vérifier les logs K3s : `vagrant ssh k3s-master`, puis `sudo journalctl -u k3s -f`

---

**Dernière mise à jour** : 2024
**Version** : 1.0
