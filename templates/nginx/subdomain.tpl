server {
  listen 80;
  server_name __SUB__;
  root /var/www/__SUB__/public;
  index index.php index.html;

  include /etc/nginx/conf.d/limit_req.conf;

  location / { try_files $uri $uri/ /index.php?$query_string; }
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
  }

  # reverse proxy modul PRO (aktif saat PRO)
  include /etc/nginx/conf.d/proxy_common.conf;
  location /editor/   { proxy_pass http://127.0.0.1:8443/; }
  location /terminal/ { proxy_pass http://127.0.0.1:8444/; }
  location /monitor/  { proxy_pass http://127.0.0.1:19999/; }
}
