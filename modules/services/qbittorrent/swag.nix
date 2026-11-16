# qBittorrent reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.qbittorrent-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "qbittorrent";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = cfg.webPort;
    });
  };
}
