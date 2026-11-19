#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 02: Instalación y Configuración del Servidor NFS
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [02] Desplegando Servidor NFS (Compartición Linux)"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../configs"

echo "[*] Instalando servidor NFS Kernel..."
apt install -y nfs-kernel-server

echo "[*] Creando estructura de directorios compartidos para TechMarket..."
mkdir -p /srv/nfs/techmarket/general
mkdir -p /srv/nfs/techmarket/catalogos
mkdir -p /srv/nfs/techmarket/backups

# Permisos para acceso transparente desde clientes Linux
chown -R nobody:nogroup /srv/nfs/techmarket
chmod -R 777 /srv/nfs/techmarket

echo "Archivos compartidos vía NFS para la sede Armenia - TechMarket" > /srv/nfs/techmarket/general/bienvenida.txt
echo "Catálogo mayorista de especificaciones de hardware" > /srv/nfs/techmarket/catalogos/especificaciones_tecnicas.txt

echo "[*] Configurando puntos de exportación en /etc/exports..."
if [[ -f "${CONFIG_DIR}/exports" ]]; then
    cp "${CONFIG_DIR}/exports" /etc/exports
else
    cat << 'EOF' > /etc/exports
/srv/nfs/techmarket/general     *(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/techmarket/catalogos   *(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/techmarket/backups     *(rw,sync,no_subtree_check,no_root_squash)
EOF
fi

echo "[*] Aplicando nuevas tablas de exportación..."
exportfs -ra

echo "[*] Reiniciando y habilitando nfs-kernel-server..."
systemctl restart nfs-kernel-server
systemctl enable nfs-kernel-server

echo "[✓] Verificación de exportaciones activas en el servidor:"
exportfs -v

echo "[✓] Servidor NFS operativo. En clientes Linux montar con:"
echo "    sudo mount -t nfs <IP_SERVIDOR>:/srv/nfs/techmarket/general /mnt/techmarket"
