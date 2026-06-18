# Seerr (jellyseerr) service options.
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
              enabled = mkEnableOption "seerr service (jellyseerr; declarr support)" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "seerr";
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyseerr.svg";
              description = ''
                Jellyseerr is a free and open source software application for managing requests for your media library. It is a fork of Overseerr built to bring Jellyfin support.
              '';
              projectUrl = "https://docs.jellyseerr.dev/";
              githubUrl = "https://github.com/Fallenbagel/jellyseerr";
              releaseUrl = "https://github.com/Fallenbagel/jellyseerr/releases";
            };
        };
        default = {};
        description = "Seerr service configuration";
      };
    };
}
