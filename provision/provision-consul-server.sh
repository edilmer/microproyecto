
#!/usr/bin/env bash
# provision-consul-server.sh
# Objetivo: instalar Consul (1.16.2), configurar en modo servidor con UI y servicio systemd.
set -euo pipefail

CONSUL_VERSION="1.16.2"

# Crea usuario/grupos de sistema y carpetas de datos/config
useradd --system --home /etc/consul.d --shell /bin/false consul || true
mkdir -p /opt/consul /etc/consul.d
chown -R consul:consul /opt/consul /etc/consul.d 

# Descarga e instala el binario de Consul si no existe
if ! command -v consul >/dev/null 2>&1; then
  curl -Lo /tmp/consul.zip https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_amd64.zip
  unzip -o /tmp/consul.zip -d /usr/local/bin
  chmod +x /usr/local/bin/consul
fi

# Detecta IP privada de la VM para bind_addr (busca en el rango 192.168.56.x)
# Si no encuentra una IP privada, usa la primera IP disponible como fallback
IP=$(ip route get 1 | grep -oP 'src \K\S+' 2>/dev/null || hostname -I | awk '{print $2}' 2>/dev/null || hostname -I | awk '{print $1}')

# Si la IP detectada está en el rango NAT (10.0.2.x), busca la interfaz privada
if [[ "$IP" =~ ^10\.0\.2\. ]]; then
    IP=$(ip addr show | grep -oP '192\.168\.56\.\d+' | head -1 || echo "$IP")
fi

echo "Configurando Consul server con IP: $IP" 

# Archivo de configuración principal del servidor Consul
cat >/etc/consul.d/server.hcl <<EOF
server = true                         # modo servidor
bootstrap_expect = 1                  # tamaño mínimo del quórum (1 server)
datacenter = "dc1"                    # nombre del datacenter lógico
data_dir = "/opt/consul"              # carpeta de datos
bind_addr = "${IP}"                   # interfaz a la que se enlaza
client_addr = "0.0.0.0"               # expone API/UI en todas las interfaces
ui_config { enabled = true }          # habilita la interfaz web
retry_join = ["${IP}"]                # unirse a sí mismo (cluster de 1 server)
EOF

# Unidad systemd para ejecutar el agente Consul como servicio
cat >/etc/systemd/system/consul.service <<'EOF'
[Unit]
Description=Consul Agent
Wants=network-online.target
After=network-online.target

[Service]
User=consul
Group=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/etc/consul.d
ExecReload=/bin/kill --signal HUP $MAINPID
KillMode=process
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Habilita y arranca Consul
systemctl daemon-reload
systemctl enable consul
systemctl restart consul
