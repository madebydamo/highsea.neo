# Seerr service options.
{...}: {
  flake.modules.nixos.seerr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.seerr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "seerr service (seerr; declarr support)" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "seerr";
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // lib.neo.mkContainerDefinitions {
              seerr = "ghcr.io/seerr-team/seerr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/seerr"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyseerr.svg";
              description = ''
                Seerr is a free and open source software application for managing requests for your media library. It is the current merged successor to Jellyseerr and Overseerr (Jellyseerr/Overseerr merger project).
              '';
              projectUrl = "https://docs.seerr.dev/";
              githubUrl = "https://github.com/seerr-team/seerr";
              releaseUrl = "https://github.com/seerr-team/seerr/releases";
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Seerr service configuration";
      };
    };
}
