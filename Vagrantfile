# -*- mode: ruby -*-
# vi: set ft=ruby :

# Configuration K3s minimaliste pour Windows
# Si le Vagrantfile principal ne fonctionne pas, copiez ce fichier sur Vagrantfile
# cp Vagrantfile.minimal Vagrantfile

K3S_VERSION = "v1.28.5+k3s1"
MASTER_IP = "192.168.56.110"

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-20.04"
  config.vm.box_check_update = false

  # Configuration SSH avec timeouts plus longs
  config.vm.boot_timeout = 900  # 15 minutes
  config.ssh.forward_agent = false
  config.ssh.insert_key = true

  # Master Node seulement
  config.vm.define "k3s-master", primary: true do |master|
    master.vm.hostname = "k3s-master"
    master.vm.network "private_network", ip: MASTER_IP

    master.vm.provider "virtualbox" do |vb|
      vb.name = "k3s-master"
      vb.memory = 3072  # Augmenter à 3GB
      vb.cpus = 2
      vb.gui = true  # Mettre à true pour voir la console
      vb.linked_clone = true

      # Désactiver les fonctionnalités qui peuvent causer des problèmes
      vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
      vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
      vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
      vb.customize ["modifyvm", :id, "--uartmode1", "file", File::NULL]
      vb.customize ["modifyvm", :id, "--audio", "none"]
      vb.customize ["modifyvm", :id, "--usb", "off"]
    end

    master.vm.provision "shell", inline: <<-SHELL
      set -e

      echo "==> Configuration du système..."
      export DEBIAN_FRONTEND=noninteractive

      # Désactiver les mises à jour automatiques
      systemctl stop apt-daily.timer || true
      systemctl disable apt-daily.timer || true
      systemctl stop apt-daily-upgrade.timer || true
      systemctl disable apt-daily-upgrade.timer || true

      # Attendre que apt soit disponible
      while fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1 ; do
        echo "Waiting for apt lock..."
        sleep 5
      done

      echo "==> Installation des paquets..."
      apt-get update -qq
      apt-get install -y curl wget net-tools || true

      echo "==> Désactivation du swap..."
      swapoff -a
      sed -i '/swap/d' /etc/fstab

      echo "==> Installation de K3s master #{K3S_VERSION}..."
      curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION=#{K3S_VERSION} sh -s - server \
        --bind-address=#{MASTER_IP} \
        --advertise-address=#{MASTER_IP} \
        --node-ip=#{MASTER_IP} \
        --flannel-iface=eth1 \
        --write-kubeconfig-mode=644 \
        --disable=traefik \
        --disable=servicelb

      echo "==> Attente du démarrage de K3s..."
      for i in {1..30}; do
        if kubectl get nodes 2>/dev/null; then
          break
        fi
        echo "Waiting... ($i/30)"
        sleep 10
      done

      echo "==> Copie du kubeconfig..."
      mkdir -p /vagrant/.kube
      cp /etc/rancher/k3s/k3s.yaml /vagrant/.kube/config
      sed -i "s/127.0.0.1/#{MASTER_IP}/g" /vagrant/.kube/config
      chmod 644 /vagrant/.kube/config

      echo "==> K3s master prêt!"
      kubectl get nodes
    SHELL
  end

  config.vm.post_up_message = <<-MESSAGE
    ╔═══════════════════════════════════════════════════════════════╗
    ║           K3s Master Déployé (Configuration Minimale)        ║
    ╚═══════════════════════════════════════════════════════════════╝

    Master Node: #{MASTER_IP} (k3s-master)

    Accès au cluster:
      export KUBECONFIG=$(pwd)/.kube/config
      kubectl get nodes

    SSH au master:
      vagrant ssh k3s-master
  MESSAGE
end
