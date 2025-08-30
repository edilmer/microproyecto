#!/usr/bin/env bash
# provision-common.sh
# Objetivo: instalar utilidades base y Node.js 18.x desde NodeSource.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Función de logging
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

log "Iniciando aprovisionamiento común..."

# Actualizar índices de paquetes con reintentos
for i in {1..3}; do
    log "Intento $i: Actualizando índices de paquetes..."
    if apt-get update -y; then
        break
    fi
    sleep 5
done

# Instalar utilidades base
log "Instalando utilidades base..."
apt-get install -y \
    curl \
    unzip \
    jq \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    htop \
    net-tools \
    dnsutils

# Verificar si Node.js ya está instalado
if command -v node >/dev/null 2>&1; then
    log "Node.js ya está instalado: $(node --version)"
else
    log "Instalando Node.js 18.x..."
    # Instalar Node.js 18.x (LTS) usando el repositorio oficial de NodeSource
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    apt-get install -y nodejs
fi

log "Verificando instalación de Node.js..."
node --version
npm --version

# Preparar directorio de la app Node y asignar propiedad al usuario vagrant
log "Preparando directorio de aplicación Node.js..."
mkdir -p /opt/nodeapp
chown -R vagrant:vagrant /opt/nodeapp
chmod 755 /opt/nodeapp

# Configurar logrotate para logs de aplicación
log "Configurando logrotate..."
cat > /etc/logrotate.d/nodeapp << 'EOF'
/var/log/nodeapp/*.log {
    daily
    missingok
    rotate 7
    compress
    notifempty
    create 644 root root
}
EOF

log "Aprovisionamiento común completado exitosamente"
