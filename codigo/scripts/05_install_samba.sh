#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 05: Servidor de Archivos Samba SMB/CIFS (Windows / macOS)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [05] Desplegando Servidor Samba SMB/CIFS"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${SCRIPT_DIR}/../configs"
REAL_USER="${SUDO_USER:-$USER}"

echo "[*] Instalando Samba y cliente smbclient..."
apt install -y samba smbclient

echo "[*] Creando grupos departamentales de TechMarket..."
groupadd -f admin
groupadd -f ventas
groupadd -f compras
groupadd -f bodega

echo "[*] Creando directorios estructurados en /srv/samba/techmarket..."
mkdir -p /srv/samba/techmarket/general
mkdir -p /srv/samba/techmarket/ventas
mkdir -p /srv/samba/techmarket/importaciones
mkdir -p /srv/samba/techmarket/despachos

echo "[*] Creando usuarios operativos para demostración..."
create_tech_user() {
    local username="$1"
    local group="$2"
    local pass="TechMarket2026*"

    if ! id "${username}" &>/dev/null; then
        useradd -M -s /usr/sbin/nologin -g "${group}" "${username}"
    fi
    echo -e "${pass}\n${pass}" | smbpasswd -a -s "${username}"
    echo "[+] Usuario Samba '${username}' creado en grupo '${group}' (Clave: ${pass})"
}

create_tech_user "admin_tech" "admin"
create_tech_user "juan_ventas" "ventas"
create_tech_user "carlos_import" "compras"
create_tech_user "pedro_bodega" "bodega"

# Añadir también al usuario real del sistema
echo -e "TechMarket2026*\nTechMarket2026*" | smbpasswd -a -s "${REAL_USER}" || true
usermod -aG admin "${REAL_USER}" || true

echo "[*] Asignando permisos a directorios..."
chown -R root:admin /srv/samba/techmarket/general
chmod -R 0775 /srv/samba/techmarket/general

chown -R root:ventas /srv/samba/techmarket/ventas
chmod -R 0770 /srv/samba/techmarket/ventas

chown -R root:compras /srv/samba/techmarket/importaciones
chmod -R 0770 /srv/samba/techmarket/importaciones

chown -R root:bodega /srv/samba/techmarket/despachos
chmod -R 0770 /srv/samba/techmarket/despachos

# Archivos de bienvenida demostrativos
echo "Bienvenido a TechMarket S.A.S. - Directorio General" > /srv/samba/techmarket/general/Aviso_General.txt
echo "Políticas de comisiones y catálogo de precios locales" > /srv/samba/techmarket/ventas/Precios_Mayoristas.txt
echo "Declaraciones de importación aduanera DIAN y Manifiestos Shenzhen/Miami" > /srv/samba/techmarket/importaciones/DEX_2026.txt
echo "Planilla de entregas y despachos del día" > /srv/samba/techmarket/despachos/Despachos_Armenia.txt

echo "[*] Aplicando configuración en /etc/samba/smb.conf..."
if [[ -f "${CONFIG_DIR}/smb.conf" ]]; then
    cp "${CONFIG_DIR}/smb.conf" /etc/samba/smb.conf
fi

echo "[*] Reiniciando y habilitando servicios smbd y nmbd..."
systemctl restart smbd nmbd
systemctl enable smbd nmbd

echo "[✓] Verificación de recursos compartidos disponibles en Samba:"
smbclient -L localhost -N || true

echo "[✓] Servidor Samba listo. Acceso desde Windows: \\\\<IP_SERVIDOR>\\general"
