# Hermes skill for bazarr — subtitle automation + API.
{...}: {
  neoPlugin.modules.bazarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "bazarr";
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
      description = "Bazarr subtitles for Sonarr/Radarr, API";
      tags = ["neo" "high_sea" "bazarr" "subtitles" "api"];
      title = "Neo · Bazarr${plugin.label}";
      body = ''
        ## When to Use

        Missing subtitles, provider failures, Sonarr/Radarr path mapping, or Bazarr API.

        ## Architecture notes

        - Mounts `/tv`, `/movies`, `/downloads` from high_sea media/download volumes.
        - Talks to Sonarr/Radarr at `http://${plugin.name "sonarr"}:8989` / `http://${plugin.name "radarr"}:7878` over the plugin's subtitles Docker link.
        - Edge: tinyauth on the whole site (no publicPaths): call the API from inside the container.

        ## Credentials (API)

        - **Neo**: `services.${name}.apiKey` (a secret; never print it or paste it into chat). Bazarr reads it from its `config/config.yaml` (`auth.apikey`).
        - Header: **`X-API-KEY`**

        ```bash
        # bz URL [curl args]: curl inside ${name}, key read there from config.yaml
        bz() { docker exec -i ${name} sh -c 'k=$(sed -n "/^auth:/,/^[^ ]/s/^  apikey: *//p" /config/config/config.yaml | tr -d "\\042\\047"); exec curl -fsS -H "X-API-KEY: $k" "$@"' _ "$@"; }
        BASE=http://localhost:6767
        bz "$BASE/api/system/status" | jq .
        ```

        ## REST API (agent playbook)

        Docs: https://bazarr.media/ — API browser at `/api` in the UI.
        Common patterns (version may vary; probe with system status first):

        | Goal | Request |
        |------|---------|
        | System | `GET /api/system/status` |
        | Health | `GET /api/system/health` |
        | Series (from Sonarr) | `GET /api/series` |
        | Movies (from Radarr) | `GET /api/movies` |
        | History | `GET /api/history/stats` |
        | Wanted | `GET /api/episodes/wanted`, `GET /api/movies/wanted` |

        Open the Swagger/redoc in the Bazarr UI for exact paths on the installed version.

        ## Procedures

        1. Container health + logs
        2. Confirm Sonarr/Radarr connectivity in Bazarr Settings → Sonarr/Radarr
        3. Provider API keys (OpenSubtitles etc.) are app-managed
        4. Path mapping must match `/tv` and `/movies` container mounts

        ## Pitfalls

        - The public URL answers API calls with the Neo login page (tinyauth), not a bad Bazarr key: use `bz`.
        - Sonarr/Radarr auth changes break Bazarr until reconfigured.
        - Subtitle providers rate-limit; don't hammer search APIs.

        ## Verification

        - UI lists series/movies synced from *arr
        - Manual subtitle search succeeds for one episode
        - `bz "$BASE/api/system/status"` returns 200
      '';
    };
  };
}
