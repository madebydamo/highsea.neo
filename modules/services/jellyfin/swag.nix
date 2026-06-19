# Jellyfin reverse proxy configuration for SWAG.
{...}: {
  flake.modules.nixos.jellyfin-swag = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.jellyfin;
  in {
    config.neo.services.jellyfin.proxyConf = lib.mkDefault ''
      server {
        listen 443 ssl;
        http2 on;
        server_name ${cfg.subdomain}.*;
        include /config/nginx/ssl.conf;

        client_max_body_size 0;

        location / {
          include /config/nginx/proxy.conf;
          proxy_pass http://host.docker.internal:8096;
          proxy_set_header Range $http_range;
          proxy_set_header If-Range $http_if_range;
          ${lib.neo.authBlock config cfg}
        }

        location ~ (/jellyfin)?/socket {
          include /config/nginx/proxy.conf;
          proxy_pass http://host.docker.internal:8096;
          proxy_set_header Upgrade $http_upgrade;
          proxy_set_header Connection "upgrade";
          proxy_set_header Host $host;
          proxy_set_header X-Real-IP $remote_addr;
          proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
          proxy_set_header X-Forwarded-Proto $scheme;
          proxy_set_header X-Forwarded-Host $http_host;
        }

        ${lib.neo.authLocations config cfg}
      }
    '';
  };
}
