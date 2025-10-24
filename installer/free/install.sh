#!/usr/bin/env bash
set -euo pipefail
source /opt/farispanel/installer/common.sh

DOMAIN="${1:?domain wajib}"
SUB="${2:?subdomain wajib}"

ensure_webroot "$DOMAIN"
ensure_webroot "$SUB"

apply_snippets

render_vhost "/opt/farispanel/templates/nginx/domain.tpl" \
  "/etc/nginx/sites-available/$DOMAIN.conf" "DOMAIN=$DOMAIN"

render_vhost "/opt/farispanel/templates/nginx/subdomain.tpl" \
  "/etc/nginx/sites-available/$SUB.conf" "SUB=$SUB"

reload_nginx
/opt/farispanel/bin/enable-modules free
set_edition "FREE"
echo "[FREE] Done. Visit http://$SUB"
