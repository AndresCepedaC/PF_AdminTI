#!/usr/bin/env bash
# ==============================================================================
# TECHMARKET S.A.S. - Infraestructura TI
# Script 03: Servidor NIS Master (Autenticación Centralizada)
# ==============================================================================
set -euo pipefail

echo "=========================================================="
echo " [03] Desplegando Servidor Maestro NIS (techmarket.local)"
echo "=========================================================="

if [[ $EUID -ne 0 ]]; then
   echo "[ERROR] Este script debe ejecutarse como root (usar sudo)." 
   exit 1
fi

NIS_DOMAIN="techmarket.local"

# Asegurar repositorio universe
add-apt-repository -y universe 2>/dev/null || true

echo "[*] Estableciendo dominio NIS: ${NIS_DOMAIN}..."
nisdomainname "${NIS_DOMAIN}" || true
echo "${NIS_DOMAIN}" > /etc/defaultdomain

echo "[*] Instalando rpcbind y NIS..."
DEBIAN_FRONTEND=noninteractive apt install -y rpcbind nis || true

if [[ -f /etc/default/nis ]]; then
    sed -i 's/^NISSERVER=.*/NISSERVER=master/' /etc/default/nis
    sed -i 's/^NISCLIENT=.*/NISCLIENT=true/' /etc/default/nis
fi

echo "[*] Configurando subredes autorizadas en /etc/ypserv.securenets..."
cat << 'EOF' > /etc/ypserv.securenets
255.0.0.0       127.0.0.0
0.0.0.0         0.0.0.0
EOF

echo "[*] Configurando /etc/yp.conf para servidor local..."
echo "domain ${NIS_DOMAIN} server 127.0.0.1" > /etc/yp.conf

echo "[*] Creando usuario de prueba corporativo en Linux para NIS..."
if ! id "tecnico_techmarket" &>/dev/null; then
    useradd -m -s /bin/bash tecnico_techmarket || true
    echo "tecnico_techmarket:TechMarket2026*" | chpasswd || true
    echo "[+] Usuario 'tecnico_techmarket' creado con éxito."
fi

echo "[*] Reiniciando servicios RPC y NIS..."
systemctl restart rpcbind || true
systemctl restart ypserv || true
systemctl restart yppasswdd || true

echo "[*] Inicializando base de datos de mapas NIS con ypinit..."
if [[ -x /usr/lib/yp/ypinit ]]; then
    printf "\n\ny\n" | /usr/lib/yp/ypinit -m 2>/dev/null || true
    make -C /var/yp 2>/dev/null || true
fi

systemctl restart ypserv 2>/dev/null || true
systemctl restart yppasswdd 2>/dev/null || true
systemctl restart ypbind 2>/dev/null || true

systemctl enable rpcbind ypserv yppasswdd 2>/dev/null || true

echo "[✓] Verificación de mapas NIS disponibles:"
ypwhich 2>/dev/null || true
ypcat passwd 2>/dev/null || true

echo "[✓] Servidor NIS Master configurado en el dominio '${NIS_DOMAIN}'."
