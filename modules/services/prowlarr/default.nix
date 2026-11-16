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
        assertions = lib.neo.requireSecrets name cfg ["apiKey"];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          appdata
          "${appdata}/config"
        ];

        # The API key reaches the container through a rendered env file.
        neo.core.secrets.containerEnv.${name}.PROWLARR__AUTH__APIKEY = cfg.apiKey;

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              PROWLARR__LOG__LEVEL = "info";
            };
          volumes = [
            "${appdata}/config:/config"
          ];
          networks = [(lib.neo.docker.serviceNetwork name)];
        };
      };
    };
}
