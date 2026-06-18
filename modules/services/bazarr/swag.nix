# Bazarr reverse proxy configuration for SWAG.
{...}: {
  flake.modules.nixos.bazarr-swag = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.bazarr;
  in {
    config.neo.services.bazarr.proxyConf = lib.mkDefault ''
      server {
        listen 443 ssl;
        http2 on;
        server_name ${cfg.subdomain}.*;
        include /config/nginx/ssl.conf;

        client_max_body_size 0;

        location / {
          include /config/nginx/proxy.conf;
          include /config/nginx/resolver.conf;
          set $upstream_app bazarr;
          set $upstream_port 6767;
          set $upstream_proto http;
          proxy_pass $upstream_proto://$upstream_app:$upstream_port;
          ${lib.neo.authBlock config cfg}
        }
        ${lib.neo.authLocations config cfg}
      }
    '';
  };
}
