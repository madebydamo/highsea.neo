# Lidarr service implementation.
{...}: {
  neoPlugin.modules.lidarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "lidarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      vols = config.neo.core.volumes;
    in {
      config = mkIf cfg.enabled {
        assertions = lib.neo.requireSecrets name cfg ["apiKey"];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          "${vols.data}/Downloads"
          "${vols.media}/Music"
          appdata
          "${appdata}/config"
        ];

        # The API key reaches the container through a rendered env file.
        neo.core.secrets.containerEnv.${name}.LIDARR__AUTH__APIKEY = cfg.apiKey;

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              LIDARR__LOG__LEVEL = "info";
            };
          volumes = [
            "${appdata}/config:/config"
            "${vols.media}/Music:/music"
            "${vols.data}/Downloads:/downloads"
          ];
          networks = [(lib.neo.docker.serviceNetwork name)];
        };
      };
    };
}
