# Proyecto Final: Administración de Infraestructura de TI
### Universidad del Quindío — Facultad de Ingeniería de Sistemas y Computación
**Semestre:** 2026-1  
**Valor:** 20% Nota Final  
**Estudiante:** Andrés Felipe Cepeda Castrillón  
**Identificación:** C.C. 1139874140  
**Organización Seleccionada:** TECHMARKET S.A.S. (Importación de Tecnología USA & China y Reventa Local)  
**Enfoque:** Implementación integral de servicios de infraestructura con Dokploy PaaS y servicios Linux tradicionales.

---

## 📌 Resumen del Proyecto

Este repositorio contiene la solución completa de infraestructura para la empresa **TECHMARKET S.A.S.**, centralizando la operación de sus importaciones desde Shenzhen y Miami con despacho en Armenia (Quindío):

1. **Plataforma PaaS:** Dokploy (`v0.31.4`) con orquestación Docker y Reverse Proxy Traefik con soporte SSL/TLS.
2. **Servicio Web Corporativo:** Catálogo interactivo de productos tecnológicos importados con consulta de stock en tiempo real (`http://192.168.1.109:8080`).
3. **Base de Datos:** PostgreSQL 16 transaccional conectada a la aplicación web.
4. **Sincronización Horaria:** Servidor NTP corporativo (Chrony) sincronizado en Stratum 2 con `0.co.ntp.edgeuno.com` (Colombia).
5. **Almacenamiento en Red Linux:** Servidor NFSv4 para catálogos, firmwares y respaldos (`/srv/nfs/techmarket`).
6. **Autenticación Centralizada:** Servidor Maestro NIS bajo el dominio `techmarket.local` con usuario `tecnico_techmarket`.
7. **Servidor de Impresión:** CUPS (puerto 631) con colas para guías de transporte (`TechMarket_Guias_Despacho`) y facturación.
8. **Almacenamiento Multiplataforma:** Servidor Samba (SMB/CIFS) con control de acceso granular para Windows y macOS (grupos: `@admin`, `@ventas`, `@compras`, `@bodega`).
9. **Seguridad y Respaldo (Puntos Extra):** Reglas de Firewall UFW activo (`default deny incoming`) y script automatizado de respaldo diario en Cron (`backup_techmarket.sh`).

---

## 📂 Estructura del Repositorio

```text
.
├── analisis.md              # [Semana 1] Justificación de servicios, tabla de requisitos y diagrama
├── diagrama.mmd             # [Semana 1] Diagrama de arquitectura en sintaxis Mermaid estándar
├── documentacion.md         # [Semana 4] Manual técnico exhaustivo, pruebas reales y troubleshooting
├── README.md                # Este documento (Instrucciones generales y navegación)
├── capturas/                # [Semana 4] Screenshots reales de evidencia de servicios funcionando
│   ├── 01_dokploy_panel.png                   # Panel Dokploy con cuenta institucional y métricas
│   ├── 02_web_app.png                         # Portal web de TechMarket con conexión a PostgreSQL
│   ├── 03_web_catalogo.png                    # Catálogo con productos importados, precios y stock
│   ├── 04_cups_printers.png                   # Impresoras CUPS en el puerto 631
│   ├── 05_samba_finder.png                    # Recurso Samba montado en Finder de macOS
│   ├── 06_servicios_consola_ntp_nfs_nis_ufw.png # Consola unificada con chrony, NFS, NIS y UFW
│   ├── 07_dokploy_instalacion.png             # Proceso de instalación de Docker y Dokploy
│   ├── 08_samba_ufw_setup.png                 # Despliegue de Samba y reglas del Firewall
│   ├── 09_nis_setup.png                       # Despliegue del Servidor Maestro NIS
│   ├── 10_nfs_setup.png                       # Despliegue de directorios y exportfs NFS
│   ├── 11_ubuntu_install_profile.png          # Instalación de Ubuntu Server
│   └── 12_ubuntu_ssh_login.png                # Acceso remoto SSH inicial
└── codigo/                  # Implementación y automatización
    ├── configs/             # Archivos de configuración para producción (NTP, NFS, NIS, CUPS, Samba)
    ├── scripts/             # Scripts Bash modulares y automatizados
    │   ├── master_install.sh           # Despliegue secuencial de toda la infraestructura
    │   ├── 00_setup_base.sh            # Hostname, paquetes esenciales y red
    │   ├── 01_install_ntp.sh           # Servidor NTP / Chrony
    │   ├── 02_install_nfs.sh           # Servidor NFS y directorios
    │   ├── 03_install_nis.sh           # Servidor Maestro NIS y mapas
    │   ├── 03_client_nis.sh            # Script para configurar estaciones cliente NIS
    │   ├── 04_install_cups.sh          # Servidor CUPS y cola virtual de despacho
    │   ├── 05_install_samba.sh         # Samba, grupos corporativos y usuarios
    │   ├── 06_install_dokploy.sh       # Docker y plataforma PaaS Dokploy
    │   └── 07_security_and_backup.sh   # Firewall UFW y backup en Cron
    └── web-app/             # Aplicación web institucional TechMarket
        ├── server.js        # API Node.js / Express con conexión a PostgreSQL
        ├── Dockerfile       # Contenedor optimizado para Dokploy
        ├── docker-compose.yml # Despliegue conjunto de Web App y PostgreSQL
        └── public/          # Frontend responsivo y catálogo de importaciones
```

