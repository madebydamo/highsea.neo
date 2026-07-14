# Listenarr service options.
{...}: {
  flake.modules.nixos.listenarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.listenarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "listenarr service" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "listenarr";
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["listenarr"];
              networks = ["internal"];
              ports = [4545];
            }
            // lib.neo.mkContainerDefinitions {
              listenarr = "ghcr.io/listenarrs/listenarr:canary";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/listenarr"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = "https://cdn.jsdelivr.net/gh/selfhst/icons/svg/listenarr.svg";
              description = ''
                Listenarr automates audiobook collection management similar to Sonarr or Radarr, but for audiobooks. It can search, download, and organize your library automatically using metadata from Audible and other sources.
              '';
              projectUrl = "https://getlistenarr.com/";
              githubUrl = "https://github.com/Listenarrs/Listenarr";
              releaseUrl = "https://github.com/Listenarrs/Listenarr/releases";
            };
        };
        default = {};
        description = "Listenarr service configuration";
      };
    };
}
