# Radarr service implementation.
{...}: {
  flake.modules.nixos.radarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.radarr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-radarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Movies";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/radarr/config";
          })
        ];

        virtualisation.oci-containers.containers.radarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            RADARR__AUTH__APIKEY = cfg.apiKey;
          };
          image = "lscr.io/linuxserver/radarr:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/radarr/config:/config"
            "${config.neo.core.volumes.media}/Movies:/movies"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
