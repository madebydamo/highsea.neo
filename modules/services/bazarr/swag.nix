# Bazarr reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.bazarr-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "bazarr";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 6767;
    });
  };
}
