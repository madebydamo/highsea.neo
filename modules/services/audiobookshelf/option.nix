# Audiobookshelf service options.
{...}: {
  flake.modules.nixos.audiobookshelf-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.audiobookshelf = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "audiobookshelf service" {rank = 0;};
            }
            // neo.mkReverseProxyOptions {
              subdomain = "audiobookshelf";
              # Audiobookshelf has multi-user auth; skip tinyauth in front.
              auth.available = false;
            }
            // lib.neo.mkContainerDefinitions {
              audiobookshelf = "ghcr.io/advplyr/audiobookshelf:latest";
            }
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/audiobookshelf.svg";
              description = ''
                Audiobookshelf is a self-hosted audiobook and podcast server. Stream to any device, track progress per user, and manage libraries with metadata from several providers.
              '';
              projectUrl = "https://www.audiobookshelf.org/";
              githubUrl = "https://github.com/advplyr/audiobookshelf";
              releaseUrl = "https://github.com/advplyr/audiobookshelf/releases";
            };
        };
        default = {};
        description = "Audiobookshelf service configuration";
      };
    };
}
