
#!/usr/bin/env bash
# provision-common.sh
# Objetivo: instalar utilidades base y Node.js 18.x desde NodeSource.
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

apt-get update -y                                  # actualiza índices de paquetes
apt-get install -y curl unzip jq apt-transport-https ca-certificates gnupg lsb-release software-properties-common
                                                   # utilidades comunes necesarias por otros scripts

# Instala Node.js 18.x (LTS) usando el repositorio oficial de NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# Prepara el directorio de la app Node y cede propiedad al usuario vagrant
mkdir -p /opt/nodeapp
chown -R vagrant:vagrant /opt/nodeapp
