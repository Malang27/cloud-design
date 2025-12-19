# Guide : Supprimer les VMs Vagrant

## Supprimer les VMs du projet actuel

### Option 1 : Arrêter et détruire (recommandé)
```bash
cd /c/Users/lomao/Desktop/note/orchestrator

# Arrêter les VMs
vagrant halt

# Détruire les VMs (suppression complète)
vagrant destroy -f
```

### Option 2 : Supprimer une VM spécifique
```bash
# Détruire uniquement le master
vagrant destroy k3s-master -f

# Détruire uniquement l'agent
vagrant destroy k3s-agent -f
```

### Option 3 : Supprimer tout (VMs + fichiers générés)
```bash
# Détruire les VMs
vagrant destroy -f

# Supprimer les fichiers générés
rm -rf .vagrant/
rm -rf .kube/
rm -f .k3s-token
```

## Supprimer TOUTES les VMs Vagrant du système

### Windows (Git Bash / PowerShell)
```bash
# Lister toutes les VMs Vagrant
vagrant global-status

# Supprimer une VM par son ID
vagrant destroy <ID> -f

# Nettoyer les entrées invalides
vagrant global-status --prune
```

## Supprimer les VMs directement depuis VirtualBox

```bash
# Lister toutes les VMs VirtualBox
vboxmanage list vms

# Arrêter une VM
vboxmanage controlvm "k3s-master" poweroff

# Supprimer une VM
vboxmanage unregistervm "k3s-master" --delete
vboxmanage unregistervm "k3s-agent" --delete
```

## Libérer l'espace disque

```bash
# Supprimer les images Vagrant en cache
vagrant box list
vagrant box remove ubuntu/focal64
```

## Vérification après suppression

```bash
# Vérifier qu'il n'y a plus de VMs Vagrant
vagrant global-status

# Vérifier qu'il n'y a plus de VMs VirtualBox
vboxmanage list vms
```
