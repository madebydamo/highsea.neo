# Sonarr service implementation.
{...}: {
  neoPlugin.modules.sonarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "sonarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      vols = config.neo.core.volumes;
    in {
      config = mkIf cfg.enabled {
        assertions = [
          {
            assertion = cfg.apiKey != null;
            message = "neo.services.${name}: set the API key (use Generate).";
          }
        ];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          "${vols.data}/Downloads"
          "${vols.media}/TV"
          appdata
          "${appdata}/config"
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              SONARR__AUTH__APIKEY = cfg.apiKey;
              SONARR__LOG__LEVEL = "info";
            };
          volumes = [
            "${appdata}/config:/config"
            "${vols.media}/TV:/tv"
            "${vols.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
