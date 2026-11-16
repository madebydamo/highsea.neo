# Lidarr service options.
{...}: {
  neoPlugin.modules.lidarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "lidarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Albums of the artists you like, downloaded automatically${plugin.label}" {rank = 0;};
              # Reaches the container as LIDARR__AUTH__APIKEY; declarr and the
              # exporter use the same key.
              apiKey = lib.neo.mkSecretOption {
                type = types.nullOr types.str;
                default = null;
                description = "Key the other media apps use to talk to Lidarr. Changing it is passed on to apps the media helper connects; apps you connected by hand need the new key.";
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
              ports = [8686];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/lidarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Keeps your music collection complete${plugin.label}";
              description = ''
                Follow your favourite artists and Lidarr finds, downloads and files their albums, including new releases.
                Your music library then plays in Jellyfin or any music app that reads a folder, without a streaming subscription.
              '';
              notes = ''
                Lidarr's own sign-in is off for visits through Neo, so the Neo login page is the only gate for its web page.
                Its API (/api/, used by Prowlarr and other apps) skips the Neo login and needs the API key.
                Music is saved under Media/Music, downloads go through qBittorrent into Downloads.
                With the media helper on, the download client and root folder are set up for you.
              '';
              privacy = ["music"];
              projectUrl = "https://lidarr.audio/";
              githubUrl = "https://github.com/Lidarr/Lidarr";
              releaseUrl = "https://github.com/Lidarr/Lidarr/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/Lidarr/Lidarr/blob/develop/LICENSE.md";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Lidarr: downloads the music of artists you follow";
      };
    };
}
