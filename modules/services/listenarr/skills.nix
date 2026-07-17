# Hermes skill for listenarr — audiobook *arr-style automation.
{...}: {
  flake.modules.nixos.listenarr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.listenarr;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://listenarr.<domain>";
  in {
    config.neo.services.listenarr.skill.conf = lib.neo.mkServiceSkill {
      service = "listenarr";
      inherit cfg domain;
      description = "Listenarr audiobook automation and API";
      tags = ["neo" "high_sea" "listenarr" "audiobooks" "api"];
      title = "Neo · Listenarr (high_sea)";
      body = ''
        ## When to Use

        Audiobook want-list, search/download automation, pairing with Audiobookshelf, API probes.

        ## Architecture notes

        - Config: appdata `listenarr/config` → `/app/config`
        - Media: `/audiobooks`, downloads: `/downloads`
        - Edge: tinyauth; **`/api/` + `/ping` publicPaths** (Servarr-like clients)
        - Image track: canary (`ghcr.io/listenarrs/listenarr:canary`) — APIs may move

        ## Credentials (API)

        - Neo does **not** currently declare a stable `apiKey` option (unlike Sonarr).
        - Create/find API key in Listenarr UI (Settings/General) when available.
        - Try Servarr-style **`X-Api-Key`** first; if 401, check UI docs for Bearer/token scheme.
        - Upstream: https://getlistenarr.com/ / GitHub Listenarrs/Listenarr

        ```bash
        BASE="${publicUrl}"
        H=(-H "X-Api-Key: $LISTENARR_KEY" -H "Accept: application/json")
        curl -fsS "''${H[@]}" "$BASE/ping" || true
        curl -fsS "''${H[@]}" "$BASE/api" -I || true
        # Explore OpenAPI/swagger if the build exposes it:
        curl -fsS "$BASE/swagger" -I || curl -fsS "$BASE/api/docs" -I || true
        ```

        ## Agent approach (version-flexible)

        1. Hit `$BASE/ping` and `$BASE/api` / swagger to discover versioned routes.
        2. Prefer UI for complex library adds until routes confirmed.
        3. For automation: list wanted items, trigger search commands if command API exists.
        4. After downloads land in `/audiobooks`, scan Audiobookshelf (`/neo-audiobookshelf`).

        ## Procedures

        1. Container health + logs
        2. Confirm download client + indexers inside Listenarr settings
        3. Path must match shared downloads volume with torrent client
        4. ABS library scan after import

        ## Pitfalls

        - Canary image → breaking API changes; always probe before scripting.
        - Do not invent API keys; without a Neo option they are app-only.

        ## Verification

        - UI loads after tinyauth
        - `/ping` or health endpoint 200
        - Test search returns results; file appears under audiobooks volume
      '';
    };
  };
}
