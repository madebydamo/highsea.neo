# Seerr service implementation.
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
            dirPath = "${config.neo.core.volumes.appdata}/seerr";
            user = "1000";
            group = "1000";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/seerr/config";
            user = "1000";
            group = "1000";
          })
        ];

        # When declarr is enabled, ensure it has run (and written settings.json + created dir)
        # before starting the seerr container. This lets declarr --sync fully pre-configure
        # seerr (radarr/sonarr links, initialized, media server type, connection params)
        # declaratively via the settings file that seerr loads on startup.
        systemd.services.docker-seerr = {
          after = lib.optionals (config.neo.services.declarr.enabled or false) ["declarr.service"];
          wants = lib.optionals (config.neo.services.declarr.enabled or false) ["declarr.service"];
        };

        virtualisation.oci-containers.containers.seerr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            LOG_LEVEL = "debug";
            PORT = "5055";
          };
          image = "ghcr.io/seerr-team/seerr:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/seerr/config:/app/config"
          ];
          networks = ["internal"];
          extraOptions = [
            "--init"
          ];
        };
      };
    };
}
