#!/usr/bin/env bash
set -euo pipefail

ensure_webroot() {
  local host="$1"
  mkdir -p "/var/www/$host/public"
  if [ ! -f "/var/www/$host/public/index.php" ]; then
    cat >/var/www/$host/public/index.php <<'PHP'
<?php require_once '/opt/farispanel/web/bootstrap.php';
PHP
  fi
  chown -R www-data:www-data "/var/www/$host"
}

render_vhost() {
  local tpl="$1" out="$2"
  shift 2
  local content; content="$(cat "$tpl")"
  for kv in "$@"; do
    key="${kv%%=*}"; val="${kv#*=}"
    content="$(echo "$content" | sed -e "s|__${key}__|$val|g")"
  done
  echo "$content" > "$out"
  ln -sf "$out" "/etc/nginx/sites-enabled/$(basename "$out")"
}

reload_nginx() { nginx -t && systemctl reload nginx; }

set_edition() {
  local ed="$1"; local exp="${2:-}"
  mkdir -p /etc/farispanel
  cat >/etc/farispanel/edition.conf <<EOF
EDITION=$ed
TRIAL_EXPIRES_AT=$exp
EOF
}

apply_snippets() {
  cp -f /opt/farispanel/configs/nginx-snippets/*.conf /etc/nginx/conf.d/ || true
}
