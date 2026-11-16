# Jellyfin service options.
{...}: {
  neoPlugin.modules.jellyfin-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "jellyfin";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Your films, shows and music, streamed to every screen${plugin.label}" {rank = 0;};
            }
            # Jellyfin has its own accounts and its apps cannot pass the Neo login.
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
              auth.available = false;
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/jellyfin:latest";
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Your own Netflix for the films and shows you own${plugin.label}";
              description = ''
                Watch your films, shows and music on the TV, phone or browser, at home or away.
                Jellyfin remembers where everyone stopped and shows covers, descriptions and subtitles, like a streaming service for your own library.
              '';
              notes = ''
                Jellyfin has its own accounts: the first visit creates the admin account. It is not behind the Neo login page, so its apps can connect.
                It reads everything under Media and converts videos with the graphics chip of the server when the device cannot play them directly.
                Devices on your home network do not find it on their own (no DLNA or auto-discovery); enter the address in the app.
              '';
              replaces = ["Netflix" "Plex"];
              privacy = ["movies-tv"];
              projectUrl = "https://jellyfin.org/";
              githubUrl = "https://github.com/jellyfin/jellyfin";
              releaseUrl = "https://github.com/jellyfin/jellyfin/releases";
              license = {
                spdx = "GPL-2.0-only";
                url = "https://github.com/jellyfin/jellyfin/blob/master/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "Jellyfin: streams your media library";
      };
    };
}
