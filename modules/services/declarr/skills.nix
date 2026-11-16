# Hermes skill for declarr — declarative *arr stack wiring.
{...}: {
  neoPlugin.modules.declarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "declarr";
    cfg = config.neo.services.${name};
    domain = config.neo.services.swag.domain or null;
  in {
    config.neo.services.${name}.skill.conf = lib.neo.mkServiceSkill {
      service = name;
      inherit config;
      description = "declarr sync for *arr/qbit/seerr wiring";
      tags = ["neo" "high_sea" "declarr" "automation"];
      title = "Neo · declarr${plugin.label}";
      body = ''
        ## When to Use

        *arr apps missing download clients, Prowlarr not linked, Seerr without Radarr/Sonarr,
        quality profiles drift, or after rotating API keys.

        ## What it is

        Host **setup** units (lib.neo.mkSetupService) (not a long-running HTTP API):

        - `declarr` — syncs Sonarr/Radarr/Lidarr/Prowlarr (+ qBittorrent client, indexers, apps)
        - `${name}-seerr` — when Seerr enabled; waits for settings.json then syncs Jellyseerr-shaped config

        The generated JSON holds API keys and passwords: Neo renders it at activation into root-only files (`/run/neo-secrets/rendered/${name}-config.json`, `${name}-seerr-config.json`). Never print them.

        ## Architecture notes

        - Reads enabled high_sea services and Neo **apiKey** / qBittorrent user+pass.
        - **declarr itself** talks to *arr over **public HTTPS** (host cannot resolve docker DNS).
        - Addresses it writes into the apps are container names (`http://${plugin.name "sonarr"}:8989`, `${plugin.name "qbittorrent"}`, `http://${plugin.name "flaresolverr"}:8191/`), reached over the plugin's Docker links.
        - Both units are setup units: they retry until they succeed and show "done"; `${name}` runs again when one of the apps restarts.

        ## There is no query REST API

        Operate via systemd + logs + resulting *arr APIs:

        ```bash
        systemctl status ${name} ${name}-seerr
        systemctl start ${name}
        systemctl start ${name}-seerr   # if seerr enabled
        journalctl -u ${name} -u ${name}-seerr -b --no-pager
        ls -la ${
          if (cfg.appdata or null) != null
          then cfg.appdata
          else "/var/neo/DATA/AppData/declarr"
        }
        ```

        Then verify with service APIs:

        - Sonarr/Radarr download clients → `/neo-${plugin.name "sonarr"}` `/neo-${plugin.name "radarr"}`
        - Prowlarr applications → `/neo-${plugin.name "prowlarr"}`
        - Seerr settings radarr/sonarr → `/neo-${plugin.name "seerr"}`

        ## Credentials

        - Uses `services.{sonarr,radarr,lidarr,prowlarr}.apiKey`
        - Uses `services.${plugin.name "qbittorrent"}.username` / `password`
        - Jellyfin: UI user for declarr jellyfin block (see module) — not a Neo API key option

        ## Procedures

        1. Ensure target containers are up
        2. `systemctl start ${name}` and read journal for API errors (401 = bad key, TLS = domain)
        3. For Seerr: ensure `settings.json` exists (first start creates it), then `${name}-seerr`
        4. After key rotation: activate Neo → re-run declarr units
        5. Advanced overrides: `services.${name}.extraConfig` deep-merge (settings.toml)

        ## Pitfalls

        - Editing generated JSON by hand is wiped on next activate/preStart.
        - Running declarr while SWAG/domain wrong → connection failures to public URLs.
        - *arr host config must include allowedHosts while authenticationRequired is DisabledForLocalAddresses. The module sets each app to its SWAG hostname, docker name, and localhost. A blank value makes the host PUT fail and declarr restart.
        - Seerr path only runs full sync when mediaServerType indicates uninitialized setup.

        ## Verification

        - `systemctl is-active ${name}` (RemainAfterExit → active after success)
        - Sonarr `GET /api/v3/downloadclient` shows qBittorrent
        - Prowlarr `GET /api/v1/applications` lists Sonarr/Radarr/Lidarr
      '';
    };
  };
}
