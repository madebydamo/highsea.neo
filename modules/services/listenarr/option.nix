# Listenarr service options.
{...}: {
  neoPlugin.modules.listenarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "listenarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Audiobooks you want, downloaded automatically${plugin.label}" {rank = 0;};
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
              networks = ["internal"];
              ports = [4545];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "ghcr.io/listenarrs/listenarr:canary";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Gets the audiobooks you want automatically${plugin.label}";
              description = ''
                Pick the audiobooks you want and Listenarr finds, downloads and files them, using book details from Audible and other sources.
                Finished books land in your audiobook library, ready for Audiobookshelf.
              '';
              notes = ''
                Its web page is behind the Neo login page; its API (/api/) skips it and needs Listenarr's own API key.
                Connect qBittorrent on its settings page (host qbittorrent, the qBittorrent port and password). Books are saved under Media/Audiobooks.
                Runs the project's preview (canary) release, which can change without notice.
              '';
              privacy = ["audiobooks"];
              projectUrl = "https://getlistenarr.com/";
              githubUrl = "https://github.com/Listenarrs/Listenarr";
              releaseUrl = "https://github.com/Listenarrs/Listenarr/releases";
              license = {
                spdx = "AGPL-3.0-only";
                url = "https://github.com/Listenarrs/Listenarr/blob/canary/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Listenarr: downloads audiobooks";
      };
    };
}
