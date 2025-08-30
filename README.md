<<<<<<< HEAD
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

=======
# Microproyecto
## Como ejecutar el programa:
### 1. **Prerequisitos**
Necesitas tener instalado:
- **Vagrant**
- **VirtualBox**
- **Artillery** (para pruebas de carga)

### 2. **Pasos:**

# 1. Primero levanta el balanceador
vagrant up balanceador

# 2. Luego levanta los servidores web
vagrant up web1 web2

# 3. Verificar que todo este funcionando
# - Aplicacion: http://localhost:8080
# - HAProxy Stats: http://localhost:8404  
# - Consul UI: http://localhost:8500

# 4. Ejecuta las pruebas de carga
artillery run artillery.yml
### 3. **URLs para verificar:**
- **http://localhost:8080** - Aplicación balanceada
- **http://localhost:8404/haproxy?stats** - Estadísticas de HAProxy
- **http://localhost:8500** - Interfaz web de Consul
>>>>>>> d63055f6efd28bc41c8875beeee186c6af9cbd5d

 