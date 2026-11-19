#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 01: Instalación y Configuración del Servidor NTP
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [01] Desplegando Servidor de Tiempo NTP (Stratum 2)"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../configs"

echo "[*] Instalando paquete NTP..."
apt install -y ntp

echo "[*] Respaldando configuración predeterminada..."
if [[ -f /etc/ntp.conf && ! -f /etc/ntp.conf.bak ]]; then
    cp /etc/ntp.conf /etc/ntp.conf.bak
fi

if [[ -f "${CONFIG_DIR}/ntp.conf" ]]; then
    echo "[*] Aplicando configuración personalizada de TechMarket..."
    cp "${CONFIG_DIR}/ntp.conf" /etc/ntp.conf
else
    echo "[*] Escribiendo configuración optimizada en /etc/ntp.conf..."
    cat << 'EOF' > /etc/ntp.conf
driftfile /var/lib/ntp/ntp.drift
server 0.south-america.pool.ntp.org iburst
server 1.south-america.pool.ntp.org iburst
server pool.ntp.org iburst

restrict -4 default kod notrap nomodify nopeer noquery limited
restrict -6 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap
restrict 10.0.0.0 mask 255.0.0.0 nomodify notrap
EOF
fi

echo "[*] Reiniciando y habilitando servicio ntp..."
systemctl restart ntp
systemctl enable ntp

echo "[*] Esperando 3 segundos para estabilización..."
sleep 3

echo "[✓] Estado de sincronización NTP:"
ntpq -p || true

echo "[✓] Servicio NTP operativo y listo para recibir clientes."
