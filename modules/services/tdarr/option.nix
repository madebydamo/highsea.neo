# Tdarr service options.
{...}: {
  flake.modules.nixos.tdarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.tdarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "tdarr service" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "tdarr";
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["tdarr"];
              networks = ["internal"];
              ports = [8265];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/tdarr.svg";
              description = ''
                Tdarr is a cross-platform conditional based transcoding application for automating media library transcode/remux management in order to process your media files.
              '';
              projectUrl = "https://tdarr.io/";
              githubUrl = "https://github.com/HaveAGitGat/Tdarr";
              releaseUrl = "https://github.com/HaveAGitGat/Tdarr/releases";
            };
        };
        default = {};
        description = "Tdarr service configuration";
      };
    };
}
