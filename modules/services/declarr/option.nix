# declarr service options (declarative *arr config sync + auto wiring for high_sea stack).
{...}: {
  flake.modules.nixos.declarr-option = {
    config,
    lib,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.declarr = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "declarr service (auto-config for sonarr/radarr/prowlarr/qbittorrent/jellyfin/jellyseerr etc)" {rank = 0;};
              stateDir = mkOption {
                type = types.str;
                default = "/var/lib/declarr";
                description = "State dir for declarr (format db etc)";
                rank = 10;
              };
              extraConfig = mkOption {
                type = types.attrs;
                default = {};
                description = "Extra raw declarr config to deep-merge (for advanced indexers etc)";
                rank = 20;
              };
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/declarr.svg";
              description = ''
                declarr provides declarative configuration syncing for the *arr stack (sonarr, radarr, prowlarr, jellyfin, and jellyseerr).
                In high_sea it is used to automatically link services together: qbittorrent is wired as the download client for sonarr/radarr/prowlarr, prowlarr registers the *arr apps, jellyfin gets plugins + libraries + repos configured, and jellyseerr (seerr) gets connections to jellyfin + *arr apps. All using stable API keys (for jellyfin: user-created in UI) and container DNS names.
                Runs after the relevant containers are up; config is generated from enabled high_sea services.
              '';
              projectUrl = "https://github.com/upidapi/declarr";
              githubUrl = "https://github.com/upidapi/declarr";
              releaseUrl = "https://github.com/upidapi/declarr/releases";
            };
        };
        default = {};
        description = "declarr service configuration for high_sea *arr auto-config";
      };
    };
}