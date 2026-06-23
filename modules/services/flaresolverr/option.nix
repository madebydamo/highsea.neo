# Flaresolverr service options.
{...}: {
  flake.modules.nixos.flaresolverr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.flaresolverr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Flaresolverr service" {rank = 0;};
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["flaresolverr"];
              networks = ["internal"];
              ports = [8191];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://upload.wikimedia.org/wikipedia/commons/4/4b/Cloudflare_Logo.svg";
              description = ''
                Flaresolverr is a proxy to bypass cloudflare bot protection. This can be used by prowlarr.
              '';
              githubUrl = "https://github.com/FlareSolverr/FlareSolverr";
              releaseUrl = "https://github.com/FlareSolverr/FlareSolverr/releases";
            };
        };
        default = {};
        description = "Flaresolverr service configuration";
      };
    };
}
