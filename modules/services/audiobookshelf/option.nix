# Audiobookshelf service options.
{...}: {
  neoPlugin.modules.audiobookshelf-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "audiobookshelf";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Your audiobooks and podcasts on every phone${plugin.label}" {rank = 0;};
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
              # Everything the phone apps call: they cannot pass the Neo login
              # page and sign in with Audiobookshelf's own accounts. The web
              # page itself stays behind the login. Older releases served the
              # same paths under /audiobookshelf/.
              auth.publicPaths = [
                "^(/audiobookshelf)?/api/"
                "^(/audiobookshelf)?/login/?$"
                "^(/audiobookshelf)?/logout/?$"
                "^(/audiobookshelf)?/init/?$"
                "^(/audiobookshelf)?/status/?$"
                "^(/audiobookshelf)?/ping/?$"
                "^(/audiobookshelf)?/auth/"
                "^(/audiobookshelf)?/socket\\.io/"
                "^(/audiobookshelf)?/hls/"
                "^(/audiobookshelf)?/public/"
                "^(/audiobookshelf)?/feed/"
              ];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "ghcr.io/advplyr/audiobookshelf:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Your own Audible for audiobooks and podcasts${plugin.label}";
              description = ''
                Listen to your audiobooks and podcasts in the browser or the phone app, and pick up where you stopped on any device.
                Every person gets their own account, progress and bookshelf.
              '';
              notes = ''
                The first visit creates the admin account. The phone apps sign in with Audiobookshelf accounts; their paths (/api/, /login, /socket.io/, /hls/, /public/, /feed/) skip the Neo login page.
                Books are read from Media/Audiobooks and podcasts from Media/Podcasts.
              '';
              replaces = ["Audible" "Spotify podcasts"];
              privacy = ["audiobooks"];
              projectUrl = "https://www.audiobookshelf.org/";
              githubUrl = "https://github.com/advplyr/audiobookshelf";
              releaseUrl = "https://github.com/advplyr/audiobookshelf/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/advplyr/audiobookshelf/blob/master/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Audiobookshelf: audiobook and podcast server";
      };
    };
}
