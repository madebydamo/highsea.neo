# Hermes skill for lidarr — ops + REST API.
{...}: {
  flake.modules.nixos.lidarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.lidarr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://lidarr.<domain>";
  in {
    config.neo.services.lidarr.skill.conf = lib.neo.mkServiceSkill {
      service = "lidarr";
      inherit cfg domain;
      description = "Lidarr music library, queue, search, REST API";
      tags = ["neo" "high_sea" "lidarr" "music" "api"];
      title = "Neo · Lidarr (high_sea)";
      body = ''
        ## When to Use

        Music library (artists/albums), missing releases, queue, search, or Lidarr REST automation.

        ## Architecture notes

        - declarr wires qBittorrent + Prowlarr when enabled; root folder Music → `/music`.
        - Edge: tinyauth UI; **`/api/` + `/ping` publicPaths** for API key clients.
        - API is Servarr-family **`/api/v1`** (Lidarr uses v1, not v3).

        ## Credentials (API)

        - **Neo**: `services.lidarr.apiKey` → `LIDARR__AUTH__APIKEY`
        - Header: **`X-Api-Key`**

        ```bash
        LIDARR_KEY=$(docker exec lidarr printenv LIDARR__AUTH__APIKEY)
        BASE="${publicUrl}"
        H=(-H "X-Api-Key: $LIDARR_KEY" -H "Accept: application/json")
        curl -fsS "''${H[@]}" "$BASE/api/v1/system/status" | jq .
        ```

        ## REST API (agent playbook)

        Docs: https://lidarr.audio/docs/api/ · prefix **`/api/v1`**

        | Goal | Request |
        |------|---------|
        | Status | `GET /api/v1/system/status` |
        | Health | `GET /api/v1/health` |
        | Artists | `GET /api/v1/artist` |
        | Albums | `GET /api/v1/album` |
        | Tracks / files | `GET /api/v1/track`, `GET /api/v1/trackfile` |
        | Queue | `GET /api/v1/queue` |
        | History | `GET /api/v1/history` |
        | Wanted missing | `GET /api/v1/wanted/missing` |
        | Lookup artist | `GET /api/v1/artist/lookup?term=…` |
        | Quality profiles | `GET /api/v1/qualityprofile` |
        | Root folders | `GET /api/v1/rootfolder` |
        | Commands | `POST /api/v1/command` JSON `{"name":"…"}` |

        ```bash
        curl -fsS "''${H[@]}" --get "$BASE/api/v1/artist/lookup" --data-urlencode "term=Radiohead"
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v1/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MissingAlbumSearch"}'
        ```

        ## Procedures

        1. Container health + `system/status`
        2. Queue / wanted missing for backlog
        3. Indexer issues → `/neo-prowlarr`
        4. Download client → `/neo-qbittorrent`

        ## Pitfalls

        - Wrong API version path (`v3` vs `v1`) → 404.
        - Appdata clear destroys library DB.
        - API key rotation needs declarr re-sync for Prowlarr app entry.

        ## Verification

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v1/system/status" | jq -r .version
        curl -fsS "''${H[@]}" "$BASE/api/v1/artist" | jq 'length'
        ```
      '';
    };
  };
}
