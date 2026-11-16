# Deemix service implementation.
# Image ghcr.io/bambanah/deemix: web page on port 6595.
{...}: {
  neoPlugin.modules.deemix = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "deemix";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      music = "${config.neo.core.volumes.media}/Music";
    in {
      config = mkIf cfg.enabled {
        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          appdata
          "${appdata}/config"
          music
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              UMASK_SET = "022";
              DEEMIX_SERVER_PORT = "6595";
              DEEMIX_DATA_DIR = "/config";
              DEEMIX_MUSIC_DIR = "/downloads";
              DEEMIX_HOST = "0.0.0.0";
              DEEMIX_SINGLE_USER = "true";
            };
          volumes = [
            "${appdata}/config:/config"
            "${music}:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
