# declarr service options (declarative *arr config sync + auto wiring for high_sea stack).
{...}: {
  neoPlugin.modules.declarr-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "declarr";
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      seerrOn = config.neo.services.${plugin.name "seerr"}.enabled or false;
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "Connects your media apps to each other for you${plugin.label}" {rank = 0;};
              # declarr's own state (format database clone): appdata, so
              # snapshots and Clear appdata cover it.
              stateDir = mkOption {
                type = types.str;
                default = "${appdata}/state";
                description = "Folder for declarr's own state";
                internal = true;
              };
              # Deep-merged over the generated declarr config (indexers,
              # quality profiles, …). Format: github.com/upidapi/declarr.
              extraConfig = mkOption {
                type = types.attrs;
                default = {};
                description = "Extra declarr settings for advanced setups, merged over what Neo generates. Leave empty unless you know declarr's format.";
                rank = 20;
                ui = lib.neo.ui.mkUi {
                  label = "Extra declarr settings";
                  group = lib.neo.ui.groups.advanced;
                };
              };
            }
            // lib.neo.mkSystemdUnits ([name] ++ optional seerrOn "${name}-seerr")
            // lib.neo.mkAppdata appdata
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = lib.neo.ui.icons.wrench;
              tagline = "Connects your media apps to each other for you${plugin.label}";
              description = ''
                Sets up Sonarr, Radarr, Lidarr, Prowlarr and Seerr so they work together without clicking through their settings.
                It connects them to qBittorrent and to each other, and adds quality profiles and a few public search sites.
              '';
              notes = ''
                Runs after every start of the apps and after every change of their settings. Changes made by hand to what it manages (download client, quality profiles, indexers, Prowlarr apps) are reset on its next run.
                Seerr is only pre-configured until you finish its setup page.
                It adds the public sites LimeTorrents, The Pirate Bay and YTS. Downloading copyrighted material can be illegal where you live; you are responsible for what is downloaded.
              '';
              projectUrl = "https://github.com/upidapi/declarr";
              githubUrl = "https://github.com/upidapi/declarr";
              releaseUrl = "https://github.com/upidapi/declarr/releases";
              license = {
                spdx = "GPL-3.0-only";
                url = "https://github.com/upidapi/declarr/blob/main/LICENSE";
              };
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "declarr: wires the media apps together";
      };
    };
}
