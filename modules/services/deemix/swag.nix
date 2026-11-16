# Deemix reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.deemix-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "deemix";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 6595;
    });
  };
}
