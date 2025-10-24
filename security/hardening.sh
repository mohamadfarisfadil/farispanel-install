#!/usr/bin/env bash
set -euo pipefail
apt-get update -y
apt-get install -y fail2ban clamav clamav-daemon

systemctl enable --now fail2ban
systemctl enable --now clamav-freshclam

# jadwal scan harian
echo '0 3 * * * root clamscan -ri /var/www --exclude-dir="^/proc" --log=/var/log/clamav/scan.log' >/etc/cron.d/faris_clamav
