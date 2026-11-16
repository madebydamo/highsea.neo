# Deemix service options.
{...}: {
  neoPlugin.modules.deemix-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "deemix";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Save songs and albums from Deezer into your music library${plugin.label}" {rank = 0;};
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
            }
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = ["internal"];
              ports = [6595];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "ghcr.io/bambanah/deemix:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.png;
              tagline = "Download music from Deezer${plugin.label}";
              description = ''
                Search Deezer and save songs, albums and playlists in high quality straight into your music library.
                You need a Deezer account; the files are then yours to play anywhere.
              '';
              notes = ''
                Sign in with your Deezer account on its page (the ARL cookie of your browser session). Treat that value like a password.
                Music is saved under Media/Music, next to what Lidarr downloads. Check that downloading from Deezer is allowed where you live and by your plan.
              '';
              privacy = ["music"];
              projectUrl = "https://github.com/bambanah/deemix";
              githubUrl = "https://github.com/bambanah/deemix";
              releaseUrl = "https://github.com/bambanah/deemix/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/bambanah/deemix/blob/main/LICENSE.txt";
                openSource = false;
                note = "Deemix itself is open source, but it only works with an account at Deezer, a closed streaming service. Lidarr gets music without one.";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Deemix: downloads music from Deezer";
      };
    };
}
