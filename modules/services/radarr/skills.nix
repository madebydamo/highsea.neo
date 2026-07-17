# Hermes skill for radarr — ops + REST API (high leverage for media automation).
{...}: {
  flake.modules.nixos.radarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.radarr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://radarr.<domain>";
  in {
    config.neo.services.radarr.skill.conf = lib.neo.mkServiceSkill {
      service = "radarr";
      inherit cfg domain;
      description = "Radarr movies, queue, search, REST API";
      tags = ["neo" "high_sea" "radarr" "media" "api"];
      title = "Neo · Radarr (high_sea)";
      body = ''
        ## When to Use

        Movie library, missing/wanted, queue issues, interactive search, quality upgrades,
        or **agent automation** via Radarr REST API.

        ## Architecture notes

        - high_sea + **declarr**: qBittorrent download client, Prowlarr app link, Seerr radarr connection.
        - Edge: tinyauth on UI; **`/api/` + `/ping` publicPaths** → API key only.
        - Container media path: `/movies` · downloads: `/downloads`.

        ## Credentials (API)

        - **Neo**: `services.radarr.apiKey` → env `RADARR__AUTH__APIKEY`
        - Header: **`X-Api-Key`**
        - Load key (do not dump into chat):

        ```bash
        RADARR_KEY=$(docker exec radarr printenv RADARR__AUTH__APIKEY)
        BASE="${publicUrl}"
        H=(-H "X-Api-Key: $RADARR_KEY" -H "Accept: application/json")
        ```

        Or from `/etc/neo/settings.toml` → `services.radarr.apiKey`.

        ## REST API (agent playbook)

        Base: `${publicUrl}` · prefix `/api/v3` · Docs: https://radarr.video/docs/api/

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v3/system/status" | jq .
        curl -fsS "''${H[@]}" "$BASE/ping"
        ```

        ### High-value endpoints

        | Goal | Request |
        |------|---------|
        | Status | `GET /api/v3/system/status` |
        | Health | `GET /api/v3/health` |
        | Movies | `GET /api/v3/movie` |
        | One movie | `GET /api/v3/movie/{id}` |
        | Lookup | `GET /api/v3/movie/lookup?term=…` |
        | TMDB lookup | `GET /api/v3/movie/lookup/tmdb?tmdbId=…` |
        | Queue | `GET /api/v3/queue` |
        | History | `GET /api/v3/history` |
        | Wanted missing | `GET /api/v3/wanted/missing` |
        | Wanted cutoff | `GET /api/v3/wanted/cutoff` |
        | Calendar | `GET /api/v3/calendar?start=&end=` |
        | Quality profiles | `GET /api/v3/qualityprofile` |
        | Root folders | `GET /api/v3/rootfolder` |
        | Download clients | `GET /api/v3/downloadclient` |
        | Indexers | `GET /api/v3/indexer` |
        | Disk space | `GET /api/v3/diskspace` |

        ### Commands

        ```bash
        # Missing movies search
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MissingMoviesSearch"}'

        # Search one movie
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MoviesSearch","movieIds":[1]}'

        # Refresh movie metadata
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"RefreshMovie","movieIds":[1]}'
        ```

        ## Procedures

        1. Health-check container + `system/status`
        2. Queue stuck → inspect `queue` then qBittorrent
        3. No results → Prowlarr + `indexer` status
        4. After API key change → activate + `systemctl start declarr` (and seerr path if used)

        ## Pitfalls

        - Appdata wipe destroys movie DB/history.
        - Root folder must be `/movies` for declarr-shaped config.
        - Confirm before mass delete / unmonitor via API.

        ## Verification

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v3/system/status" | jq -r .version
        curl -fsS "''${H[@]}" "$BASE/api/v3/movie" | jq 'length'
        ```
      '';
    };
  };
}
