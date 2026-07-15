# Lidarr service implementation.
{...}: {
  flake.modules.nixos.lidarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.lidarr;
    in {
      config = mkIf cfg.enabled {
        assertions = [
          {
            assertion = cfg.apiKey != null;
            message = "neo.services.lidarr: apiKey must be set when the service is enabled.";
          }
        ];

        systemd.services.docker-lidarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.data}/Downloads";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Music";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/lidarr";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/lidarr/config";
          })
        ];

        virtualisation.oci-containers.containers.lidarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            LIDARR__AUTH__APIKEY = cfg.apiKey;
          };
          image = cfg.containers.lidarr;
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/lidarr/config:/config"
            "${config.neo.core.volumes.media}/Music:/music"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
