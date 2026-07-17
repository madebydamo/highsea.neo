# Hermes skill for seerr — media requests + API (Jellyseerr successor).
{...}: {
  flake.modules.nixos.seerr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.seerr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://seerr.<domain>";
  in {
    config.neo.services.seerr.skill.conf = lib.neo.mkServiceSkill {
      service = "seerr";
      inherit cfg domain;
      description = "Seerr media requests, users, Radarr/Sonarr API";
      tags = ["neo" "high_sea" "seerr" "requests" "api"];
      title = "Neo · Seerr (high_sea)";
      body = ''
        ## When to Use

        Media requests, approvals, Jellyfin/*arr connectivity, notifications, or Seerr REST API.

        ## Architecture notes

        - Image: seerr (merged Jellyseerr/Overseerr line). Config under appdata `seerr/config`.
        - **declarr-seerr** can pre-wire Sonarr/Radarr/Jellyfin when `services.declarr` is enabled.
        - Edge: tinyauth UI; **`/api/` + `/ping` publicPaths** for API key clients.
        - Listens container port **5055**.

        ## Credentials (API)

        - Neo does **not** store Seerr's API key.
        - Create/copy: Seerr → Settings → General → API Key.
        - Also often present in `settings.json` under appdata (do not cat full file into chat).
        - Header: **`X-Api-Key`**

        ```bash
        BASE="${publicUrl}"
        # Operator pastes key once into env/MEMORY, or extract carefully from settings:
        # jq -r '.main.apiKey // .main.apiKey'  is version-dependent — prefer UI copy.
        H=(-H "X-Api-Key: $SEERR_API_KEY" -H "Accept: application/json")
        curl -fsS "''${H[@]}" "$BASE/api/v1/status" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/v1/settings/public" | jq .
        ```

        ## REST API (agent playbook)

        Docs: https://docs.seerr.dev/ · Jellyseerr-compatible `/api/v1/*` surface in most builds.

        | Goal | Request |
        |------|---------|
        | Status | `GET /api/v1/status` |
        | Public settings | `GET /api/v1/settings/public` |
        | Request list | `GET /api/v1/request` |
        | Request by id | `GET /api/v1/request/{id}` |
        | Create request | `POST /api/v1/request` JSON body |
        | Approve / decline | `POST /api/v1/request/{id}/approve` etc. |
        | Media search | `GET /api/v1/search?query=…` |
        | Movie / TV detail | `GET /api/v1/movie/{tmdbId}`, `GET /api/v1/tv/{tmdbId}` |
        | Users | `GET /api/v1/user` |
        | Radarr servers | `GET /api/v1/settings/radarr` |
        | Sonarr servers | `GET /api/v1/settings/sonarr` |
        | Jellyfin settings | `GET /api/v1/settings/jellyfin` |

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v1/request?take=20" | jq .
        curl -fsS "''${H[@]}" --get "$BASE/api/v1/search" --data-urlencode "query=Dune" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/v1/settings/radarr" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/v1/settings/sonarr" | jq .
        ```

        ### Create request (example shape — confirm fields for your version)

        ```bash
        # Movie request by TMDB id (mediaType movie)
        curl -fsS "''${H[@]}" -X POST "$BASE/api/v1/request" \
          -H "Content-Type: application/json" \
          -d '{"mediaType":"movie","mediaId":438631,"is4k":false}'
        ```

        Always confirm with the user before approving mass requests or changing settings.

        ## Procedures

        1. Container health; if first boot, wait for `settings.json` then declarr-seerr
        2. API `status` + list Radarr/Sonarr settings — empty means wizard/declarr incomplete
        3. Request stuck → check Sonarr/Radarr queue skills + Seerr request status
        4. Jellyfin library not visible → Jellyfin API key/user perms in Seerr settings

        ## Pitfalls

        - Appdata clear resets Seerr DB/users/requests.
        - declarr only auto-configures when mediaServerType indicates setup state — see declarr skill.
        - Double login: tinyauth then Seerr user session for UI; API uses API key only.

        ## Verification

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/v1/status" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/v1/settings/radarr" | jq 'length'
        ```
      '';
    };
  };
}
