# Tdarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.tdarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "tdarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 8265;
    });
  };
}
