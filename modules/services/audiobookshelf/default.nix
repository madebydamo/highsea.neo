# Audiobookshelf service implementation.
# Image ghcr.io/advplyr/audiobookshelf listens on port 80 and ignores
# PUID/PGID, so it runs as neo.core.uid:gid through `user`.
{...}: {
  neoPlugin.modules.audiobookshelf = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "audiobookshelf";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      media = config.neo.core.volumes.media;
    in {
      config = mkIf cfg.enabled {
        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          appdata
          "${appdata}/config"
          "${appdata}/metadata"
          "${media}/Audiobooks"
          "${media}/Podcasts"
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment = {
            TZ = config.neo.core.timeZone;
          };
          user = "${toString config.neo.core.uid}:${toString config.neo.core.gid}";
          volumes = [
            # Keep config and metadata as separate top-level mounts (not nested).
            "${appdata}/config:/config"
            "${appdata}/metadata:/metadata"
            "${media}/Audiobooks:/audiobooks"
            "${media}/Podcasts:/podcasts"
          ];
          networks = ["internal"];
        };
      };
    };
}
