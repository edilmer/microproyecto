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
- **http://localhost:8404** - Estadísticas de HAProxy
- **http://localhost:8500** - Interfaz web de Consul

