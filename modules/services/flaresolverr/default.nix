# Flaresolverr service implementation.
{...}: {
  flake.modules.nixos.flaresolverr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.flaresolverr;
    in {
      config = mkIf cfg.enabled {
        virtualisation.oci-containers.containers.flaresolverr = {
          environment = {
            TZ = config.neo.core.timeZone;
          };
          image = cfg.containers.flaresolverr;
          autoStart = true;
          networks = ["internal"];
        };
      };
    };
}
