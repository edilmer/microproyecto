
#!/usr/bin/env bash 
# provision-nodeapp.sh
# Objetivo: desplegar una app Node.js mínima y correr 3 réplicas vía systemd.
set -euo pipefail

# Código de la app: expone / y /health para checks de Consul
cat >/opt/nodeapp/server.js <<'EOF'
const http = require('http');
const os = require('os');
const PORT = process.env.PORT || process.argv[2] || 3000;
const server = http.createServer((req, res) => {
  if (req.url === '/health') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({status: 'ok'}));
    return;
  } 
  res.writeHead(200, {'Content-Type': 'text/plain'});
  res.end(`Hello from ${os.hostname()} on port ${PORT}\n`);
});
server.listen(PORT, () => console.log(`Node app listening on port ${PORT}`));
EOF

# Unidad systemd con plantilla (@) para lanzar múltiples instancias por puerto
cat >/etc/systemd/system/nodeapp@.service <<'EOF'
[Unit]
Description=Node App instance on port %i
After=network.target
 
[Service]
ExecStart=/usr/bin/node /opt/nodeapp/server.js %i
Restart=always
Environment=NODE_ENV=production
User=root
WorkingDirectory=/opt/nodeapp

[Install]
WantedBy=multi-user.target
EOF

# Habilita y arranca 3 réplicas (3000, 3001, 3002)
systemctl daemon-reload
for p in 3000 3001 3002; do
  systemctl enable nodeapp@${p}
  systemctl restart nodeapp@${p}
done

# Registra cada réplica como un servicio en Consul con healthcheck HTTP
mkdir -p /etc/consul.d
for p in 3000 3001 3002; do
  cat >/etc/consul.d/web-${p}.json <<EOF
{
  "service": {
    "id": "web-${p}",
    "name": "web",
    "port": ${p},
    "tags": ["node"],
    "check": {
      "http": "http://127.0.0.1:${p}/health",
      "interval": "10s",
      "timeout": "2s"
    }
  }
}
EOF
done

# Recarga el agente Consul para leer los nuevos servicios registrados
systemctl restart consul || true
