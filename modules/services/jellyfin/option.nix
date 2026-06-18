# Jellyfin service options.
{...}: {
  flake.modules.nixos.jellyfin-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.jellyfin = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "jellyfin service" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "jellyfin";
              auth.available = false;
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/jellyfin.svg";
              description = ''
                Jellyfin is the volunteer-built media solution that puts you in control of your media. Stream to any device from your own server, with no strings attached.
              '';
              projectUrl = "https://jellyfin.org/";
              githubUrl = "https://github.com/jellyfin/jellyfin";
              releaseUrl = "https://github.com/jellyfin/jellyfin/releases";
            };
        };
        default = {};
        description = "Jellyfin service configuration";
      };
    };
}
