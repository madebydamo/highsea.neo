# Seerr service options.
{...}: {
  neoPlugin.modules.seerr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "seerr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "A wish list where your household asks for films and shows${plugin.label}" {rank = 0;};
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "ghcr.io/seerr-team/seerr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Let your household request films and shows${plugin.label}";
              description = ''
                Everyone at home can browse new and popular films and shows and ask for the ones they want.
                Requests go straight to Sonarr and Radarr, and Seerr tells people when their film or show is ready in Jellyfin.
              '';
              notes = ''
                On first visit, sign in with a Jellyfin account (Jellyfin address: its public address on port 443 with SSL). The media helper connects Sonarr and Radarr before that.
                Its API (/api/) skips the Neo login page and needs Seerr's own sign-in or API key.
              '';
              privacy = ["movies-tv"];
              projectUrl = "https://docs.seerr.dev/";
              githubUrl = "https://github.com/seerr-team/seerr";
              releaseUrl = "https://github.com/seerr-team/seerr/releases";
              license = {
                spdx = "MIT";
                url = "https://github.com/seerr-team/seerr/blob/develop/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Seerr: film and show requests";
      };
    };
}
