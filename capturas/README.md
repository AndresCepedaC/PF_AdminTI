# Directorio de Evidencias y Capturas de Pantalla (Semana 4)
## Proyecto: TECHMARKET S.A.S. - Infraestructura de TI

Para cumplir con el criterio de evaluación de **Documentación (10 pts)** y **Presentación (5 pts)**, guarda en este directorio las capturas de pantalla de la infraestructura funcionando. Puedes usar los siguientes nombres estándar para enlazar directamente en `documentacion.md`:

| Nombre de Archivo | Servicio / Prueba | Descripción de lo que debe verse en la captura |
| :--- | :--- | :--- |
| `01_dokploy_panel.png` | **Dokploy PaaS** | Dashboard web de Dokploy (`http://<IP>:3000`) mostrando el estado del servidor, uso de CPU/RAM y aplicaciones creadas. |
| `02_web_https.png` | **Sitio Web** | Portal de TechMarket en el navegador con candado SSL/TLS activo y el catálogo de tecnología visible. |
| `03_postgres_dokploy.png`| **Base de Datos** | Base de datos PostgreSQL desplegada en Dokploy / Docker conectada y tabla `productos` con datos de inventario. |
| `04_ntp_sync.png` | **Servidor NTP** | Salida en consola del comando `ntpq -p` en el servidor y sincronización desde una máquina cliente. |
| `05_nfs_mount.png` | **Servidor NFS** | Salida de `exportfs -v` en el servidor y comando `df -h` / `ls /mnt/techmarket` en la máquina cliente Linux. |
| `06_nis_auth.png` | **Servidor NIS** | Salida de `ypwhich`, `ypcat passwd` y prueba de login o consulta de usuario centralizado con `id tecnico_techmarket`. |
| `07_cups_interface.png` | **Servidor CUPS** | Interfaz web de CUPS (`http://<IP>:631/printers`) mostrando la impresora `TechMarket_Guias_Despacho` activa. |
| `08_samba_access.png` | **Samba SMB** | Acceso a las carpetas compartidas desde el Explorador de Archivos de Windows (`\\<IP>\general`) o Finder de macOS. |
| `09_ufw_firewall.png` | **Firewall (Extra)** | Salida en consola de `sudo ufw status verbose` con todas las reglas de los puertos permitidos. |
| `10_backup_cron.png` | **Backup (Extra)** | Ejecución del script `backup_techmarket.sh` y listado de los archivos comprimidos generados en `/srv/nfs/techmarket/backups`. |
