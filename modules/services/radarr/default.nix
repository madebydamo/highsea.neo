# Radarr service implementation.
{...}: {
  neoPlugin.modules.radarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "radarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      vols = config.neo.core.volumes;
    in {
      config = mkIf cfg.enabled {
        assertions = lib.neo.requireSecrets name cfg ["apiKey"];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          "${vols.data}/Downloads"
          "${vols.media}/Movies"
          appdata
          "${appdata}/config"
        ];

        # The API key reaches the container through a rendered env file.
        neo.core.secrets.containerEnv.${name}.RADARR__AUTH__APIKEY = cfg.apiKey;

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              RADARR__LOG__LEVEL = "info";
            };
          volumes = [
            "${appdata}/config:/config"
            "${vols.media}/Movies:/movies"
            "${vols.data}/Downloads:/downloads"
          ];
          networks = [(lib.neo.docker.serviceNetwork name)];
        };
      };
    };
}
