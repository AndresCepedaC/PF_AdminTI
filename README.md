# Proyecto Final: Administración de Infraestructura de TI
### Universidad del Quindío — Facultad de Ingeniería de Sistemas y Computación
**Semestre:** 2026-1  
**Valor:** 20% Nota Final  
**Organización Seleccionada:** TECHMARKET S.A.S. (Importación de Tecnología USA & China y Reventa Local)  
**Enfoque:** Implementación de servicios de infraestructura con Dokploy PaaS y servicios Linux tradicionales.

---

## 📌 Resumen del Proyecto

Este repositorio contiene la solución completa de infraestructura para la empresa **TECHMARKET S.A.S.**, centralizando la gestión de:
1. **Plataforma PaaS:** Dokploy con orquestación Docker y Reverse Proxy Traefik con soporte SSL/TLS.
2. **Servicio Web Corporativo:** Catálogo interactivo de productos tecnológicos importados con consulta de stock en tiempo real.
3. **Base de Datos:** PostgreSQL transaccional conectada a la aplicación web.
4. **Sincronización Horaria:** Servidor NTP corporativo (Stratum 2) enlazado con `pool.ntp.org`.
5. **Almacenamiento en Red Linux:** Servidor NFSv4 para catálogos, firmwares y respaldos.
6. **Autenticación Centralizada:** Servidor Maestro NIS bajo el dominio `techmarket.local`.
7. **Servidor de Impresión:** CUPS (puerto 631) con colas para guías de transporte y facturación.
8. **Almacenamiento Multiplataforma:** Servidor Samba (SMB/CIFS) con control de acceso granular para Windows y macOS (grupos: `@admin`, `@ventas`, `@compras`, `@bodega`).
9. **Seguridad y Respaldo (Puntos Extra):** Reglas de Firewall UFW y script automatizado de respaldo diario en Cron (`backup_techmarket.sh`).

---

## 📂 Estructura del Repositorio

```text
.
├── analisis.md              # [Semana 1] Justificación de servicios y tabla de requisitos
├── diagrama.mmd             # [Semana 1] Diagrama de arquitectura en sintaxis Mermaid
├── documentacion.md         # [Semana 4] Manual técnico exhaustivo, pruebas y troubleshooting
├── README.md                # Este documento (Instrucciones generales y navegación)
├── capturas/                # [Semana 4] Screenshots de evidencia de servicios funcionando
│   └── README.md            # Guía detallada con la lista de capturas requeridas
└── codigo/                  # Implementación y automatización
    ├── configs/             # Archivos de configuración listos para producción
    │   ├── ntp.conf         # Configuración del servidor NTP
    │   ├── exports          # Puntos de exportación NFS
    │   ├── yp.conf          # Configuración cliente/servidor NIS
    │   ├── ypserv.securenets# Restricción de subredes para NIS
    │   ├── cupsd.conf       # Configuración con acceso web de CUPS
    │   └── smb.conf         # Configuración departamental de Samba
    ├── scripts/             # Scripts Bash modulares y automatizados
    │   ├── master_install.sh           # Despliegue secuencial de toda la infraestructura
    │   ├── 00_setup_base.sh            # Hostname, paquetes esenciales y red
    │   ├── 01_install_ntp.sh           # Servidor NTP
    │   ├── 02_install_nfs.sh           # Servidor NFS y directorios
    │   ├── 03_install_nis.sh           # Servidor Maestro NIS y mapas
    │   ├── 03_client_nis.sh            # Script para configurar estaciones cliente NIS
    │   ├── 04_install_cups.sh          # Servidor CUPS y cola virtual de despacho
    │   ├── 05_install_samba.sh         # Samba, grupos corporativos y usuarios
    │   ├── 06_install_dokploy.sh       # Docker y plataforma PaaS Dokploy
    │   └── 07_security_and_backup.sh   # Firewall UFW y backup en Cron
    └── web-app/             # Aplicación web institucional TechMarket
        ├── server.js        # API Node.js / Express con conexión a PostgreSQL
        ├── package.json     # Dependencias del proyecto
        ├── Dockerfile       # Empaquetado en contenedor para Dokploy
        ├── docker-compose.yml # Despliegue conjunto de Web App y PostgreSQL
        └── public/          # Frontend responsivo y catálogo de importaciones
            ├── index.html   # Estructura del portal y modal de registro
            ├── styles.css   # Estilos modernos y modo oscuro de alta tecnología
            └── app.js       # Consumo de API, filtros y reloj sincronizado
```

---

## 🚀 Despliegue Rápido en la Máquina Virtual (Ubuntu Server)

### 1. Clonar este repositorio en la máquina virtual:
```bash
git clone <URL_DE_TU_REPOSITORIO> PF_AdminTI
cd PF_AdminTI
```

### 2. Ejecutar la instalación completa:
```bash
cd codigo/scripts
sudo ./master_install.sh
```

El script maestro configurará en secuencia todos los servicios, creará los usuarios departamentales, ajustará los permisos de carpetas y aplicará las políticas de seguridad.

### 3. Levantar la Aplicación Web y Base de Datos (Dokploy o Docker Compose):
```bash
cd ../web-app
sudo docker compose up -d --build
```

---

## 🌐 Puertos y URLs de Acceso

| Servicio | URL / Recurso | Credenciales por Defecto |
| :--- | :--- | :--- |
| **Panel Dokploy** | `http://<IP_VM>:3000` | Creación de cuenta en primer acceso |
| **Web TechMarket** | `http://<IP_VM>:8080` (o `https://<DOMINIO>`) | Acceso público a catálogo |
| **PostgreSQL** | `<IP_VM>:5432` | User: `techmarket_admin` / Pass: `TechMarket2026Secure!` |
| **Panel CUPS** | `http://<IP_VM>:631` | Usuario del sistema en grupo `lpadmin` |
| **Recursos Samba** | `\\<IP_VM>\general` / `\\<IP_VM>\ventas` | `juan_ventas` / `TechMarket2026*` |
| **Servidor NTP** | `<IP_VM>:123` (UDP) | Sincronización transparente |
| **Servidor NFS** | `<IP_VM>:/srv/nfs/techmarket/general` | Montaje libre en subred local |
| **Dominio NIS** | `techmarket.local` | Usuario: `tecnico_techmarket` / Pass: `TechMarket2026*` |

---

## 📊 Criterios de Evaluación y Entregables

* ✅ **Semana 1:** [analisis.md](analisis.md) y [diagrama.mmd](diagrama.mmd) completados.
* ✅ **Semana 2:** Dokploy PaaS, NTP y configuración de red/dominio implementados en [codigo/scripts/](codigo/scripts/).
* ✅ **Semana 3:** Todos los servicios requeridos (Web, NTP, NFS, NIS, CUPS, Samba, PostgreSQL) codificados y probados.
* ✅ **Semana 4:** [documentacion.md](documentacion.md) con guía paso a paso, solución de problemas y análisis costo-beneficio para la presentación.
* ✅ **Puntos Extra:** Firewall UFW activo, copias de seguridad automáticas en Cron y contenedores multi-servicio.
