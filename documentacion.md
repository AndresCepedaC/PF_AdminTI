# TECHMARKET S.A.S. - Infraestructura de TI
## Documentación Técnica Completa y Guía de Operaciones (Semana 4)

**Asignatura:** Administración de Infraestructura de TI  
**Facultad:** Ingeniería de Sistemas y Computación  
**Institución:** Universidad del Quindío  
**Semestre:** 2026-1  
**Empresa:** TECHMARKET S.A.S. (Importación de Tecnología desde China y USA)  
**Entorno Operativo:** Ubuntu Server 22.04/24.04 LTS (2 vCPUs, 4GB RAM, 40GB Disco) en Red Modo Puente (*Bridged*)  

---

## 1. Introducción y Arquitectura General

El presente documento constituye la memoria técnica y el manual de operaciones para la infraestructura de TI de **TECHMARKET S.A.S.**, empresa dedicada a la importación mayorista y reventa local de componentes y productos tecnológicos de alta demanda procedentes de Shenzhen (China) y Miami (USA).

La solución unifica dos paradigmas complementarios:
1. **Plataforma PaaS Moderna (Dokploy & Traefik):** Aislamiento en contenedores para el catálogo web y la base de datos transaccional con orquestación, métricas en tiempo real y terminación TLS/SSL automática.
2. **Servicios de Red Nativos Linux:** Implementación de servicios corporativos de almacenamiento, impresión, autenticación y tiempo (NTP, NFS, NIS, CUPS y Samba) con directivas estrictas de seguridad mediante Firewall UFW.

---

## 2. Preparación del Sistema Base e Infraestructura de Red

### 2.1 Especificaciones de la Máquina Virtual
* **Hipervisor:** VMware Workstation / VirtualBox.
* **Sistema Operativo:** Ubuntu Server 22.04 LTS o 24.04 LTS.
* **Recursos:** 2 vCPUs, 4096 MB RAM, 40 GB de disco virtual.
* **Adaptador de Red:** Modo Puente (*Bridged*), permitiendo que la máquina virtual reciba una dirección IP accesible directamente desde los clientes de la red física local.

### 2.2 Configuración del Hostname y Paquetes Esenciales
```bash
# Definir hostname corporativo
sudo hostnamectl set-hostname srv-infra.techmarket.local

# Actualización de repositorios
sudo apt update && sudo apt upgrade -y

# Herramientas esenciales
sudo apt install -y curl wget git vim net-tools ufw htop rsync unzip ca-certificates gnupg
```

---

## 3. Procedimientos de Instalación y Verificación por Servicio

---

### 3.1 Dokploy (Plataforma PaaS y Reverse Proxy Traefik)

Dokploy centraliza la administración de contenedores Docker y el enrutamiento web con Traefik.

#### Instalación:
```bash
# Instalar Docker Engine
curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh

# Instalar Dokploy de forma desatendida
curl -sSL https://dokploy.com/install.sh | sh
```

#### Verificación y Acceso:
```bash
# Validar que los contenedores de Dokploy y Traefik estén en ejecución
sudo docker ps --filter "name=dokploy"
```
1. Abrir en el navegador: `http://<IP_SERVIDOR>:3000`.
2. Crear la cuenta de administrador inicial de TechMarket (`admin@techmarket.local` / `TechMarket2026*`).
3. El panel mostrará uso de memoria RAM, carga de CPU y el listado de aplicaciones y bases de datos.

![Panel Dokploy](capturas/01_dokploy_panel.png)

---

### 3.2 Base de Datos PostgreSQL (en Dokploy / Docker)

Almacena el catálogo de importaciones, referencias SKU, países de origen (USA/China), precios en COP y stock en bodega.

