# Seerr (jellyseerr) service implementation.
{...}: {
  flake.modules.nixos.seerr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.seerr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-seerr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/seerr/config";
          })
        ];

        virtualisation.oci-containers.containers.seerr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
          };
          image = "lscr.io/linuxserver/jellyseerr:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/seerr/config:/app/config"
          ];
          networks = ["internal"];
        };
      };
    };
}
