# Deemix service options.
{...}: {
  flake.modules.nixos.deemix-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.deemix = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "deemix service" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "deemix";
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["deemix"];
              networks = ["internal"];
              ports = [6595];
            }
            // lib.neo.mkContainerDefinitions {
              deemix = "ghcr.io/bambanah/deemix:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/deemix"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/deezer.svg";
              description = ''
                Deemix is a Deezer downloader library and web UI for downloading music tracks, albums, and playlists in high quality. Point it at your music library and use the web interface to search and download.
              '';
              projectUrl = "https://github.com/bambanah/deemix";
              githubUrl = "https://github.com/bambanah/deemix";
              releaseUrl = "https://github.com/bambanah/deemix/releases";
            };
        };
        default = {};
        description = "Deemix service configuration";
      };
    };
}
