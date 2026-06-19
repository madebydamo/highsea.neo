# Radarr service options.
{...}: {
  flake.modules.nixos.radarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.radarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "radarr service" {rank = 0;};
              apiKey = mkOption {
                type = types.str;
                default = "radarrapikey1234567890abcdefghij";
                description = "Stable API key for Radarr (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
              };
            }
            // neo.mkReverseProxyOptions {
              subdomain = "radarr";
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["radarr"];
              networks = ["internal"];
              ports = [7878];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/radarr.svg";
              description = ''
                Radarr is a movie collection manager for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new movies and will interface with clients and indexers to grab, sort, and rename them.
                It can also be configured to automatically upgrade the quality of existing files in the library when a better quality format becomes available.
              '';
              projectUrl = "https://radarr.video/";
              githubUrl = "https://github.com/Radarr/Radarr";
              releaseUrl = "https://github.com/Radarr/Radarr/releases";
            };
        };
        default = {};
        description = "Radarr service configuration";
      };
    };
}
