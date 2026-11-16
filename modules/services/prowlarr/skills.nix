# Hermes skill for prowlarr — indexer manager REST API.
{...}: {
  neoPlugin.modules.prowlarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "prowlarr";
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
      description = "Prowlarr indexers, apps sync, search API";
      tags = ["neo" "high_sea" "prowlarr" "indexers" "api"];
      title = "Neo · Prowlarr${plugin.label}";
      body = ''
        ## When to Use

        Indexer failures, app sync (Sonarr/Radarr/Lidarr), FlareSolverr proxy, or Prowlarr API queries.

        ## Architecture notes

        - declarr seeds public indexers, app links to *arr, optional FlareSolverr proxy.
        - Edge: tinyauth UI; publicPaths: **`/api/`**, **`/[id]/api/`** (per-indexer), **`/ping`**.
        - API prefix **`/api/v1`**.

        ## Credentials (API)

        - **Neo setting**: `services.${name}.apiKey` (a secret; never print it or paste it into chat).
        - The container gets it as `PROWLARR__AUTH__APIKEY`; header **`X-Api-Key`**.
        - Call the API from inside the container, so the key never leaves it:

        ```bash
        # arr URL [curl args]: curl inside ${name} with the API key
        arr() { docker exec -i ${name} sh -c 'exec curl -fsS -H "X-Api-Key: $PROWLARR__AUTH__APIKEY" -H "Accept: application/json" -H "Content-Type: application/json" "$@"' _ "$@"; }
        BASE=http://localhost:9696
        arr "$BASE/api/v1/system/status" | jq .
        ```

        Works with the VPN on or off (`docker exec` does not depend on the network).

        ## REST API (agent playbook)

        Docs: https://prowlarr.com/docs/api/

        | Goal | Request |
        |------|---------|
        | Status | `GET /api/v1/system/status` |
        | Health | `GET /api/v1/health` |
        | Indexers | `GET /api/v1/indexer` |
        | Applications (*arr links) | `GET /api/v1/applications` |
        | Download clients | `GET /api/v1/downloadclient` |
        | Indexer proxies (FlareSolverr) | `GET /api/v1/indexerProxy` |
        | Tags | `GET /api/v1/tag` |
        | Search | `GET /api/v1/search?query=…` |
        | History | `GET /api/v1/history` |
        | Test indexer | `POST /api/v1/indexer/test` (body = indexer resource) |

        ```bash
        arr "$BASE/api/v1/indexer" | jq '[.[] | {id, name, enable, priority}]'
        arr "$BASE/api/v1/applications" | jq .
        arr --get "$BASE/api/v1/search" --data-urlencode "query=ubuntu"
        ```

        ### Sync apps to Sonarr/Radarr/Lidarr

        After adding indexers in UI, use Prowlarr's sync (or declarr `applications` fullSync).
        API: application resources include `syncLevel` and target `apiKey`/`baseUrl`
        (high_sea uses container names like `http://${plugin.name "sonarr"}:8989`, reached over the indexers Docker link).

        ## Procedures

        1. `system/status` + `health`
        2. List indexers; test failing ones in UI or API
        3. Cloudflare challenges → FlareSolverr (`/neo-${plugin.name "flaresolverr"}`) + indexerProxy
        4. Apps missing → enable *arr + declarr sync

        ## Pitfalls

        - Indexer credentials are app-managed (not Neo settings) — never invent them.
        - Public demo indexers from declarr may be flaky; expect user-added private trackers.
        - VPN down breaks outbound indexer HTTP.

        ## Verification

        ```bash
        arr "$BASE/api/v1/system/status" | jq -r .version
        arr "$BASE/api/v1/indexer" | jq 'length'
        ```
      '';
    };
  };
}