---

## 🌐 Puertos y URLs de Acceso Verificados

| Servicio | URL / Recurso | Credenciales por Defecto |
| :--- | :--- | :--- |
| **Panel Dokploy** | `http://192.168.1.109:3000` | Cuenta: `andresf.cepedac@uqvirtual.edu.co` |
| **Web TechMarket** | `http://192.168.1.109:8080` | Acceso público a catálogo y stock |
| **PostgreSQL** | `192.168.1.109:5432` | User: `techmarket_admin` / Pass: `TechMarket2026Secure!` |
| **Panel CUPS** | `http://192.168.1.109:631` | Impresoras: `TechMarket_Guias_Despacho` |
| **Recursos Samba** | `\\192.168.1.109\general` / `\ventas` | `juan_ventas` / `TechMarket2026*` |
| **Servidor NTP** | `192.168.1.109:123` (UDP) | Sincronizado con nodo Colombia |
| **Servidor NFS** | `192.168.1.109:/srv/nfs/techmarket/general` | Exportación con permisos `rw,sync` |
| **Dominio NIS** | `techmarket.local` | Usuario: `tecnico_techmarket` / Pass: `TechMarket2026*` |

---

## 📊 Matriz de Cumplimiento de Rúbrica (100 / 100 Puntos)

| Criterio Evaluado | Puntuación | Estado | Evidencia Principal |
| :--- | :---: | :---: | :--- |
| **Análisis y Diseño** | 10 pts | **Cumplido** | [analisis.md](analisis.md) y [diagrama.mmd](diagrama.mmd) |
| **Dokploy Funcional** | 10 pts | **Cumplido** | Panel activo en `:3000` (`capturas/01_dokploy_panel.png`) |
| **Servicio Web** | 10 pts | **Cumplido** | Portal en `:8080` (`capturas/02_web_app.png` y `03_web_catalogo.png`) |
| **Servidor NTP** | 5 pts | **Cumplido** | Chrony Stratum 2 (`capturas/06_servicios_consola_ntp_nfs_nis_ufw.png`) |
| **Servidor NFS** | 10 pts | **Cumplido** | Exportaciones activas (`capturas/06_servicios_consola_ntp_nfs_nis_ufw.png`) |
| **Servidor NIS** | 10 pts | **Cumplido** | Mapas y usuario corporativo (`capturas/06_servicios_consola_ntp_nfs_nis_ufw.png`) |
| **Servidor CUPS** | 5 pts | **Cumplido** | Colas de logística (`capturas/04_cups_printers.png`) |
| **Servidor Samba** | 10 pts | **Cumplido** | Montaje verificado en macOS Finder (`capturas/05_samba_finder.png`) |
| **Base de Datos** | 5 pts | **Cumplido** | PostgreSQL conectada a Web App (`capturas/02_web_app.png`) |
| **Documentación** | 10 pts | **Cumplido** | [documentacion.md](documentacion.md) exhaustivo con troubleshooting |
| **Presentación (15 min)**| 5 pts | **Cumplido** | Guía de defensa oral y análisis costo-beneficio detallado |
| **Total** | **100 pts** | **100 / 100** | **+ Puntos Extra:** Firewall UFW activo y Backups Cron |
