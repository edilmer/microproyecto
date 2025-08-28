#!/bin/bash
echo "configurando el resolv.conf con cat"
sudo tee /etc/resolv.conf > /dev/null <<EOF
nameserver 8.8.8.8
EOF
echo "instalando un servidor vsftpd"
sudo apt-get install -y vsftpd
echo "Modificando vsftpd.conf con sed"
sudo sed -i 's/#write_enable=YES/write_enable=YES/g' /etc/vsftpd.conf
echo "configurando ip forwarding con echo"
echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "aplicando configuracion de sysctl"
sudo sysctl -p
echo "reiniciando vsftpd"
sudo systemctl restart vsftpd
sudo systemctl enable vsftpd
