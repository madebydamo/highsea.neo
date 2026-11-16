# Lidarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.lidarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "lidarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 8686;
    });
  };
}
