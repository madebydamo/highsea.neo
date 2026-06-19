# Sonarr service options.
{...}: {
  flake.modules.nixos.sonarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.sonarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "sonarr service" {rank = 0;};
              apiKey = mkOption {
                type = types.str;
                default = "sonarrapikey1234567890abcdefghij";
                description = "Stable API key for Sonarr (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
              };
            }
            // neo.mkReverseProxyOptions {
              subdomain = "sonarr";
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["sonarr"];
              networks = ["internal"];
              ports = [8989];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/sonarr.svg";
              description = ''
                Sonarr is a PVR for Usenet and BitTorrent users. It can monitor multiple RSS feeds for new episodes of your favorite shows and will interface with clients and indexers to grab, sort, and rename them.
                It can also be configured to automatically upgrade the quality of files already downloaded when a better quality format becomes available.
              '';
              projectUrl = "https://sonarr.tv/";
              githubUrl = "https://github.com/Sonarr/Sonarr";
              releaseUrl = "https://github.com/Sonarr/Sonarr/releases";
            };
        };
        default = {};
        description = "Sonarr service configuration";
      };
    };
}
