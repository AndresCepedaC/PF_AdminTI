#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 06: Instalación de Docker y Plataforma PaaS Dokploy
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [06] Desplegando Dokploy PaaS y Docker Engine"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"

echo "[*] Verificando e instalando Docker Engine si no está presente..."
if ! command -v docker &>/dev/null; then
    echo "[*] Descargando e instalando Docker oficial..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm -f get-docker.sh
    systemctl enable --now docker
    usermod -aG docker "${REAL_USER}" || true
else
    echo "[✓] Docker Engine ya se encuentra instalado."
fi

# Instalar Docker Compose Plugin si falta
if ! docker compose version &>/dev/null; then
    apt install -y docker-compose-plugin
fi

echo "[*] Instalando Dokploy (PaaS con Traefik integrado)..."
curl -sSL https://dokploy.com/install.sh | sh

echo "[*] Verificando contenedores de Dokploy en ejecución..."
docker ps --filter "name=dokploy"

echo "=========================================================="
echo "[✓] Dokploy instalado exitosamente."
echo "    Acceso al Panel Web: http://<IP_DE_ESTA_VM>:3000"
echo "    Crea la cuenta administrativa inicial en el primer ingreso."
echo "=========================================================="
