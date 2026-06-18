# Sonarr service implementation.
{...}: {
  flake.modules.nixos.sonarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.sonarr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-sonarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/sonarr/config";
          })
        ];

        virtualisation.oci-containers.containers.sonarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            SONARR__AUTH__APIKEY = cfg.apiKey;
          };
          image = "lscr.io/linuxserver/sonarr:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/sonarr/config:/config"
            "${config.neo.core.volumes.media}/TV:/tv"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
