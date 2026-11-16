# Prowlarr service implementation.
{...}: {
  neoPlugin.modules.prowlarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "prowlarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
    in {
      config = mkIf cfg.enabled {
        assertions = [
          {
            assertion = cfg.apiKey != null;
            message = "neo.services.${name}: set the API key (use Generate).";
          }
        ];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          appdata
          "${appdata}/config"
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              PROWLARR__AUTH__APIKEY = cfg.apiKey;
              PROWLARR__LOG__LEVEL = "info";
            };
          volumes = [
            "${appdata}/config:/config"
          ];
          networks = ["internal"];
        };
      };
    };
}
