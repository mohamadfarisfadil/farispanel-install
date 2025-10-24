server {
  listen 80;
  server_name __DOMAIN__ www.__DOMAIN__;
  root /var/www/__DOMAIN__/public;
  index index.php index.html;

  include /etc/nginx/conf.d/limit_req.conf;

  location / { try_files $uri $uri/ /index.php?$query_string; }
  location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
  }
}
