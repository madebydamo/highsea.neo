# Tdarr service options.
{...}: {
  neoPlugin.modules.tdarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "tdarr";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Shrinks and converts your video library in the background${plugin.label}" {rank = 0;};
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
            }
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = ["internal"];
              ports = [8265];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "ghcr.io/haveagitgat/tdarr:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Shrinks and converts your video library automatically${plugin.label}";
              description = ''
                Tdarr goes through your films and shows and converts them to formats that take less space or play on more devices.
                You set the rules once and it works through the library in the background.
              '';
              notes = ''
                Tdarr's own sign-in is off, so the Neo login page is the only gate. It runs one worker inside the same container; remote workers cannot connect.
                It works on the files under Media in place: try your rules on a copy first. Conversions use the graphics chip of the server when it has one.
              '';
              projectUrl = "https://tdarr.io/";
              githubUrl = "https://github.com/HaveAGitGat/Tdarr";
              releaseUrl = "https://github.com/HaveAGitGat/Tdarr/releases";
              license = {
                spdx = "LicenseRef-Proprietary";
                url = "https://docs.tdarr.io/";
                openSource = false;
                note = "Tdarr's server and worker are closed source (free with paid extras); only plugins and docs are public. For a fully open setup, convert files with HandBrake or FFmpeg instead.";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Tdarr: converts your video library";
      };
    };
}
