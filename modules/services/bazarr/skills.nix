# Hermes skill for bazarr — subtitle automation + API.
{...}: {
  flake.modules.nixos.bazarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.bazarr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://bazarr.<domain>";
  in {
    config.neo.services.bazarr.skill.conf = lib.neo.mkServiceSkill {
      service = "bazarr";
      inherit cfg domain;
      description = "Bazarr subtitles for Sonarr/Radarr, API";
      tags = ["neo" "high_sea" "bazarr" "subtitles" "api"];
      title = "Neo · Bazarr (high_sea)";
      body = ''
        ## When to Use

        Missing subtitles, provider failures, Sonarr/Radarr path mapping, or Bazarr API.

        ## Architecture notes

        - Mounts `/tv`, `/movies`, `/downloads` from high_sea media/download volumes.
        - Must point at Sonarr/Radarr instances (API keys + URLs) inside Bazarr settings.
        - Edge: tinyauth on UI. **No `/api/` publicPath by default** — external API calls
          through SWAG may hit tinyauth unless you add publicPaths or use cookie auth.
        - Prefer **in-network** access from Hermes when automating:

        ```bash
        # Reach bazarr on docker network (name: bazarr, port 6767)
        docker run --rm --network internal curlimages/curl:latest \
          -fsS -H "X-API-KEY: $BAZARR_KEY" "http://bazarr:6767/api/system/status"
        ```

        If VPN netns is used, the service may share gluetun's network — then use
        public URL after logging through tinyauth, or `docker exec` diagnostics.

        ## Credentials (API)

        - **Neo**: `services.bazarr.apiKey` → env `BAZARR__AUTH__APIKEY`
        - Header: **`X-API-KEY`** (Bazarr spelling; also try `X-Api-Key` if one fails)
        - Sonarr/Radarr keys used *by* Bazarr are configured in Bazarr UI (or future declarr), not separate Neo options.

        ```bash
        BAZARR_KEY=$(docker exec bazarr printenv BAZARR__AUTH__APIKEY)
        BASE="${publicUrl}"
        ```

        ## REST API (agent playbook)

        Docs: https://bazarr.media/ — API browser often at `$BASE/api` when authenticated.
        Common patterns (version may vary; probe with system status first):

        | Goal | Request |
        |------|---------|
        | System | `GET /api/system/status` or `/api/system` |
        | Series (from Sonarr) | `GET /api/series` |
        | Movies (from Radarr) | `GET /api/movies` |
        | Episodes wanted | `GET /api/episodes` / wanted endpoints in API UI |
        | Providers | `GET /api/providers` (if exposed) |
        | History | `GET /api/history` |
        | Wanted | `GET /api/episodes/wanted`, `GET /api/movies/wanted` |

        ```bash
        # Prefer internal curl when public path is auth-walled:
        KEY=$(docker exec bazarr printenv BAZARR__AUTH__APIKEY)
        docker run --rm --network internal curlimages/curl:latest \
          -fsS -H "X-API-KEY: $KEY" "http://bazarr:6767/api/system/statuses" || \
        docker run --rm --network internal curlimages/curl:latest \
          -fsS -H "X-API-KEY: $KEY" "http://bazarr:6767/api/system/status"
        ```

        Open the Swagger/redoc in the Bazarr UI for exact paths on the installed version.

        ## Procedures

        1. Container health + logs
        2. Confirm Sonarr/Radarr connectivity in Bazarr Settings → Sonarr/Radarr
        3. Provider API keys (OpenSubtitles etc.) are app-managed
        4. Path mapping must match `/tv` and `/movies` container mounts

        ## Pitfalls

        - Public HTTPS API without publicPaths → tinyauth 401/redirect (not a bad Bazarr key).
        - Sonarr/Radarr auth changes break Bazarr until reconfigured.
        - Subtitle providers rate-limit; don't hammer search APIs.

        ## Verification

        - UI lists series/movies synced from *arr
        - Manual subtitle search succeeds for one episode
        - API status returns 200 with API key (internal or public)
      '';
    };
  };
}
