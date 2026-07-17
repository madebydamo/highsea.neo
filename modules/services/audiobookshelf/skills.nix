# Hermes skill for audiobookshelf — libraries + REST API.
{...}: {
  flake.modules.nixos.audiobookshelf-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.audiobookshelf;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://audiobookshelf.<domain>";
  in {
    config.neo.services.audiobookshelf.skill.conf = lib.neo.mkServiceSkill {
      service = "audiobookshelf";
      inherit cfg domain;
      description = "Audiobookshelf libraries, podcasts, REST API";
      tags = ["neo" "high_sea" "audiobookshelf" "audiobooks" "api"];
      title = "Neo · Audiobookshelf (high_sea)";
      body = ''
        ## When to Use

        Audiobook/podcast libraries, scans, users, progress, or Audiobookshelf REST API.

        ## Architecture notes

        - Config/metadata under appdata; media: `/audiobooks`, `/podcasts` from media volume.
        - Listens on container port **80**.
        - Edge: tinyauth; **`^/audiobookshelf/api/`** is on publicPaths (API path prefix depends on
          URL base — confirm whether reverse proxy strips paths). Prefer absolute paths under
          `${publicUrl}/api/...` first; if 404, try `${publicUrl}/audiobookshelf/api/...`.

        ## Credentials (API)

        - Neo does not store ABS API tokens.
        - Create: User settings → API token (or admin users panel).
        - Auth: **`Authorization: Bearer <token>`**

        ```bash
        BASE="${publicUrl}"
        H=(-H "Authorization: Bearer $ABS_TOKEN" -H "Accept: application/json")
        ```

        ## REST API (agent playbook)

        Docs: https://api.audiobookshelf.org/

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/status" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/libraries" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/me" | jq .
        ```

        | Goal | Request |
        |------|---------|
        | Server status | `GET /api/status` |
        | Current user | `GET /api/me` |
        | Libraries | `GET /api/libraries` |
        | Library items | `GET /api/libraries/{id}/items` |
        | Item detail | `GET /api/items/{id}` |
        | Search | `GET /api/libraries/{id}/search?q=…` |
        | Scan library | `POST /api/libraries/{id}/scan` |
        | Authors / series | under `/api/libraries/{id}/…` (see OpenAPI) |

        ```bash
        LIB=$(curl -fsS "''${H[@]}" "$BASE/api/libraries" | jq -r '.[0].id // .libraries[0].id')
        curl -fsS "''${H[@]}" "$BASE/api/libraries/$LIB/items?limit=10" | jq .
        curl -fsS "''${H[@]}" -X POST "$BASE/api/libraries/$LIB/scan"
        ```

        Response shapes vary slightly by version — use `jq` exploration; prefer OpenAPI.

        ## Procedures

        1. Container health + logs
        2. API status/me before UI
        3. Missing books → confirm files under media Audiobooks + library path + scan
        4. Pair with Listenarr (`/neo-listenarr`) if automation downloads into `/audiobooks`

        ## Pitfalls

        - Path mismatch between host media folder and library path in ABS.
        - API token is per-user; admin token needed for server-wide ops.

        ## Verification

        ```bash
        curl -fsS "''${H[@]}" "$BASE/api/status" | jq .
        curl -fsS "''${H[@]}" "$BASE/api/libraries" | jq 'length'
        ```
      '';
    };
  };
}
