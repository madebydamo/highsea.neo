# Radarr reverse proxy configuration for SWAG.
{...}: {
  flake.modules.nixos.radarr-swag = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.radarr;
  in {
    config.neo.services.radarr.proxyConf = lib.mkDefault ''
      server {
        include /config/nginx/listen-https.conf;
        http2 on;
        server_name ${cfg.subdomain}.*;
        include /config/nginx/ssl.conf;
        include /config/nginx/geo-access.conf;
        client_max_body_size 0;

        location / {
          include /config/nginx/proxy.conf;
          include /config/nginx/resolver.conf;
          set $upstream_app radarr;
          set $upstream_port 7878;
          set $upstream_proto http;
          proxy_pass $upstream_proto://$upstream_app:$upstream_port;
          ${lib.neo.authBlock config cfg}
        }
        ${lib.neo.authLocations config cfg}
      }
    '';
  };
}
