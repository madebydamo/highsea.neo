# Hermes skill for flaresolverr — Cloudflare bypass proxy API.
{...}: {
  flake.modules.nixos.flaresolverr-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.flaresolverr;
    domain = config.neo.services.swag.domain or null;
  in {
    config.neo.services.flaresolverr.skill.conf = lib.neo.mkServiceSkill {
      service = "flaresolverr";
      inherit cfg domain;
      description = "FlareSolverr Cloudflare bypass for Prowlarr";
      tags = ["neo" "high_sea" "flaresolverr" "indexers" "api"];
      title = "Neo · FlareSolverr (high_sea)";
      body = ''
        ## When to Use

        Indexers fail with Cloudflare challenges; Prowlarr indexer proxy debugging.

        ## Architecture notes

        - **No public subdomain** by default — internal only for Prowlarr.
        - Listen **8191**; declarr wires Prowlarr indexerProxy to `http://flaresolverr:8191/`.
        - Often on VPN network with other download stack containers.

        ## API (JSON POST)

        Docs: https://github.com/FlareSolverr/FlareSolverr

        From Hermes (host), use docker network:

        ```bash
        docker run --rm --network internal curlimages/curl:latest \
          -fsS -X POST "http://flaresolverr:8191/v1" \
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

        1. `systemctl status docker-flaresolverr` + logs
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
