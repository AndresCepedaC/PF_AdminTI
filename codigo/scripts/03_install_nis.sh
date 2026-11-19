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

echo "[*] Estableciendo dominio NIS: ${NIS_DOMAIN}..."
nisdomainname "${NIS_DOMAIN}" || true
echo "${NIS_DOMAIN}" > /etc/defaultdomain

echo "[*] Instalando rpcbind y NIS..."
DEBIAN_FRONTEND=noninteractive apt install -y rpcbind nis

echo "[*] Configurando modo servidor maestro en /etc/default/nis..."
sed -i 's/^NISSERVER=.*/NISSERVER=master/' /etc/default/nis
sed -i 's/^NISCLIENT=.*/NISCLIENT=true/' /etc/default/nis

echo "[*] Configurando subredes autorizadas en /etc/ypserv.securenets..."
cat << 'EOF' > /etc/ypserv.securenets
255.0.0.0       127.0.0.0
0.0.0.0         0.0.0.0
EOF

echo "[*] Configurando /etc/yp.conf para servidor local..."
echo "domain ${NIS_DOMAIN} server 127.0.0.1" > /etc/yp.conf

echo "[*] Creando usuario de prueba corporativo en Linux para NIS..."
if ! id "tecnico_techmarket" &>/dev/null; then
    useradd -m -s /bin/bash tecnico_techmarket
    echo "tecnico_techmarket:TechMarket2026*" | chpasswd
    echo "[+] Usuario 'tecnico_techmarket' creado con éxito."
fi

echo "[*] Reiniciando servicios RPC y NIS..."
systemctl restart rpcbind
systemctl restart ypserv || true
systemctl restart yppasswdd || true

echo "[*] Inicializando base de datos de mapas NIS con ypinit..."
# Construir mapas sin intervención interactiva
echo | /usr/lib/yp/ypinit -m << 'EOF'
next
y
EOF

systemctl restart ypserv
systemctl restart yppasswdd
systemctl restart ypbind || true

systemctl enable rpcbind ypserv yppasswdd

echo "[✓] Verificación de mapas NIS disponibles:"
ypwhich || true
ypcat passwd || true

echo "[✓] Servidor NIS Master instalado y en ejecución en el dominio '${NIS_DOMAIN}'."
