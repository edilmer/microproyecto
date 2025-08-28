
#!/usr/bin/env bash
# provision-haproxy.sh
# Objetivo: instalar HAProxy, habilitar la UI de stats y configurar descubrimiento vía DNS de Consul.
set -euo pipefail

apt-get update -y
apt-get install -y haproxy

# Habilita HAProxy en sistemas donde /etc/default/haproxy controla el arranque
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/haproxy || true

# Página personalizada para errores 503 (cuando no hay backends disponibles)
cat >/etc/haproxy/errors/503custom.http <<'EOF'
HTTP/1.0 503 Service Unavailable
Cache-Control: no-cache
Connection: close
Content-Type: text/html

<html><body><h1>Servicio temporalmente no disponible</h1>
<p>Por el momento no hay servidores disponibles para atender su solicitud.</p>
</body></html>
EOF

# Configuración principal de HAProxy:
# - 'resolvers consul' usa el DNS de Consul (127.0.0.1:8600) para descubrir 'web.service.consul'
# - 'server-template' crea dinámicamente hasta 10 servidores a partir de registros SRV
# - 'listen stats' habilita el panel de estadísticas
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

# UI de estadísticas (usuario: admin / clave: admin)
listen stats
    bind *:8404
    stats enable
    stats uri /haproxy?stats
    stats refresh 5s
    stats auth admin:admin

# Resolver DNS que consulta a Consul (puerto 8600)
resolvers consul
    parse-resolv-conf
    hold valid 10s
    nameserver consul 127.0.0.1:8600

# Entrada HTTP del balanceador
frontend http_front
    bind *:80
    default_backend web_back

# Backend con descubrimiento dinámico de las instancias 'web' registradas en Consul
backend web_back
    balance roundrobin
    server-template web 10 web.service.consul resolvers consul resolve-prefer ipv4 resolve-opts allow-dup-ip init-addr none
EOF

# Habilita y (re)inicia HAProxy
systemctl enable haproxy
systemctl restart haproxy
