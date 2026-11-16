# Sonarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.sonarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "sonarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 8989;
    });
  };
}
