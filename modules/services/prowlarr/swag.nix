# Prowlarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.prowlarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "prowlarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 9696;
    });
  };
}
