#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script Maestro: Despliegue Completo de Infraestructura
# Universidad del Quindío - 2026-1
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================================="
echo "    TECHMARKET S.A.S. - DESPLIEGUE COMPLETO DE INFRAESTRUCTURA   "
echo "=================================================================="
echo "Este script configurará de forma automatizada:"
echo " 1. Configuración Base del Sistema (Ubuntu)"
echo " 2. Servidor de Tiempo NTP"
echo " 3. Servidor de Archivos NFS"
echo " 4. Servidor Maestro NIS"
echo " 5. Servidor de Impresión CUPS"
echo " 6. Servidor Samba SMB/CIFS"
echo " 7. Docker y Plataforma PaaS Dokploy"
echo " 8. Seguridad (Firewall UFW) y Respaldo Automático (Cron)"
echo "=================================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Debes ejecutar este script con privilegios de superusuario: sudo $0"
   exit 1
fi

chmod +x "${SCRIPT_DIR}/0"*.sh

echo ""
echo "Iniciando despliegue secuencial..."
sleep 2

bash "${SCRIPT_DIR}/00_setup_base.sh"
bash "${SCRIPT_DIR}/01_install_ntp.sh"
bash "${SCRIPT_DIR}/02_install_nfs.sh"
bash "${SCRIPT_DIR}/03_install_nis.sh"
bash "${SCRIPT_DIR}/04_install_cups.sh"
bash "${SCRIPT_DIR}/05_install_samba.sh"
bash "${SCRIPT_DIR}/07_security_and_backup.sh"

echo ""
read -p "¿Deseas instalar Dokploy y Docker ahora? (s/n): " RESP_DOKPLOY
if [[ "${RESP_DOKPLOY,,}" == "s" || "${RESP_DOKPLOY,,}" == "si" ]]; then
    bash "${SCRIPT_DIR}/06_install_dokploy.sh"
fi

echo ""
echo "=================================================================="
echo " [✓] DESPLIEGUE FINALIZADO EXITOSAMENTE PARA TECHMARKET S.A.S.  "
echo "=================================================================="
echo "Resumen de acceso:"
echo " - Panel Dokploy:       http://$(hostname -I | awk '{print $1}'):3000"
echo " - Servidor CUPS:        http://$(hostname -I | awk '{print $1}'):631"
echo " - Recursos Samba:       \\\\$(hostname -I | awk '{print $1}')\\general"
echo " - Dominio NIS:          techmarket.local"
echo " - Exportaciones NFS:    /srv/nfs/techmarket"
echo "=================================================================="
