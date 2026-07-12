# Audiobookshelf service implementation.
# Docker image: ghcr.io/advplyr/audiobookshelf — listens on port 80.
# Docs: https://audiobookshelf.org/docs/documentation/install/docker
# Does not use PUID/PGID; run as neo.core.uid:gid via the user directive.
{...}: {
  flake.modules.nixos.audiobookshelf = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.audiobookshelf;
      appdata = "${config.neo.core.volumes.appdata}/audiobookshelf";
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-audiobookshelf.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = appdata;
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${appdata}/config";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${appdata}/metadata";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Audiobooks";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}/Podcasts";
          })
        ];

        virtualisation.oci-containers.containers.audiobookshelf = {
          environment = {
            TZ = config.neo.core.timeZone;
          };
          image = cfg.containers.audiobookshelf;
          autoStart = true;
          user = "${toString config.neo.core.uid}:${toString config.neo.core.gid}";
          volumes = [
            # Keep config and metadata as separate top-level mounts (not nested).
            "${appdata}/config:/config"
            "${appdata}/metadata:/metadata"
            "${config.neo.core.volumes.media}/Audiobooks:/audiobooks"
            "${config.neo.core.volumes.media}/Podcasts:/podcasts"
          ];
          networks = ["internal"];
        };
      };
    };
}
