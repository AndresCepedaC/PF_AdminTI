#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 03-B: Configuración de Cliente NIS en Estación Linux
# ==============================================================================
set -euo pipefail

if [[ $# -lt 1 ]]; then
    echo "Uso: sudo $0 <IP_DEL_SERVIDOR_NIS>"
    echo "Ejemplo: sudo $0 192.168.1.100"
    exit 1
fi

NIS_SERVER_IP="$1"
NIS_DOMAIN="techmarket.local"

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

echo "[*] Configurando cliente NIS apuntando a ${NIS_SERVER_IP}..."
nisdomainname "${NIS_DOMAIN}"
echo "${NIS_DOMAIN}" > /etc/defaultdomain

echo "[*] Instalando paquetes NIS y rpcbind..."
DEBIAN_FRONTEND=noninteractive apt install -y rpcbind nis

echo "[*] Configurando /etc/yp.conf..."
echo "domain ${NIS_DOMAIN} server ${NIS_SERVER_IP}" > /etc/yp.conf

echo "[*] Configurando /etc/nsswitch.conf para soporte NIS..."
sed -i 's/^passwd:.*/passwd:         files nis/' /etc/nsswitch.conf
sed -i 's/^group:.*/group:          files nis/' /etc/nsswitch.conf
sed -i 's/^shadow:.*/shadow:         files nis/' /etc/nsswitch.conf
sed -i 's/^hosts:.*/hosts:          files dns nis/' /etc/nsswitch.conf

echo "[*] Reiniciando rpcbind y ypbind..."
systemctl restart rpcbind
systemctl restart ypbind
systemctl enable rpcbind ypbind

echo "[✓] Verificando enlace con el servidor NIS..."
ypwhich || true
ypcat passwd || true

echo "[✓] Cliente NIS configurado exitosamente."
