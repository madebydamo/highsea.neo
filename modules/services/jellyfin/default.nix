# Jellyfin service implementation.
{...}: {
  flake.modules.nixos.jellyfin = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.jellyfin;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-jellyfin.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/jellyfin";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/jellyfin/config";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/jellyfin/cache";
          })
        ];

        virtualisation.oci-containers.containers.jellyfin = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
          };
          image = "lscr.io/linuxserver/jellyfin:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/jellyfin/config:/config"
            "${config.neo.core.volumes.appdata}/jellyfin/cache:/cache"
            "${config.neo.core.volumes.media}:/media"
          ];
          networks = ["host"];
        };
      };
    };
}
