# Seerr service implementation.
# declarr-seerr (declarr/default.nix) pre-configures settings.json before the
# first sign-in; Seerr starts on its own and writes that file first.
{...}: {
  neoPlugin.modules.seerr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "seerr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      # The image runs as node (1000:1000) whatever neo.core.uid is.
      owned = dirPath: {
        inherit dirPath;
        user = "1000";
        group = "1000";
      };
    in {
      config = mkIf cfg.enabled {
        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          (owned appdata)
          (owned "${appdata}/config")
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment = {
            TZ = config.neo.core.timeZone;
            LOG_LEVEL = "info";
            PORT = "5055";
          };
          volumes = [
            "${appdata}/config:/app/config"
          ];
          networks = ["internal"];
          extraOptions = [
            "--init"
          ];
        };
      };
    };
}
