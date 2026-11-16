# Hermes skill for sonarr — ops + REST API (high leverage for media automation).
{...}: {
  neoPlugin.modules.sonarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "sonarr";
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
      description = "Sonarr TV library, queue, search, REST API";
      tags = ["neo" "high_sea" "sonarr" "media" "api"];
      title = "Neo · Sonarr${plugin.label}";
      body = ''
        ## When to Use

        TV library questions, missing episodes, queue/download failures, manual search,
        quality upgrades, or **any agent automation** against Sonarr's REST API.

        ## Architecture notes

        - high_sea wires download client (qBittorrent) and Prowlarr apps via **declarr** when enabled.
        - VPN option may route the container through gluetun; public URL still goes SWAG → backend.
        - Edge: tinyauth on UI; **`/api/` and `/ping` are on publicPaths** — API key auth only (no tinyauth cookie).
        - Media root inside container: `/tv` → host media `TV` volume.
        - Downloads: `/downloads` shared with qBittorrent when declarr-wired.

        ## Credentials (API)

        - **Neo setting**: `services.${name}.apiKey` (a secret; never print it or paste it into chat).
        - The container gets it as `SONARR__AUTH__APIKEY`; header **`X-Api-Key`**.
        - Call the API from inside the container, so the key never leaves it:

        ```bash
        # arr URL [curl args]: curl inside ${name} with the API key
        arr() { docker exec -i ${name} sh -c 'exec curl -fsS -H "X-Api-Key: $SONARR__AUTH__APIKEY" -H "Accept: application/json" -H "Content-Type: application/json" "$@"' _ "$@"; }
        BASE=http://localhost:8989
        arr "$BASE/api/v3/system/status" | jq .
        ```

        Works with the VPN on or off (`docker exec` does not depend on the network).

        ## REST API (agent playbook)

        Base: `$BASE` inside the container (public: `${publicUrl}`) · API prefix: `/api/v3` · Docs: https://sonarr.tv/docs/api/

        Auth every call:

        ```bash
        arr "$BASE/api/v3/system/status" | jq .
        arr "$BASE/ping"
        ```

        ### High-value read endpoints

        | Goal | Request |
        |------|---------|
        | Health / version | `GET /api/v3/system/status` |
        | Health checks | `GET /api/v3/health` |
        | All series | `GET /api/v3/series` |
        | One series | `GET /api/v3/series/{id}` |
        | Episode files | `GET /api/v3/episodefile?seriesId={id}` |
        | Episodes | `GET /api/v3/episode?seriesId={id}` |
        | Calendar | `GET /api/v3/calendar?start=YYYY-MM-DD&end=YYYY-MM-DD` |
        | Queue | `GET /api/v3/queue` |
        | History | `GET /api/v3/history` |
        | Wanted missing | `GET /api/v3/wanted/missing` |
        | Wanted cutoff | `GET /api/v3/wanted/cutoff` |
        | Quality profiles | `GET /api/v3/qualityprofile` |
        | Root folders | `GET /api/v3/rootfolder` |
        | Download clients | `GET /api/v3/downloadclient` |
        | Indexers | `GET /api/v3/indexer` |
        | Tags | `GET /api/v3/tag` |
        | Disk space | `GET /api/v3/diskspace` |

        ### Search / mutate (confirm destructive ops with user)

        ```bash
        # Lookup series (before add)
        arr --get "$BASE/api/v3/series/lookup" --data-urlencode "term=Breaking Bad"

        # Command: refresh series, rescan, missing search, etc.
        arr -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MissingEpisodeSearch"}'

        # Interactive episode search for one episode id
        arr -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"EpisodeSearch","episodeIds":[123]}'

        # Queue delete (remove from client optional)
        # arr -X DELETE "$BASE/api/v3/queue/{id}?removeFromClient=true&blocklist=false"
        ```

        ### Add series sketch

        Prefer UI for first-time complex adds; API shape:

        ```bash
        # After series/lookup, POST /api/v3/series with qualityProfileId, rootFolderPath (/tv),
        # monitored, seasonFolder, addOptions monitoSearch etc. See OpenAPI for required fields.
        ```

        ## Internal vs public URL

        - **From Hermes (host)**: `arr` above (inside the container), or `${publicUrl}` + `X-Api-Key` (publicPaths bypass tinyauth).
        - **Other apps**: Prowlarr and Bazarr reach `http://${name}:8989` over the plugin's Docker links (indexers, subtitles); qBittorrent is `http://${plugin.name "qbittorrent"}:<webPort>` over the downloads link. declarr and Seerr use the public URL.
        - If public HTTPS fails but container is up: `docker logs ${name} --tail 100` and check SWAG.

        ## Procedures

        1. `systemctl status docker-${name}` + derived cheatsheet
        2. API `system/status` + `health` before deeper diagnosis
        3. Stuck downloads: `queue` + qBittorrent skill (`/neo-${plugin.name "qbittorrent"}`)
        4. No grabs: Prowlarr indexers (`/neo-${plugin.name "prowlarr"}`) + Sonarr `indexer` list
        5. Config drift: if declarr enabled, re-run `systemctl start ${plugin.name "declarr"}` after *arr key/URL changes

        ## Pitfalls

        - Clearing appdata wipes DB/history; media files on volume may remain.
        - Changing `apiKey` in Neo requires activate + declarr re-sync for dependent apps.
        - Do not hand-edit generated declarr JSON as durable source of truth — fix settings + re-sync.
        - VPN/gluetun down → outbound indexer/search fails even if UI loads.

        ## Verification

        ```bash
        arr "$BASE/api/v3/system/status" | jq -r .version
        arr "$BASE/api/v3/series" | jq 'length'
        ```
      '';
    };
  };
}
