# Listenarr service implementation.
{...}: {
  flake.modules.nixos.listenarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.listenarr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-listenarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.data}/Downloads";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Audiobooks";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/listenarr";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/listenarr/config";
          })
        ];

        virtualisation.oci-containers.containers.listenarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            UMASK = "022";
          };
          image = cfg.containers.listenarr;
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/listenarr/config:/app/config"
            "${config.neo.core.volumes.media}/Audiobooks:/audiobooks"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
