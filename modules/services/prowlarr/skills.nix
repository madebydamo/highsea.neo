# Hermes skill for prowlarr — indexer manager REST API.
{...}: {
  flake.modules.nixos.prowlarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.prowlarr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://prowlarr.<domain>";
  in {
    config.neo.services.prowlarr.skill.conf = lib.neo.mkServiceSkill {
      service = "prowlarr";
      inherit cfg domain;
      description = "Prowlarr indexers, apps sync, search API";
      tags = ["neo" "high_sea" "prowlarr" "indexers" "api"];
      title = "Neo · Prowlarr (high_sea)";
      body = ''
        ## When to Use

        Indexer failures, app sync (Sonarr/Radarr/Lidarr), FlareSolverr proxy, or Prowlarr API queries.

        ## Architecture notes

        - declarr seeds public indexers, app links to *arr, optional FlareSolverr proxy.
        - Edge: tinyauth UI; publicPaths: **`/api/`**, **`/[id]/api/`** (per-indexer), **`/ping`**.
        - API prefix **`/api/v1`**.

        ## Credentials (API)

        - **Neo**: `services.prowlarr.apiKey` → `PROWLARR__AUTH__APIKEY`
        - Header: **`X-Api-Key`**

        ```bash
        PROWLARR_KEY=$(docker exec prowlarr printenv PROWLARR__AUTH__APIKEY)
        BASE="${publicUrl}"
        H=(-H "X-Api-Key: $PROWLARR_KEY" -H "Accept: application/json")
        curl -fsS "''${H[@]}" "$BASE/api/v1/system/status" | jq .
        ```

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
        curl -fsS "''${H[@]}" "$BASE/api/v1/indexer" | jq '[.[] | {id, name, enable, priority}]'
        curl -fsS "''${H[@]}" "$BASE/api/v1/applications" | jq .
        curl -fsS "''${H[@]}" --get "$BASE/api/v1/search" --data-urlencode "query=ubuntu"
        ```

        ### Sync apps to Sonarr/Radarr/Lidarr

        After adding indexers in UI, use Prowlarr's sync (or declarr `applications` fullSync).
        API: application resources include `syncLevel` and target `apiKey`/`baseUrl`
        (high_sea uses internal URLs like `http://sonarr:8989` for inter-container).

        ## Procedures

        1. `system/status` + `health`
        2. List indexers; test failing ones in UI or API
        3. Cloudflare challenges → FlareSolverr (`/neo-flaresolverr`) + indexerProxy
        4. Apps missing → enable *arr + declarr sync

        ## Pitfalls

        - Indexer credentials are app-managed (not Neo settings) — never invent them.
        - Public demo indexers from declarr may be flaky; expect user-added private trackers.
        - VPN down breaks outbound indexer HTTP.

        ## Verification

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v1/system/status" | jq -r .version
        curl -fsS "''${H[@]}" "$BASE/api/v1/indexer" | jq 'length'
        ```
      '';
    };
  };
}
