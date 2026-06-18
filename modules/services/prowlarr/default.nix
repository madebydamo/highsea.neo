# Prowlarr service implementation.
{...}: {
  flake.modules.nixos.prowlarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.prowlarr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-prowlarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/prowlarr/config";
          })
        ];

        virtualisation.oci-containers.containers.prowlarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            PROWLARR__AUTH__APIKEY = cfg.apiKey;
          };
          image = "lscr.io/linuxserver/prowlarr:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/prowlarr/config:/config"
          ];
          networks = ["internal"];
        };
      };
    };
}
