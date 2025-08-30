#!/usr/bin/env bash
# provision-haproxy.sh - VERSIÓN MEJORADA
set -euo pipefail

apt-get update -y
apt-get install -y haproxy rsyslog

# Asegura que haproxy arranque en distros que usan /etc/default/haproxy
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/haproxy || true

# Crear directorio de errores si no existe
mkdir -p /etc/haproxy/errors

# Página de error 503
cat >/etc/haproxy/errors/503custom.http <<'EOF'
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html><body><h1>Servicio temporalmente no disponible</h1>
<p>Por el momento no hay servidores.</p>
</body></html>
EOF

# Configurar rsyslog para HAProxy (para que /dev/log funcione)
cat >/etc/rsyslog.d/49-haproxy.conf <<'EOF'
# Habilita UDP
$ModLoad imudp
$UDPServerAddress 127.0.0.1
$UDPServerRun 514

# Logs de HAProxy
local0.* -/var/log/haproxy/haproxy.log
local1.* -/var/log/haproxy/haproxy-notice.log

# No reenviar estos logs
& ~
EOF

# Crear directorios de log y permisos
mkdir -p /var/log/haproxy
touch /var/log/haproxy/haproxy.log
touch /var/log/haproxy/haproxy-notice.log
chown -R syslog:syslog /var/log/haproxy

# Config principal (con SRV de Consul)
cat >/etc/haproxy/haproxy.cfg <<'EOF'
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon
    maxconn 4096

defaults
    log     global
    mode    http
    option  httplog
    option  dontlognull
    timeout connect 5s
    timeout client  50s
    timeout server  50s
    errorfile 503 /etc/haproxy/errors/503custom.http

# Resolvedor DNS apuntando a Consul
resolvers consul
    nameserver consul 127.0.0.1:8600
    accepted_payload_size 8192
    resolve_retries 3
    timeout resolve 1s
    timeout retry   1s
    hold valid 10s

# UI de estadísticas (usuario: admin / clave: admin)
listen stats
    bind *:8404
    stats enable
    stats uri /haproxy?stats
    stats refresh 5s
    stats auth admin:admin

# Entrada HTTP
frontend http_front
    bind *:80
    default_backend web_back

# Backend dinámico usando SRV de Consul: _web._tcp.service.consul
backend web_back
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    default-server check inter 3s fall 2 rise 2
    # hasta 10 instancias dinámicas descubiertas por SRV
    server-template web 10 _web._tcp.service.consul resolvers consul \
        resolve-prefer ipv4 resolve-opts allow-dup-ip init-addr last,libc,none
EOF

# Validar configuración antes de proceder
if ! haproxy -c -f /etc/haproxy/haproxy.cfg; then
    echo "ERROR: Configuración de HAProxy inválida"
    exit 1
fi

systemctl enable rsyslog
systemctl restart rsyslog

# Esperar a que Consul esté disponible (si es que se ejecuta después)
echo "Esperando a que Consul esté disponible..."
for i in {1..30}; do
    if dig @127.0.0.1 -p 8600 web.service.consul >/dev/null 2>&1; then
        echo "Consul DNS disponible"
        break
    fi
    sleep 1
done

systemctl enable haproxy
systemctl restart haproxy

echo "HAProxy configurado con discovery dinámico via Consul SRV records"

