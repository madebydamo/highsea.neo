# Deemix service implementation.
# Docker image: ghcr.io/bambanah/deemix — web UI on port 6595.
# Docs: https://github.com/bambanah/deemix
{...}: {
  flake.modules.nixos.deemix = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.deemix;
      appdata = "${config.neo.core.volumes.appdata}/deemix";
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-deemix.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = appdata;
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${appdata}/config";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Music";
          })
        ];

        virtualisation.oci-containers.containers.deemix = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            UMASK_SET = "022";
            DEEMIX_SERVER_PORT = "6595";
            DEEMIX_DATA_DIR = "/config";
            DEEMIX_MUSIC_DIR = "/downloads";
            DEEMIX_HOST = "0.0.0.0";
            DEEMIX_SINGLE_USER = "true";
          };
          image = cfg.containers.deemix;
          autoStart = true;
          volumes = [
            "${appdata}/config:/config"
            "${config.neo.core.volumes.media}/Music:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
