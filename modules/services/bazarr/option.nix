# Bazarr service options.
{...}: {
  flake.modules.nixos.bazarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.bazarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "bazarr service" {rank = 0;};
              apiKey = mkOption {
                type = types.str;
                default = "bazarrapikey1234567890abcdefghij";
                description = "Stable API key for Bazarr (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
              };
            }
            // neo.mkReverseProxyOptions {
              subdomain = "bazarr";
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["bazarr"];
              networks = ["internal"];
              ports = [6767];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bazarr.svg";
              description = ''
                Bazarr is a companion application to Sonarr and Radarr. It can manage and download subtitles based on your requirements. You define your preferences by TV show or movie and Bazarr takes care of everything for you.
              '';
              projectUrl = "https://www.bazarr.media/";
              githubUrl = "https://github.com/morpheus65535/bazarr";
              releaseUrl = "https://github.com/morpheus65535/bazarr/releases";
            };
        };
        default = {};
        description = "Bazarr service configuration";
      };
    };
}
