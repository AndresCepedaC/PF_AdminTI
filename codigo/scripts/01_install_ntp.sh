#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 01: Instalación y Configuración del Servidor NTP / Chrony
# Compatible con Ubuntu 20.04, 22.04, 24.04 y superiores
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [01] Desplegando Servidor de Tiempo NTP (Stratum 2)"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

echo "[*] Instalando servicio de tiempo (chrony / ntpsec)..."
if apt-cache show chrony &>/dev/null; then
    apt install -y chrony
    NTP_ENGINE="chrony"
elif apt-cache show ntpsec &>/dev/null; then
    apt install -y ntpsec
    NTP_ENGINE="ntpsec"
else
    apt install -y ntp || true
    NTP_ENGINE="ntp"
fi

echo "[*] Motor de tiempo detectado: ${NTP_ENGINE}"

if [[ "${NTP_ENGINE}" == "chrony" ]]; then
    CHRONY_CONF="/etc/chrony/chrony.conf"
    if [[ -f "${CHRONY_CONF}" && ! -f "${CHRONY_CONF}.bak" ]]; then
        cp "${CHRONY_CONF}" "${CHRONY_CONF}.bak"
    fi

    cat << 'EOF' > "${CHRONY_CONF}"
# Configuración Chrony NTP para TECHMARKET S.A.S.
server 0.south-america.pool.ntp.org iburst
server 1.south-america.pool.ntp.org iburst
server pool.ntp.org iburst

driftfile /var/lib/chrony/chrony.drift
logdir /var/log/chrony
maxupdateskew 100.0
rtcsync
makestep 1 3

# Permitir a clientes de la red local sincronizar con este servidor
allow 192.168.0.0/16
allow 10.0.0.0/8
allow 127.0.0.1
EOF

    systemctl restart chrony
    systemctl enable chrony
    sleep 2
    echo "[✓] Estado de sincronización Chrony (NTP):"
    chronyc tracking || true
    chronyc sources -v || true

else
    NTP_CONF="/etc/ntp.conf"
    if [[ -f /etc/ntpsec/ntp.conf ]]; then
        NTP_CONF="/etc/ntpsec/ntp.conf"
    fi

    cat << 'EOF' > "${NTP_CONF}"
driftfile /var/lib/ntp/ntp.drift
server 0.south-america.pool.ntp.org iburst
server 1.south-america.pool.ntp.org iburst
server pool.ntp.org iburst

restrict -4 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict ::1
restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap
restrict 10.0.0.0 mask 255.0.0.0 nomodify notrap
EOF

    systemctl restart "${NTP_ENGINE}" || systemctl restart ntp || true
    systemctl enable "${NTP_ENGINE}" || systemctl enable ntp || true
    sleep 2
    echo "[✓] Estado de sincronización NTP:"
    ntpq -p || true
fi

echo "[✓] Servidor NTP operativo y sirviendo tiempo a la red local de TechMarket."
