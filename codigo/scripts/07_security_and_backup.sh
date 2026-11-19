#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 07: Seguridad (UFW Firewall) y Copias de Seguridad Automáticas (Cron)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [07] Configuración de Firewall (UFW) y Backups Automáticos"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

echo "[*] Configurando reglas perimetrales de UFW Firewall para TechMarket..."
ufw default deny incoming
ufw default allow outgoing

# Permitir SSH (Gestión)
ufw allow 22/tcp comment 'SSH Remoto'

# Permitir Servicios Web y Dokploy
ufw allow 80/tcp comment 'HTTP Traefik'
ufw allow 443/tcp comment 'HTTPS Traefik SSL'
ufw allow 3000/tcp comment 'Dokploy Admin Panel'
ufw allow 8080/tcp comment 'Web App Direct Port'

# Permitir NTP
ufw allow 123/udp comment 'NTP Time Server'

# Permitir CUPS
ufw allow 631/tcp comment 'CUPS Impresion Web'

# Permitir Samba
ufw allow 139/tcp comment 'Samba NetBIOS'
ufw allow 445/tcp comment 'Samba SMB'

# Permitir NFS y RPC
ufw allow 111 comment 'RPC Bind'
ufw allow 2049 comment 'NFS Kernel Server'

# Activar firewall de forma no interactiva
echo "y" | ufw enable
ufw status verbose

echo "[*] Creando script de Backup automatizado en /usr/local/bin/backup_techmarket.sh..."
cat << 'EOF' > /usr/local/bin/backup_techmarket.sh
#!/usr/bin/env bash
BACKUP_DIR="/srv/nfs/techmarket/backups/daily"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
mkdir -p "${BACKUP_DIR}"

echo "[$(date)] Iniciando respaldo de configuraciones críticas..."
tar -czf "${BACKUP_DIR}/configs_techmarket_${TIMESTAMP}.tar.gz" \
    /etc/samba/smb.conf \
    /etc/exports \
    /etc/ntp.conf \
    /etc/cups/cupsd.conf \
    /etc/yp.conf 2>/dev/null || true

# Respaldo de base de datos PostgreSQL si el contenedor está activo
if docker ps --format '{{.Names}}' | grep -q "postgres"; then
    echo "[$(date)] Exportando volcado SQL de PostgreSQL..."
    docker exec -t techmarket_postgres pg_dumpall -U techmarket_admin > "${BACKUP_DIR}/pg_dump_${TIMESTAMP}.sql" 2>/dev/null || true
fi

# Mantener solo los últimos 7 días de backups
find "${BACKUP_DIR}" -type f -mtime +7 -delete
echo "[$(date)] Respaldo completado exitosamente en ${BACKUP_DIR}."
EOF

chmod +x /usr/local/bin/backup_techmarket.sh

echo "[*] Registrando tarea cron diaria para ejecutar el respaldo a las 02:00 AM..."
CRON_JOB="0 2 * * * /usr/local/bin/backup_techmarket.sh >> /var/log/backup_techmarket.log 2>&1"
(crontab -l 2>/dev/null | grep -v "backup_techmarket.sh" ; echo "${CRON_JOB}") | crontab -

# Ejecución de prueba inicial
/usr/local/bin/backup_techmarket.sh

echo "[✓] Firewall UFW activo y cron de backup automático configurado."
