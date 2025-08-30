#!/usr/bin/env bash
# provision-haproxy.sh
set -euo pipefail

apt-get update -y
apt-get install -y haproxy rsyslog

# Asegura que haproxy arranque en distros que usan /etc/default/haproxy
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/haproxy || true

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
 
systemctl enable rsyslog
systemctl restart rsyslog
systemctl enable haproxy
systemctl restart haproxy

