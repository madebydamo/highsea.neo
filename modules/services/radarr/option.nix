# Radarr service options.
{...}: {
  neoPlugin.modules.radarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "radarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Films you want, downloaded automatically${plugin.label}" {rank = 0;};
              # Reaches the container as RADARR__AUTH__APIKEY; declarr and the
              # exporter use the same key.
              apiKey = lib.neo.mkSecretOption {
                type = types.nullOr types.str;
                default = null;
                description = "Key the other media apps use to talk to Radarr. Changing it is passed on to apps the media helper connects; apps you connected by hand need the new key.";
                helper = lib.neo.helpers.randomToken;
                rank = 5;
                ui = lib.neo.ui.mkUi {label = "API key";};
              };
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
              auth.publicPaths = [
                "^/api/"
                "^/ping"
              ];
            }
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = [(lib.neo.docker.serviceNetwork name)];
              ports = [7878];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/radarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Gets the films you want automatically${plugin.label}";
              description = ''
                Add the films you want to watch and Radarr finds, downloads and files them as soon as they are available.
                It can later swap a film for a better-quality copy, and new films show up in Jellyfin by themselves.
              '';
              notes = ''
                Radarr's own sign-in is off for visits through Neo, so the Neo login page is the only gate for its web page.
                Its API (/api/, used by Prowlarr, Seerr and phone apps) skips the Neo login and needs the API key.
                Films are saved under Media/Movies, downloads go through qBittorrent into Downloads.
                With the media helper on, download client, quality profiles and indexers are set up for you; changes to those in Radarr are reset on its next run.
              '';
              privacy = ["movies-tv"];
              projectUrl = "https://radarr.video/";
              githubUrl = "https://github.com/Radarr/Radarr";
              releaseUrl = "https://github.com/Radarr/Radarr/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/Radarr/Radarr/blob/develop/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Radarr: downloads the films you want";
      };
    };
}
