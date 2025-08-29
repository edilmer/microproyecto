# Microproyecto
para iniciar e instalar las VM 
Comandos:
vagrant ssh balanceador
vagrant ssh web1
vagrant ssh web2
artillery run artillery.yml
VMs: balanceador (192.168.56.10), web1 (192.168.56.11), web2 (192.168.56.12)
Puertos: 8080 (HTTP), 8404 (HAProxy stats), 8500 (Consul UI)

