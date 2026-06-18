# Prowlarr service options.
{...}: {
  flake.modules.nixos.prowlarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.prowlarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "prowlarr service" {rank = 0;};
              apiKey = mkOption {
                type = types.str;
                default = "prowlarrapikey1234567890abcdefghij";
                description = "Stable API key for Prowlarr (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
              };
            }
            // neo.mkReverseProxyOptions {
              subdomain = "prowlarr";
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["prowlarr"];
              networks = ["internal"];
              ports = [9696];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/prowlarr.svg";
              description = ''
                Prowlarr is an indexer manager/proxy built on the *arr .net/reactjs base stack to integrate with your various PVR apps. Prowlarr supports management of both Torrent Trackers and Usenet Indexers.
                It integrates seamlessly with Sonarr, Radarr, Lidarr, Readarr, Mylar3, and many other *Arr and Servarr apps.
              '';
              projectUrl = "https://prowlarr.com/";
              githubUrl = "https://github.com/Prowlarr/Prowlarr";
              releaseUrl = "https://github.com/Prowlarr/Prowlarr/releases";
            };
        };
        default = {};
        description = "Prowlarr service configuration";
      };
    };
}
