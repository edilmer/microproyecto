
#!/usr/bin/env bash
# provision-consul-agent.sh
# Objetivo: instalar Consul (1.16.2) en modo agente y unirlo al servidor indicado.
set -euo pipefail
SERVER_IP="${1:-192.168.56.10}"       # IP del servidor Consul (balanceador)
CONSUL_VERSION="1.16.2"

# Recursos de sistema y carpetas
useradd --system --home /etc/consul.d --shell /bin/false consul || true
mkdir -p /opt/consul /etc/consul.d
chown -R consul:consul /opt/consul /etc/consul.d

# Instala Consul si no existe
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

echo "Configurando Consul agent con IP: $IP, conectando a servidor: $SERVER_IP"

# Configuración en modo agente (no servidor) con auto-join al server
cat >/etc/consul.d/agent.hcl <<EOF
server = false
datacenter = "dc1"
data_dir = "/opt/consul" 
bind_addr = "${IP}"
client_addr = "0.0.0.0"
retry_join = ["${SERVER_IP}"]
EOF

# Servicio systemd para el agente
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
  
systemctl daemon-reload
systemctl enable consul
systemctl restart consul
