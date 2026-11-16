# Hermes skill for flaresolverr — Cloudflare bypass proxy API.
{...}: {
  neoPlugin.modules.flaresolverr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "flaresolverr";
    cfg = config.neo.services.${name};
    domain = config.neo.services.swag.domain or null;
  in {
    config.neo.services.${name}.skill.conf = lib.neo.mkServiceSkill {
      service = name;
      inherit config;
      description = "FlareSolverr Cloudflare bypass for Prowlarr";
      tags = ["neo" "high_sea" "flaresolverr" "indexers" "api"];
      title = "Neo · FlareSolverr${plugin.label}";
      body = ''
        ## When to Use

        Indexers fail with Cloudflare challenges; Prowlarr indexer proxy debugging.

        ## Architecture notes

        - **No public subdomain**: only Prowlarr reaches it, over the plugin's `cloudflare` Docker link.
        - Listen **8191**; declarr wires Prowlarr's indexer proxy to `http://${name}:8191/`.
        - VPN-routed by default (gluetun answers for its name on its networks).

        ## API (JSON POST)

        Docs: https://github.com/FlareSolverr/FlareSolverr

        From Hermes (host), call it from Prowlarr's container (the only one that may reach it):

        ```bash
        docker exec ${plugin.name "prowlarr"} curl -fsS -X POST "http://${name}:8191/v1" \
          -H "Content-Type: application/json" \
          -d '{"cmd":"request.get","url":"https://example.com","maxTimeout":60000}' | jq .
        ```

        | cmd | Purpose |
        |-----|---------|
        | `request.get` | GET URL through browser challenge solver |
        | `request.post` | POST with `postData` |
        | `sessions.create` / `sessions.destroy` | Optional session reuse |

        Successful response includes `solution.response`, cookies, userAgent.

        Health-style probe: POST with a simple URL; HTTP 500 from FlareSolverr often means browser backend issues.

        ## Procedures

        1. `systemctl status docker-${name}` + logs
        2. POST `/v1` test request
        3. In Prowlarr: Settings → Indexers → proxies → FlareSolverr host
        4. Tag indexers that need CF bypass

        ## Pitfalls

        - Not a general HTTP proxy (CONNECT); only FlareSolverr protocol.
        - Heavy/slow; large maxTimeout required for hard challenges.
        - VPN down → outbound challenge fetch fails.

        ## Verification

        - `/v1` returns `"status": "ok"` for example.com
        - Prowlarr indexer test succeeds for CF-protected indexer
      '';
    };
  };
}
