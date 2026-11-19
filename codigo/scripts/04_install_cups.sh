#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 04: Servidor de Impresión CUPS (Acceso Web e Impresora Compartida)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [04] Desplegando Servidor de Impresión CUPS (Puerto 631)"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

REAL_USER="${SUDO_USER:-$USER}"

echo "[*] Instalando CUPS y módulo de impresora virtual PDF..."
apt install -y cups cups-client printer-driver-cups-pdf

echo "[*] Agregando usuario '${REAL_USER}' al grupo lpadmin..."
usermod -aG lpadmin "${REAL_USER}" || true

echo "[*] Iniciando y asegurando el servicio CUPS..."
systemctl start cups cups.socket
systemctl enable cups cups.socket
sleep 2

echo "[*] Configurando CUPS para acceso remoto en el puerto 631..."
cupsctl --remote-admin --remote-any --share-printers || true
systemctl restart cups
sleep 2

echo "[*] Creando cola de impresión virtual para logística: 'TechMarket_Guias_Despacho'..."
lpadmin -p "TechMarket_Guias_Despacho" \
        -E \
        -v "cups-pdf:/" \
        -D "Impresora de Guías y Facturación TechMarket Armenia" \
        -L "Bodega Principal - Muelle de Despachos" \
        -o printer-is-shared=true 2>/dev/null || true

echo "[*] Creando cola de impresión para facturación corporativa..."
lpadmin -p "TechMarket_Facturacion_DEX" \
        -E \
        -v "file:///dev/null" \
        -D "Cola Raw para Impresión de Manifiestos Aduaneros DIAN" \
        -L "Oficina Administrativa" \
        -o printer-is-shared=true 2>/dev/null || true

cupsenable TechMarket_Guias_Despacho 2>/dev/null || true
cupsaccept TechMarket_Guias_Despacho 2>/dev/null || true

systemctl restart cups
systemctl enable cups

echo "[✓] Estado de las impresoras configuradas:"
lpstat -p -d || true

echo "[✓] Servidor CUPS accesible vía navegador web en:"
echo "    http://<IP_SERVIDOR>:631 o https://<IP_SERVIDOR>:631"
