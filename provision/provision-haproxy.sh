
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
<p>Por el momento no hay servidores.</p>
</body></html>
EOF

# Configuración principal de HAProxy:
# - Usa servidores estáticos con health checks para garantizar estabilidad
# - Los servidores se definen explícitamente para cada instancia Node.js
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

# Entrada HTTP del balanceador
frontend http_front
    bind *:80
    default_backend web_back

# Backend dinámico usando SRV de Consul para 'web.service.consul'
backend web_back
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    # hasta 10 instancias dinámicas; usa lo que devuelva Consul
    server-template web 10 web.service.consul resolvers consul \
      resolve-prefer ipv4 resolve-opts allow-dup-ip init-addr last
EOF

# Habilita y (re)inicia HAProxy
systemctl enable haproxy
systemctl restart haproxy