#### Despliegue:
En el panel de Dokploy:
1. Ir a **Databases** → **Create Database** → Seleccionar **PostgreSQL** (versión 16).
2. Asignar los siguientes parámetros:
   * **Nombre:** `techmarket-postgres`
   * **Database:** `techmarket_db`
   * **User:** `techmarket_admin`
   * **Password:** `TechMarket2026Secure!`
   * **Puerto expuesto:** `5432`

*O alternativamente mediante Docker Compose directo:*
```bash
cd codigo/web-app
sudo docker compose up -d db
```

#### Comandos de Verificación:
```bash
# Verificar estado y salud del contenedor
sudo docker ps --filter "name=postgres"

# Conectarse e inspeccionar las tablas creadas
sudo docker exec -it techmarket_postgres psql -U techmarket_admin -d techmarket_db -c "\dt"
sudo docker exec -it techmarket_postgres psql -U techmarket_admin -d techmarket_db -c "SELECT id, name, origin, price_cop, stock, sku FROM productos LIMIT 5;"
```

![PostgreSQL Dokploy](capturas/03_postgres_dokploy.png)

---

### 3.3 Servicio Web Corporativo TechMarket (HTTPS)

Portal institucional y catálogo de productos importados para clientes mayoristas y minoristas.

#### Despliegue en Dokploy:
1. En Dokploy, ir a **Applications** → **Create Application**.
2. **Source:** Repositorio Git local o compilación con Dockerfile ubicado en `codigo/web-app`.
3. **Variables de Entorno:**
   ```env
   PORT=8080
   DB_HOST=techmarket_postgres (o la IP del servidor)
   DB_PORT=5432
   DB_USER=techmarket_admin
   DB_PASSWORD=TechMarket2026Secure!
   DB_NAME=techmarket_db
   NODE_ENV=production
   ```
