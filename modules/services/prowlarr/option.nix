# Prowlarr service options.
{...}: {
  neoPlugin.modules.prowlarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "prowlarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "One place for the sites your media apps search${plugin.label}" {rank = 0;};
              # Reaches the container as PROWLARR__AUTH__APIKEY; declarr and the
              # exporter use the same key.
              apiKey = lib.neo.mkSecretOption {
                type = types.nullOr types.str;
                default = null;
                description = "Key the other media apps use to talk to Prowlarr. Changing it is passed on to apps the media helper connects; apps you connected by hand need the new key.";
                helper = lib.neo.helpers.randomToken;
                rank = 5;
                ui = lib.neo.ui.mkUi {label = "API key";};
              };
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
              auth.publicPaths = [
                "^/api/"
                "^/[0-9]+/api/"
                "^/ping"
              ];
            }
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = [(lib.neo.docker.serviceNetwork name)];
              ports = [9696];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/prowlarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "One place for all the sites your apps search${plugin.label}";
              description = ''
                Prowlarr keeps the list of download sites in one place and shares it with Sonarr, Radarr and Lidarr.
                Add or fix a site once and every media app uses it.
              '';
              notes = ''
                Prowlarr's own sign-in is off for visits through Neo, so the Neo login page is the only gate for its web page.
                Its API (/api/ and /<id>/api/, which the other apps search through) skips the Neo login and needs the API key.
                With the media helper on, it adds three public sites (LimeTorrents, The Pirate Bay, YTS) and connects Sonarr, Radarr and Lidarr. Downloading copyrighted material can be illegal where you live: you are responsible for what you add, and the apps send their traffic through your VPN by default.
              '';
              privacy = [];
              projectUrl = "https://prowlarr.com/";
              githubUrl = "https://github.com/Prowlarr/Prowlarr";
              releaseUrl = "https://github.com/Prowlarr/Prowlarr/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/Prowlarr/Prowlarr/blob/develop/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Prowlarr: manages the sites the media apps search";
      };
    };
}
