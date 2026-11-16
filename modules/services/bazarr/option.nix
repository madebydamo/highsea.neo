# Bazarr service options.
{...}: {
  neoPlugin.modules.bazarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "bazarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Subtitles for your films and shows, downloaded automatically${plugin.label}" {rank = 0;};
              # Written into Bazarr's config.yaml by bazarr-setup; the
              # exporter uses the same key.
              apiKey = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Key scripts and the monitoring use to talk to Bazarr. Changing it takes effect on the next start of Bazarr.";
                helper = lib.neo.helpers.randomToken;
                rank = 5;
                ui = lib.neo.ui.mkUi {label = "API key";};
              };
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
            }
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = [(lib.neo.docker.serviceNetwork name)];
              ports = [6767];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/bazarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Subtitles for your films and shows, automatically${plugin.label}";
              description = ''
                Bazarr finds subtitles in the languages you choose for every film and episode in your library, and keeps looking for missing ones.
              '';
              notes = ''
                Bazarr is reached only through the Neo login page; its API key is for the monitoring exporter and scripts.
                Connect it to Sonarr and Radarr on its Settings page: use the names sonarr and radarr with ports 8989 and 7878 and their API keys.
              '';
              privacy = [];
              projectUrl = "https://www.bazarr.media/";
              githubUrl = "https://github.com/morpheus65535/bazarr";
              releaseUrl = "https://github.com/morpheus65535/bazarr/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/morpheus65535/bazarr/blob/master/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Bazarr: downloads subtitles";
      };
    };
}
