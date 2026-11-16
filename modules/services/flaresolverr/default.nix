# FlareSolverr service implementation.
{...}: {
  neoPlugin.modules.flaresolverr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "flaresolverr";
      cfg = config.neo.services.${name};
    in {
      config = mkIf cfg.enabled {
        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment = {
            TZ = config.neo.core.timeZone;
            LOG_LEVEL = "info";
          };
          networks = ["internal"];
        };
      };
    };
}
