# Jellyfin reverse proxy configuration for SWAG.
# proxy.conf already handles the WebSocket upgrade (/socket) and passes Range
# headers; no extra locations. /metrics is hidden by monitoring.nix (hidePaths).
{...}: {
  neoPlugin.modules.jellyfin-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "jellyfin";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 8096;
    });
  };
}
