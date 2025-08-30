# Microproyecto final - HAProxy + Consul + Node.js

Infraestructura de balanceador de carga con descubrimiento de servicios usando:
- **HAProxy**: Balanceador de carga con health checks
- **Consul**: Descubrimiento de servicios y monitoreo
- **Node.js**: Aplicaciones web distribuidas (3 instancias por VM)

## Arquitectura

- **balanceador** (192.168.56.10): HAProxy + Consul Server
- **web1** (192.168.56.11): Node.js (puertos 3000, 3001, 3002) + Consul Agent  
- **web2** (192.168.56.12): Node.js (puertos 3000, 3001, 3002) + Consul Agent

## Cómo usar

### Prerequisitos
- Vagrant
- VirtualBox 
- Artillery (opcional, para pruebas de carga)

### Comandos de ejecución
```bash
# 1. Levantar el balanceador primero
vagrant up balanceador

# 2. Levantar los servidores web
vagrant up web1 web2

# 3. Verificar funcionamiento
curl http://localhost:8080

# 4. Ejecutar pruebas de carga
artillery run artillery.yml
```

## URLs de acceso

- **Aplicación balanceada**: http://localhost:8080
- **HAProxy Stats**: http://localhost:8404/haproxy?stats (admin/admin)
- **Consul UI**: http://localhost:8500


