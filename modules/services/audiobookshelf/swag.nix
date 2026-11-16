# Audiobookshelf reverse proxy configuration for SWAG.
{...}: {
  neoPlugin.modules.audiobookshelf-swag = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "audiobookshelf";
    cfg = config.neo.services.${name};
  in {
    config.neo.services.${name}.proxyConf = lib.mkDefault (lib.neo.mkSubdomainProxyConf {
      inherit config cfg;
      upstream = name;
      port = 80;
    });
  };
}
