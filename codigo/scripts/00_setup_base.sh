#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 00: Configuración Base del Sistema Ubuntu Server
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [00] Inicializando Servidor Base TechMarket (Ubuntu)"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

# Configurar Hostname Corporativo
HOSTNAME_TARGET="srv-infra.techmarket.local"
echo "[*] Estableciendo hostname: ${HOSTNAME_TARGET}..."
hostnamectl set-hostname "${HOSTNAME_TARGET}"

# Asegurar resolución en /etc/hosts
if ! grep -q "srv-infra.techmarket.local" /etc/hosts; then
    echo "127.0.0.1 srv-infra.techmarket.local srv-infra" >> /etc/hosts
fi

echo "[*] Actualizando lista de paquetes del sistema..."
apt update -y && apt upgrade -y

echo "[*] Instalando utilidades esenciales de administración y red..."
apt install -y curl wget git vim net-tools ufw htop rsync unzip ca-certificates gnupg lsb-release

echo "[✓] Configuración base completada exitosamente."
