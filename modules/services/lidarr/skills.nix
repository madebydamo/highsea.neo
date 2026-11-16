# Hermes skill for lidarr — ops + REST API.
{...}: {
  neoPlugin.modules.lidarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "lidarr";
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
      description = "Lidarr music library, queue, search, REST API";
      tags = ["neo" "high_sea" "lidarr" "music" "api"];
      title = "Neo · Lidarr${plugin.label}";
      body = ''
        ## When to Use

        Music library (artists/albums), missing releases, queue, search, or Lidarr REST automation.

        ## Architecture notes

        - declarr wires qBittorrent + Prowlarr when enabled; root folder Music → `/music`.
        - Edge: tinyauth UI; **`/api/` + `/ping` publicPaths** for API key clients.
        - API is Servarr-family **`/api/v1`** (Lidarr uses v1, not v3).

        ## Credentials (API)

        - **Neo setting**: `services.${name}.apiKey` (a secret; never print it or paste it into chat).
        - The container gets it as `LIDARR__AUTH__APIKEY`; header **`X-Api-Key`**.
        - Call the API from inside the container, so the key never leaves it:

        ```bash
        # arr URL [curl args]: curl inside ${name} with the API key
        arr() { docker exec -i ${name} sh -c 'exec curl -fsS -H "X-Api-Key: $LIDARR__AUTH__APIKEY" -H "Accept: application/json" -H "Content-Type: application/json" "$@"' _ "$@"; }
        BASE=http://localhost:8686
        arr "$BASE/api/v1/system/status" | jq .
        ```

        Works with the VPN on or off (`docker exec` does not depend on the network).

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
        arr --get "$BASE/api/v1/artist/lookup" --data-urlencode "term=Radiohead"
        arr -X POST "$BASE/api/v1/command" \
          -H "Content-Type: application/json" \
          -d '{"name":"MissingAlbumSearch"}'
        ```

        ## Procedures

        1. Container health + `system/status`
        2. Queue / wanted missing for backlog
        3. Indexer issues → `/neo-${plugin.name "prowlarr"}`
        4. Download client → `/neo-${plugin.name "qbittorrent"}`

        ## Pitfalls

        - Wrong API version path (`v3` vs `v1`) → 404.
        - Appdata clear destroys library DB.
        - API key rotation needs declarr re-sync for Prowlarr app entry.

        ## Verification

        ```bash
        arr "$BASE/api/v1/system/status" | jq -r .version
        arr "$BASE/api/v1/artist" | jq 'length'
        ```
      '';
    };
  };
}
