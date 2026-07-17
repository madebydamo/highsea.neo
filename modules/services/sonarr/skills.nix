# Hermes skill for sonarr — ops + REST API (high leverage for media automation).
{...}: {
  flake.modules.nixos.sonarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.sonarr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://sonarr.<domain>";
  in {
    config.neo.services.sonarr.skill.conf = lib.neo.mkServiceSkill {
      service = "sonarr";
      inherit cfg domain;
      description = "Sonarr TV library, queue, search, REST API";
      tags = ["neo" "high_sea" "sonarr" "media" "api"];
      title = "Neo · Sonarr (high_sea)";
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

        - **Neo setting**: `services.sonarr.apiKey` (required when enabled; randomToken helper).
        - Injected as env `SONARR__AUTH__APIKEY` into the container.
        - Auth method: header **`X-Api-Key`** (also works as query `?apikey=` — prefer header).
        - Do **not** invent keys. Load from settings; avoid pasting full keys into chat.

        ### Load API key (Hermes terminal)

        ```bash
        # Most reliable on the running host (never echo the key into chat):
        SONARR_KEY=$(docker exec sonarr printenv SONARR__AUTH__APIKEY)
        BASE="${publicUrl}"
        # Alternatives: Neo UI → sonarr → apiKey, or services.sonarr.apiKey in /etc/neo/settings.toml
        ```

        ## REST API (agent playbook)

        Base: `${publicUrl}` · API prefix: `/api/v3` · Docs: https://sonarr.tv/docs/api/

        Auth every call:

        ```bash
        H=(-H "X-Api-Key: $SONARR_KEY" -H "Accept: application/json")
        curl -fsS "''${H[@]}" "$BASE/api/v3/system/status" | jq .
        curl -fsS "''${H[@]}" "$BASE/ping"
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
        curl -fsS "''${H[@]}" --get "$BASE/api/v3/series/lookup" --data-urlencode "term=Breaking Bad"

        # Command: refresh series, rescan, missing search, etc.
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MissingEpisodeSearch"}'

        # Interactive episode search for one episode id
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v3/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"EpisodeSearch","episodeIds":[123]}'

        # Queue delete (remove from client optional)
        # curl -fsS "''${H[@]}" -X DELETE "$BASE/api/v3/queue/{id}?removeFromClient=true&blocklist=false"
        ```

        ### Add series sketch

        Prefer UI for first-time complex adds; API shape:

        ```bash
        # After series/lookup, POST /api/v3/series with qualityProfileId, rootFolderPath (/tv),
        # monitored, seasonFolder, addOptions monitoSearch etc. See OpenAPI for required fields.
        ```

        ## Internal vs public URL

        - **From Hermes (host)**: use `${publicUrl}` + `X-Api-Key` (publicPaths bypass tinyauth).
        - **Container-to-container** (declarr/prowlarr): `http://sonarr:8989` on docker network.
        - If public HTTPS fails but container is up: `docker logs sonarr --tail 100` and check SWAG.

        ## Procedures

        1. `systemctl status docker-sonarr` + derived cheatsheet
        2. API `system/status` + `health` before deeper diagnosis
        3. Stuck downloads: `queue` + qBittorrent skill (`/neo-qbittorrent`)
        4. No grabs: Prowlarr indexers (`/neo-prowlarr`) + Sonarr `indexer` list
        5. Config drift: if declarr enabled, re-run `systemctl start declarr` after *arr key/URL changes

        ## Pitfalls

        - Clearing appdata wipes DB/history; media files on volume may remain.
        - Changing `apiKey` in Neo requires activate + declarr re-sync for dependent apps.
        - Do not hand-edit generated declarr JSON as durable source of truth — fix settings + re-sync.
        - VPN/gluetun down → outbound indexer/search fails even if UI loads.

        ## Verification

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v3/system/status" | jq -r .version
        curl -fsS "''${H[@]}" "$BASE/api/v3/series" | jq 'length'
        ```
      '';
    };
  };
}
