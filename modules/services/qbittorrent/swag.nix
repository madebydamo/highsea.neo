# Qbittorrent reverse proxy configuration for SWAG.
{...}: {
  flake.modules.nixos.qbittorrent-swag = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.qbittorrent;
  in {
    config.neo.services.qbittorrent.proxyConf = lib.mkDefault ''
      server {
        listen 443 ssl;
        http2 on;
        server_name ${cfg.subdomain}.*;
        include /config/nginx/ssl.conf;

        client_max_body_size 0;

        location / {
          include /config/nginx/proxy.conf;
          include /config/nginx/resolver.conf;
          set $upstream_app qbittorrent;
          set $upstream_port ${toString cfg.webPort};
          set $upstream_proto http;
          proxy_pass $upstream_proto://$upstream_app:$upstream_port;
          ${lib.neo.authBlock config cfg}
        }
        ${lib.neo.authLocations config cfg}
      }
    '';
  };
}