4. **Dominio:** Asignar `app.techmarket.local` o tu dominio público / duckdns con SSL (Let's Encrypt o certificado autofirmado generado por Traefik).

*Despliegue directo de prueba:*
```bash
cd codigo/web-app
sudo docker compose up -d --build
```

#### Verificación:
1. Ingresar en el navegador a: `http://<IP_SERVIDOR>:8080` o `https://<DOMINIO>`.
2. Verificar que el indicador muestre `PostgreSQL: Online (5432)`.
3. Probar la búsqueda y filtrado de productos por categoría y país de origen (USA / China).
4. Probar la creación de un nuevo producto con el botón **+ Nuevo Producto** y verificar su persistencia en PostgreSQL.

![Web HTTPS TechMarket](capturas/02_web_https.png)

---

### 3.4 Servicio NTP (Servidor de Tiempo)

Garantiza la sincronización horaria de toda la organización (aduanas, logs y facturación).

#### Instalación y Configuración:
```bash
sudo apt install -y ntp
```
Editar `/etc/ntp.conf`:
```conf
driftfile /var/lib/ntp/ntp.drift
server 0.south-america.pool.ntp.org iburst
server 1.south-america.pool.ntp.org iburst
server pool.ntp.org iburst

restrict -4 default kod notrap nomodify nopeer noquery limited
restrict 127.0.0.1
restrict 192.168.0.0 mask 255.255.0.0 nomodify notrap
```
```bash
sudo systemctl restart ntp
sudo systemctl enable ntp
```

#### Comandos de Verificación:
*En el Servidor:*
```bash
sudo ntpq -p
```
*(Debe verse una tabla de servidores remotos con asterisco `*` o cruz `+` indicando sincronización activa).*

*En un Cliente Linux:*
```bash
# Probar consulta al servidor NTP
ntpdate -q <IP_SERVIDOR>
# o sincronizar hora del sistema
sudo sntp -s <IP_SERVIDOR>
```

![Sincronización NTP](capturas/04_ntp_sync.png)

---

### 3.5 Servidor NFS (Compartición de Archivos para Linux)

Permite montar volúmenes de almacenamiento remoto en estaciones técnicas y servidores de respaldo.

#### Instalación y Configuración:
```bash
sudo apt install -y nfs-kernel-server

# Crear directorios para TechMarket
sudo mkdir -p /srv/nfs/techmarket/{general,catalogos,backups}
sudo chown -R nobody:nogroup /srv/nfs/techmarket
sudo chmod -R 777 /srv/nfs/techmarket
```

Editar `/etc/exports`:
```exports
/srv/nfs/techmarket/general     *(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/techmarket/catalogos   *(rw,sync,no_subtree_check,no_root_squash)
/srv/nfs/techmarket/backups     *(rw,sync,no_subtree_check,no_root_squash)
```

```bash
sudo exportfs -ra
sudo systemctl restart nfs-kernel-server
sudo systemctl enable nfs-kernel-server
```

#### Comandos de Verificación:
*En el Servidor:*
```bash
sudo exportfs -v
```

*En la Máquina Cliente (Linux):*
```bash
sudo apt install -y nfs-common
sudo mkdir -p /mnt/techmarket

# Montar el recurso remoto
sudo mount -t nfs <IP_SERVIDOR>:/srv/nfs/techmarket/general /mnt/techmarket

# Verificar montaje y escribir un archivo de prueba
df -h | grep nfs
echo "Prueba desde cliente Linux" | sudo tee /mnt/techmarket/prueba_cliente.txt
ls -la /mnt/techmarket/
```

![NFS Mount](capturas/05_nfs_mount.png)

---

### 3.6 Servidor NIS (Autenticación Centralizada)

Provee un dominio centralizado de credenciales (`techmarket.local`) para estaciones Linux.

#### Instalación y Configuración del Servidor Maestro:
```bash
# Definir dominio NIS
sudo nisdomainname techmarket.local
echo "techmarket.local" | sudo tee /etc/defaultdomain

# Instalar paquetes
sudo DEBIAN_FRONTEND=noninteractive apt install -y rpcbind nis

# Configurar servidor maestro en /etc/default/nis
sudo sed -i 's/^NISSERVER=.*/NISSERVER=master/' /etc/default/nis

# Indicar servidor local en /etc/yp.conf
echo "domain techmarket.local server 127.0.0.1" | sudo tee /etc/yp.conf

# Permitir subredes en /etc/ypserv.securenets
cat << 'EOF' | sudo tee /etc/ypserv.securenets
255.0.0.0       127.0.0.0
0.0.0.0         0.0.0.0
EOF

# Crear usuario corporativo
sudo useradd -m -s /bin/bash tecnico_techmarket
echo "tecnico_techmarket:TechMarket2026*" | sudo chpasswd

# Reiniciar y compilar mapas
sudo systemctl restart rpcbind ypserv yppasswdd
sudo /usr/lib/yp/ypinit -m
sudo systemctl restart ypserv yppasswdd ypbind
```

#### Comandos de Verificación:
```bash
# Validar mapas NIS activos
ypwhich
ypcat passwd | grep tecnico_techmarket
```

*En el Cliente Linux:*
```bash
# Ejecutar el script cliente provisto:
sudo bash codigo/scripts/03_client_nis.sh <IP_SERVIDOR>

# Validar resolución remota
ypwhich
id tecnico_techmarket
```

![NIS Auth](capturas/06_nis_auth.png)

---

### 3.7 Servidor de Impresión CUPS

Gestiona las impresiones de guías de despacho, etiquetas de código de barras y facturación.

#### Instalación y Configuración:
```bash
sudo apt install -y cups cups-client printer-driver-cups-pdf
sudo usermod -aG lpadmin $USER

# Habilitar administración remota y difusión de impresoras
sudo cupsctl --remote-admin --remote-any --share-printers

# Crear impresora de logística
sudo lpadmin -p "TechMarket_Guias_Despacho" -E -v "cups-pdf:/" \
             -D "Impresora de Guias TechMarket" -L "Bodega Armenia" -o printer-is-shared=true

sudo systemctl restart cups
sudo systemctl enable cups
```

#### Comandos de Verificación:
```bash
# Listar impresoras y cola por defecto
lpstat -p -d

# Enviar trabajo de impresión de prueba desde terminal
echo "Guia de Despacho #TM-2026-094 - Importacion Shenzhen" | lp -d TechMarket_Guias_Despacho
lpstat -o
```
Acceder vía navegador a: `http://<IP_SERVIDOR>:631` para administrar colas e impresoras.

![CUPS Web](capturas/07_cups_interface.png)

---

### 3.8 Servidor Samba (Compartición para Windows y macOS)

Organiza las carpetas compartidas con permisos específicos para Ventas, Importaciones, Bodega y Gerencia.

#### Instalación y Configuración:
```bash
sudo apt install -y samba smbclient
sudo cp codigo/configs/smb.conf /etc/samba/smb.conf
```
*(El script `05_install_samba.sh` crea automáticamente los grupos `admin`, `ventas`, `compras`, `bodega` y las contraseñas SMB).*

```bash
sudo systemctl restart smbd nmbd
sudo systemctl enable smbd nmbd
```

#### Comandos de Verificación:
*En el Servidor:*
```bash
smbclient -L localhost -N
```

*En Clientes Windows:*
1. Presionar `Win + R` y escribir: `\\<IP_SERVIDOR>`
2. Ingresar credenciales:
   * Usuario: `juan_ventas` | Clave: `TechMarket2026*`
   * Se observará acceso a la carpeta `[ventas]` y denegación de acceso a `[importaciones]`.
   * Usuario: `carlos_import` | Clave: `TechMarket2026*`
   * Se observará acceso a la carpeta confidencial `[importaciones]`.

*En Clientes macOS:*
1. En Finder presionar `Cmd + K`
2. Conectar a: `smb://<IP_SERVIDOR>/general`

![Samba Access](capturas/08_samba_access.png)

---

### 3.9 Seguridad (Firewall UFW) y Backups Automáticos (Puntos Extra)

#### Reglas del Firewall UFW:
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw allow 3000/tcp # Dokploy
sudo ufw allow 8080/tcp # Web App
sudo ufw allow 123/udp  # NTP
sudo ufw allow 631/tcp  # CUPS
sudo ufw allow 139/tcp  # Samba
sudo ufw allow 445/tcp  # Samba
sudo ufw allow 111      # RPC
sudo ufw allow 2049     # NFS
sudo ufw enable
```

#### Verificación del Firewall:
```bash
sudo ufw status verbose
```

#### Respaldo Diario Programado:
El script `/usr/local/bin/backup_techmarket.sh` respalda:
1. Todas las configuraciones críticas (`/etc/samba/smb.conf`, `/etc/exports`, `/etc/ntp.conf`, etc.).
2. Volcado SQL completo de la base de datos PostgreSQL (`pg_dumpall`).
3. Almacenamiento en `/srv/nfs/techmarket/backups/daily` con rotación automática de 7 días vía `cron`.

![Firewall y Backup](capturas/09_ufw_firewall.png)

---

## 4. Guía de Solución de Problemas (Troubleshooting)

| Síntoma / Problema | Causa Probable | Solución Paso a Paso |
| :--- | :--- | :--- |
| **No se puede acceder al panel de Dokploy en el puerto 3000** | Firewall bloqueando el puerto o Docker no inició el contenedor. | Ejecutar `sudo ufw allow 3000/tcp` y verificar contenedores con `sudo docker ps`. Si el contenedor cayó, reiniciar con `sudo systemctl restart docker`. |
| **El cliente NFS arroja "Connection timed out" o "Permission denied"** | El servicio RPC/NFS está bloqueado por firewall o IP no autorizada en `/etc/exports`. | Revisar `/etc/exports` asegurando `*(rw,sync,no_root_squash)` o la subred exacta. Ejecutar `sudo exportfs -ra` y abrir puertos con `sudo ufw allow 2049` y `sudo ufw allow 111`. |
| **Error en NIS "ypwhich: Can't communicate with ypbind"** | Dominio NIS no coincide o `ypbind` no se enlazó al servidor. | Validar que el archivo `/etc/defaultdomain` contenga `techmarket.local`. Ejecutar `sudo nisdomainname techmarket.local` y reiniciar con `sudo systemctl restart rpcbind ypserv ypbind`. |
| **Windows no puede conectarse a las carpetas Samba** | Bloqueo de SMB1 o nombres NetBIOS no resueltos. | Conectarse por dirección IP directa (`\\192.168.1.100\general`). Verificar que el usuario tenga clave SMB asignada mediante `sudo smbpasswd -a <usuario>`. |
| **CUPS responde "403 Forbidden" en el navegador** | La directiva `cupsd.conf` restringe el acceso solo a localhost. | Ejecutar `sudo cupsctl --remote-admin --remote-any --share-printers` y reiniciar con `sudo systemctl restart cups`. |
| **La aplicación web no conecta con PostgreSQL** | El contenedor de base de datos está iniciando o las credenciales no coinciden. | Verificar logs con `sudo docker logs techmarket_postgres`. Asegurar que las variables de entorno `DB_HOST`, `DB_USER` y `DB_PASSWORD` coincidan exactamente. |

---

## 5. Decisiones de Diseño y Análisis de Costo-Beneficio (Sustentación de 15 Minutos)

### 5.1 Decisiones de Diseño
1. **Adopción de Dokploy sobre clústeres complejos (ej. Kubernetes):**
   * Para una empresa mediana como TECHMARKET, un clúster de Kubernetes representaría un sobrecosto operativo injustificado. Dokploy brinda las ventajas de contenedores Docker, CI/CD y Traefik SSL con un consumo mínimo de recursos (apto para 2 vCPU y 4GB RAM).
2. **Coexistencia de Servicios Contenerizados y Nativos:**
   * Las aplicaciones web y bases de datos se benefician de la inmutabilidad y aislamiento de Docker.
   * Los servicios de bajo nivel (NFS, Samba, NIS, CUPS, NTP) funcionan con mayor rendimiento, menor latencia y configuración directa como servicios del sistema host (`systemd`).
3. **Esquema de Seguridad por Zonas:**
   * Segmentación por grupos de usuarios Samba (`@ventas`, `@compras`, `@bodega`), protegiendo datos sensibles aduaneros y estados financieros.

### 5.2 Análisis Costo-Beneficio

| Rubro | Solución Tradicional / Cloud Pública | Solución Implementada (TechMarket On-Premise) | Beneficio para TECHMARKET |
| :--- | :--- | :--- | :--- |
| **Licenciamiento SO** | Windows Server Datacenter (~$1.200 USD + CALs de usuario) | Ubuntu Server 22.04/24.04 LTS ($0 USD) | **Ahorro del 100% en licencias base.** Sin límite de CALs para usuarios Samba/NFS/NIS. |
| **Hosting PaaS** | AWS ECS / Heroku / GCP Cloud Run (~$80-$150 USD/mes) | Dokploy PaaS Auto-alojado ($0 USD/mes) | Despliegues continuos ilimitados en el servidor local. |
| **Servicio de Archivos** | Dropbox Business / Google Workspace (~$18 USD/usuario/mes) | Samba + NFS en almacenamiento local | Control total de privacidad sobre manifiestos DIAN y packing lists. |
| **Seguridad y Respaldo**| Software comercial de backup (~$600 USD) | Bash automatizado + Cron + NFS | Respaldo diario sin costo de suscripción. |
| **Retorno de Inversión (ROI)**| Costo proyectado Año 1: **~$6.500 USD** | Costo Año 1 (Hardware existente): **$0 USD en software** | **ROI inmediato:** La infraestructura se paga en el primer mes de operación. |
