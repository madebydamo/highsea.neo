# Tdarr service implementation (server with one internal node).
{...}: {
  neoPlugin.modules.tdarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "tdarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
    in {
      config = mkIf cfg.enabled {
        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          appdata
          "${appdata}/config"
          "${appdata}/server"
          "${appdata}/logs"
          config.neo.core.volumes.media
        ];

        virtualisation.oci-containers.containers.${name} = {
          environment =
            lib.neo.linuxserverEnv config
            // {
              UMASK_SET = "002";
              serverIP = "0.0.0.0";
              serverPort = "8266";
              webUIPort = "8265";
              internalNode = "true";
              inContainer = "true";
              ffmpegVersion = "7";
              nodeName = "TdarrNode";
              auth = "false";
            };
          image = cfg.containers.${name};
          devices = ["/dev/dri:/dev/dri"];
          volumes = [
            "${appdata}/config:/app/configs"
            "${appdata}/server:/app/server"
            "${appdata}/logs:/app/logs"
            # Scratch space for conversions.
            "/tmp/${name}-cache:/temp"
            "${config.neo.core.volumes.media}:/media"
          ];
          networks = [(lib.neo.docker.serviceNetwork name)];
        };
      };
    };
}
