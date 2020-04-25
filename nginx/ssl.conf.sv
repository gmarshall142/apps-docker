server {
  listen              443 http2 ssl;
  listen              [::]:443 http2 ssl;
  server_name         localhost;

  ssl_certificate     /etc/ssl/certs/gemapps.crt;
  ssl_certificate_key /etc/ssl/private/gemapps.key;
  ssl_dhparam         /etc/ssl/certs/dhparam.pem;
}

