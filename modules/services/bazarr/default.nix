# Bazarr service implementation.
{...}: {
  flake.modules.nixos.bazarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.bazarr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-bazarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/TV";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Movies";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/bazarr";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/bazarr/config";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.data}/Downloads";
          })
        ];

        virtualisation.oci-containers.containers.bazarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            BAZARR__AUTH__APIKEY = cfg.apiKey;
          };
          image = "lscr.io/linuxserver/bazarr:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/bazarr/config:/config"
            "${config.neo.core.volumes.media}/TV:/tv"
            "${config.neo.core.volumes.media}/Movies:/movies"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
