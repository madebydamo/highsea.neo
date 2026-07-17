# Hermes skill for declarr — declarative *arr stack wiring.
{...}: {
  flake.modules.nixos.declarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.declarr;
    domain = config.neo.services.swag.domain or null;
  in {
    config.neo.services.declarr.skill.conf = lib.neo.mkServiceSkill {
      service = "declarr";
      inherit cfg domain;
      description = "declarr sync for *arr/qbit/seerr wiring";
      tags = ["neo" "high_sea" "declarr" "automation"];
      title = "Neo · declarr (high_sea)";
      body = ''
        ## When to Use

        *arr apps missing download clients, Prowlarr not linked, Seerr without Radarr/Sonarr,
        quality profiles drift, or after rotating API keys.

        ## What it is

        Host **oneshot** systemd units (not a long-running HTTP API):

        - `declarr` — syncs Sonarr/Radarr/Lidarr/Prowlarr (+ qBittorrent client, indexers, apps)
        - `declarr-seerr` — when Seerr enabled; waits for settings.json then syncs Jellyseerr-shaped config

        Generated JSON lives under appdata `declarr/` (`config.json`, `seerr-config.json`).

        ## Architecture notes

        - Reads enabled high_sea services and Neo **apiKey** / qBittorrent user+pass.
        - **declarr itself** talks to *arr over **public HTTPS** (host cannot resolve docker DNS).
        - Inter-container URLs inside *arr config stay as `http://sonarr:8989` etc.
        - Default fallback API key string exists in module only when keys null — production must set real keys.

        ## There is no query REST API

        Operate via systemd + logs + resulting *arr APIs:

        ```bash
        systemctl status declarr declarr-seerr
        systemctl start declarr
        systemctl start declarr-seerr   # if seerr enabled
        journalctl -u declarr -u declarr-seerr -b --no-pager
        ls -la ${
          if (cfg.appdata or null) != null
          then cfg.appdata
          else "/var/neo/DATA/AppData/declarr"
        }
        ```

        Then verify with service APIs:

        - Sonarr/Radarr download clients → `/neo-sonarr` `/neo-radarr`
        - Prowlarr applications → `/neo-prowlarr`
        - Seerr settings radarr/sonarr → `/neo-seerr`

        ## Credentials

        - Uses `services.{sonarr,radarr,lidarr,prowlarr}.apiKey`
        - Uses `services.qbittorrent.username` / `password`
        - Jellyfin: UI user for declarr jellyfin block (see module) — not a Neo API key option

        ## Procedures

        1. Ensure target containers are up
        2. `systemctl start declarr` and read journal for API errors (401 = bad key, TLS = domain)
        3. For Seerr: ensure `settings.json` exists (first start creates it), then `declarr-seerr`
        4. After key rotation: activate Neo → re-run declarr units
        5. Advanced overrides: `services.declarr.extraConfig` deep-merge (settings.toml)

        ## Pitfalls

        - Editing generated JSON by hand is wiped on next activate/preStart.
        - Running declarr while SWAG/domain wrong → connection failures to public URLs.
        - Seerr path only runs full sync when mediaServerType indicates uninitialized setup.

        ## Verification

        - `systemctl is-active declarr` (oneshot RemainAfterExit → active after success)
        - Sonarr `GET /api/v3/downloadclient` shows qBittorrent
        - Prowlarr `GET /api/v1/applications` lists Sonarr/Radarr/Lidarr
      '';
    };
  };
}
