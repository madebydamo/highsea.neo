# FlareSolverr service options. No web page: only Prowlarr calls it.
{...}: {
  neoPlugin.modules.flaresolverr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "flaresolverr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Lets Prowlarr open search sites that check for bots${plugin.label}" {rank = 0;};
            }
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = [(lib.neo.docker.serviceNetwork name)];
              ports = [8191];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "ghcr.io/flaresolverr/flaresolverr:latest";
            }
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Helps your search sites get past bot checks${plugin.label}";
              description = ''
                Some download sites show a "checking your browser" page that Prowlarr cannot pass on its own.
                FlareSolverr opens those pages in a hidden browser for Prowlarr, so the sites keep working.
              '';
              notes = ''
                It has no page of its own and no login, so it is never reachable from outside: only Prowlarr calls it. With the media helper on, Prowlarr uses it for sites tagged FlareSolverr.
              '';
              projectUrl = "https://github.com/FlareSolverr/FlareSolverr";
              githubUrl = "https://github.com/FlareSolverr/FlareSolverr";
              releaseUrl = "https://github.com/FlareSolverr/FlareSolverr/releases";
              license = {
                spdx = "MIT";
                url = "https://github.com/FlareSolverr/FlareSolverr/blob/master/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "FlareSolverr: opens bot-checked sites for Prowlarr";
      };
    };
}
