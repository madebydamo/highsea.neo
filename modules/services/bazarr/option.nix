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
                type = types.nullOr types.str;
                default = null;
                description = "Stable API key for Bazarr (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
                helper = lib.neo.helpers.randomToken;
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
            // lib.neo.mkContainerDefinitions {
              bazarr = "lscr.io/linuxserver/bazarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/bazarr"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/bazarr.svg";
              description = ''
                Bazarr is a companion application to Sonarr and Radarr. It can manage and download subtitles based on your requirements. You define your preferences by TV show or movie and Bazarr takes care of everything for you.
              '';
              projectUrl = "https://www.bazarr.media/";
              githubUrl = "https://github.com/morpheus65535/bazarr";
              releaseUrl = "https://github.com/morpheus65535/bazarr/releases";
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Bazarr service configuration";
      };
    };
}
