# Sonarr service options.
{...}: {
  neoPlugin.modules.sonarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "sonarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "New episodes of your shows, downloaded automatically${plugin.label}" {rank = 0;};
              # Reaches the container as SONARR__AUTH__APIKEY; declarr and the
              # exporter use the same key. 32 characters: exportarr accepts 20 to 32
              # letters or digits and nothing longer (_lib.nix arrMonitoring).
              apiKey = lib.neo.mkSecretOption {
                type = types.nullOr types.str;
                default = null;
                description = "Key the other media apps use to talk to Sonarr. Changing it is passed on to apps the media helper connects; apps you connected by hand need the new key.";
                helper = lib.neo.helpers.randomToken32Hex;
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
              ports = [8989];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/sonarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Gets new episodes of your shows automatically${plugin.label}";
              description = ''
                Pick the TV shows you follow and Sonarr finds, downloads and files every new episode as it comes out.
                It can later swap episodes for better-quality copies, and new episodes show up in Jellyfin by themselves.
              '';
              notes = ''
                Sonarr's own sign-in is off for visits through Neo, so the Neo login page is the only gate for its web page.
                Its API (/api/, used by Prowlarr, Seerr and phone apps) skips the Neo login and needs the API key.
                Episodes are saved under Media/TV, downloads go through qBittorrent into Downloads.
                With the media helper on, download client, quality profiles and indexers are set up for you; changes to those in Sonarr are reset on its next run.
              '';
              privacy = ["movies-tv"];
              projectUrl = "https://sonarr.tv/";
              githubUrl = "https://github.com/Sonarr/Sonarr";
              releaseUrl = "https://github.com/Sonarr/Sonarr/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/Sonarr/Sonarr/blob/develop/LICENSE.md";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Sonarr: downloads new episodes of your TV shows";
      };
    };
}
