#!/usr/bin/env bash
set -euo pipefail

# Default arg
EDITION="free"   # free | pro | protrial
DOMAIN=""
SUBDOMAIN=""
EMAIL=""
USE_SSL=0

usage() {
  cat <<EOF
FarisPanel installer (one-liner)
Usage:
  bash <(curl -fsSL https://raw.githubusercontent.com/<USER>/<REPO>/main/quick.sh) \\
    --edition free|pro|protrial --domain pasartef.com --subdomain hosting.pasartef.com \\
    [--email admin@pasartef.com] [--ssl]

Examples:
  # FREE:
  bash <(curl -fsSL https://raw.githubusercontent.com/<USER>/<REPO>/main/quick.sh) \\
    --edition free --domain pasartef.com --subdomain hosting.pasartef.com

  # PRO (langsung full):
  bash <(curl -fsSL https://raw.githubusercontent.com/<USER>/<REPO>/main/quick.sh) \\
    --edition pro --domain pasartef.com --subdomain hosting.pasartef.com --ssl --email admin@pasartef.com
EOF
}

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --edition) EDITION="$2"; shift 2;;
    --domain) DOMAIN="$2"; shift 2;;
    --subdomain) SUBDOMAIN="$2"; shift 2;;
    --email) EMAIL="$2"; shift 2;;
    --ssl) USE_SSL=1; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Argumen tidak dikenal: $1"; usage; exit 1;;
  esac
done

[[ -z "$DOMAIN" || -z "$SUBDOMAIN" ]] && { echo "ERROR: --domain dan --subdomain wajib."; exit 1; }
[[ "$EDITION" =~ ^(free|pro|protrial)$ ]] || { echo "EDITION harus free|pro|protrial"; exit 1; }

# 1) Paket dasar (Ubuntu 24.04)
export DEBIAN_FRONTEND=noninteractive
apt update -y
apt install -y git curl jq nginx mariadb-server ufw zip unzip \
               software-properties-common
add-apt-repository -y ppa:ondrej/php || true
apt update -y
apt install -y php8.2-fpm php8.2-cli php8.2-mysql php8.2-xml php8.2-curl \
               php8.2-zip php8.2-gd php8.2-mbstring php8.2-intl

ufw allow OpenSSH || true
ufw allow 'Nginx Full' || true
yes | ufw enable || true
systemctl enable --now nginx php8.2-fpm mariadb

# 2) Clone/update repo ke /opt/farispanel
INSTALL_DIR="/opt/farispanel"
if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" fetch --all --prune
  git -C "$INSTALL_DIR" reset --hard origin/main
else
  mkdir -p "$INSTALL_DIR"
  git clone --depth=1 https://github.com/<USER>/<REPO>.git "$INSTALL_DIR"
fi

chmod +x "$INSTALL_DIR"/installer/*/*.sh || true
chmod +x "$INSTALL_DIR"/installer/common.sh || true
chmod +x "$INSTALL_DIR"/bin/* || true
chmod +x "$INSTALL_DIR"/security/*.sh || true

# 3) Jalankan installer sesuai edisi
case "$EDITION" in
  free)     "$INSTALL_DIR/installer/free/install.sh"     "$DOMAIN" "$SUBDOMAIN" ;;
  pro)      "$INSTALL_DIR/installer/pro/install.sh"      "$DOMAIN" "$SUBDOMAIN" ;;
  protrial) "$INSTALL_DIR/installer/protrial/install.sh" "$DOMAIN" "$SUBDOMAIN" ;;
esac

# 4) SSL opsional
if [ $USE_SSL -eq 1 ]; then
  apt install -y certbot python3-certbot-nginx
  if [ -n "$EMAIL" ]; then
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" -d "$SUBDOMAIN" --email "$EMAIL" --agree-tos -n || true
  else
    certbot --nginx -d "$DOMAIN" -d "www.$DOMAIN" -d "$SUBDOMAIN" --register-unsafely-without-email -n || true
  fi
  systemctl reload nginx
fi

echo ">> FarisPanel ($EDITION) selesai. Buka: http://$SUBDOMAIN"
