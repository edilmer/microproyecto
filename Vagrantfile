
# -*- mode: ruby -*-
# vi: set ft=ruby :
# Vagrantfile comentado para un entorno con:
#   - balanceador: HAProxy + Consul Server (descubrimiento de servicios) 
#   - web1 y web2: Node.js (3 réplicas) + Consul Agent (registro/healthchecks)
# Se usa un único box para coherencia de librerías/paquetes: Ubuntu 22.04 (bento).
Vagrant.configure("2") do |config|
  # Box base para todas las VMs (Ubuntu 22.04 LTS - Jammy)
  config.vm.box = "bento/ubuntu-22.04"

  # VM: balanceador (HAProxy + Consul Server)================================================================================
  config.vm.define "balanceador" do |lb|
    lb.vm.hostname = "balanceador"                 # nombre de host dentro de la VM
    lb.vm.network "private_network", ip: "192.168.56.10"   # IP privada para que las webs se conecten al Consul server

    # Publicación de puertos hacia el host para pruebas locales:
    lb.vm.network "forwarded_port", guest: 80,   host: 8080, auto_correct: true   # tráfico HTTP balanceado por HAProxy
    lb.vm.network "forwarded_port", guest: 8404, host: 8404, auto_correct: true   # interfaz de estadísticas de HAProxy
    lb.vm.network "forwarded_port", guest: 8500, host: 8500, auto_correct: true   # interfaz web de Consul

    # Provisioners (scripts de shell que configuran la VM automáticamente)
    lb.vm.provision "shell", path: "provision/provision-common.sh"          # utilidades base + Node.js
    lb.vm.provision "shell", path: "provision/provision-consul-server.sh"   # instala/activa Consul en modo servidor con UI
    lb.vm.provision "shell", path: "provision/provision-haproxy.sh"         # instala/activa HAProxy + stats + error 503
  end

  # VM: web1 (NodeJS + Consul Agent)==================================================================================================
  config.vm.define "web1" do |web|
    web.vm.hostname = "web1"
    web.vm.boot_timeout = 600
    web.vm.network "private_network", ip: "192.168.56.11"                   # IP privada de la web1

    # Provisioners para Node.js + registro en Consul
    web.vm.provision "shell", path: "provision/provision-common.sh"                           # utilidades + Node.js
    web.vm.provision "shell", path: "provision/provision-consul-agent.sh", args: ["192.168.56.10"]  # agente Consul uniéndose al server (balanceador)
    web.vm.provision "shell", path: "provision/provision-nodeapp.sh"                           # app Node y 3 réplicas via systemd + checks
  end

  # VM: web2 (NodeJS + Consul Agent)=========================================================================================================
  config.vm.define "web2" do |web|
    web.vm.hostname = "web2"
    web.vm.network "private_network", ip: "192.168.56.12"

    web.vm.provision "shell", path: "provision/provision-common.sh"
    web.vm.provision "shell", path: "provision/provision-consul-agent.sh", args: ["192.168.56.10"]
    web.vm.provision "shell", path: "provision/provision-nodeapp.sh"
  end
end
