# Listenarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.listenarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "listenarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 4545;
    });
  };
}
