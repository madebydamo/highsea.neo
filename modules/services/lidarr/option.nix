# Lidarr service options.
{...}: {
  flake.modules.nixos.lidarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.lidarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "lidarr service" {rank = 0;};
              apiKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Stable API key for Lidarr (enables declarr auto-configuration compatibility; overridable)";
                helper = lib.neo.helpers.randomToken;
                rank = 5;
              };
            }
            // neo.mkReverseProxyOptions {
              subdomain = "lidarr";
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["lidarr"];
              networks = ["internal"];
              ports = [8686];
            }
            // lib.neo.mkContainerDefinitions {
              lidarr = "lscr.io/linuxserver/lidarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/lidarr"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/lidarr.svg";
              description = ''
                Lidarr is a music collection manager for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new albums from your favorite artists and will interface with clients and indexers to grab, sort, and rename them.
                It can also be configured to automatically upgrade the quality of existing files in the library when a better quality format becomes available.
              '';
              projectUrl = "https://lidarr.audio/";
              githubUrl = "https://github.com/Lidarr/Lidarr";
              releaseUrl = "https://github.com/Lidarr/Lidarr/releases";
            };
        };
        default = {};
        description = "Lidarr service configuration";
      };
    };
}
