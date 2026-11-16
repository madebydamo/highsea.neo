# Hermes skill for radarr — ops + REST API (high leverage for media automation).
{...}: {
  neoPlugin.modules.radarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "radarr";
    cfg = config.neo.services.${name};
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://${name}.<domain>";
  in {
    config.neo.services.${name}.skill.conf = lib.neo.mkServiceSkill {
      service = name;
      inherit config;
      description = "Radarr movies, queue, search, REST API";
      tags = ["neo" "high_sea" "radarr" "media" "api"];
      title = "Neo · Radarr${plugin.label}";
      body = ''
        ## When to Use

        Movie library, missing/wanted, queue issues, interactive search, quality upgrades,
        or **agent automation** via Radarr REST API.

        ## Architecture notes

        - high_sea + **declarr**: qBittorrent download client, Prowlarr app link, Seerr radarr connection.
        - Edge: tinyauth on UI; **`/api/` + `/ping` publicPaths** → API key only.
        - Container media path: `/movies` · downloads: `/downloads`.

        ## Credentials (API)

        - **Neo setting**: `services.${name}.apiKey` (a secret; never print it or paste it into chat).
        - The container gets it as `RADARR__AUTH__APIKEY`; header **`X-Api-Key`**.
        - Call the API from inside the container, so the key never leaves it:

        ```bash
        # arr URL [curl args]: curl inside ${name} with the API key
        arr() { docker exec -i ${name} sh -c 'exec curl -fsS -H "X-Api-Key: $RADARR__AUTH__APIKEY" -H "Accept: application/json" -H "Content-Type: application/json" "$@"' _ "$@"; }
        BASE=http://localhost:7878
        arr "$BASE/api/v3/system/status" | jq .
        ```

        Works with the VPN on or off (`docker exec` does not depend on the network).

        ## REST API (agent playbook)

        Base: `$BASE` inside the container (public: `${publicUrl}`) · prefix `/api/v3` · Docs: https://radarr.video/docs/api/

        ```bash
        arr "$BASE/api/v3/system/status" | jq .
        arr "$BASE/ping"
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
        arr -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MissingMoviesSearch"}'

        # Search one movie
        arr -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MoviesSearch","movieIds":[1]}'

        # Refresh movie metadata
        arr -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"RefreshMovie","movieIds":[1]}'
        ```

        ## Procedures

        1. Health-check container + `system/status`
        2. Queue stuck → inspect `queue` then qBittorrent
        3. No results → Prowlarr + `indexer` status
        4. After API key change → activate + `systemctl start ${plugin.name "declarr"}` (and seerr path if used)

        ## Pitfalls

        - Appdata wipe destroys movie DB/history.
        - Root folder must be `/movies` for declarr-shaped config.
        - Confirm before mass delete / unmonitor via API.

        ## Verification

        ```bash
        arr "$BASE/api/v3/system/status" | jq -r .version
        arr "$BASE/api/v3/movie" | jq 'length'
        ```
      '';
    };
  };
}
