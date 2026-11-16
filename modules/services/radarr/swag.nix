# Radarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.radarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "radarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 7878;
    });
  };
}
