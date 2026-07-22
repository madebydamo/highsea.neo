# Hermes skill for qbittorrent — WebAPI automation.
{...}: {
  flake.modules.nixos.qbittorrent-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.qbittorrent;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://qbittorrent.<domain>";
    webPort = toString (cfg.webPort or 8082);
    listenPort = toString (cfg.listenPort or 8342);
  in {
    config.neo.services.qbittorrent.skill.conf = lib.neo.mkServiceSkill {
      service = "qbittorrent";
      inherit cfg domain;
      description = "qBittorrent downloads, WebUI API, VPN ports";
      tags = ["neo" "high_sea" "qbittorrent" "torrent" "api"];
      title = "Neo · qBittorrent (high_sea)";
      body = ''
        ## When to Use

        Transfer state, stuck torrents, categories/paths for *arr, WebAPI automation, VPN listen port.

        ## Architecture notes

        - WebUI port **${webPort}**, torrent listen **${listenPort}** (gluetun publishes when VPN enabled).
        - Host unit **qbittorrent-portcheck** dials the listen port from the container/VPN netns every 5m and restarts `docker-qbittorrent` when closed.
        - *arr apps talk to `qbittorrent:${webPort}` with Neo username/password (declarr).
        - Edge: tinyauth on public UI (no API publicPath) — WebAPI from Hermes via **cookie login**
          on public URL (after tinyauth is awkward) or **docker-network curl** to the container.

        Prefer in-network WebAPI for agents:

        ```bash
        QBIT=http://qbittorrent:${webPort}
        # If container is on gluetun netns, network name may differ — try:
        # docker inspect qbittorrent --format '{{json .NetworkSettings.Networks}}'
        ```

        ## Credentials

        - **Neo**: `services.qbittorrent.username` / `services.qbittorrent.password`
          (defaults historically `admin` / `adminadmin` — change them).
        - WebAPI uses **session cookie** after `auth/login` (not X-Api-Key).

        ```bash
        # Username on this install (from Neo options); password: services.qbittorrent.password
        QBIT_USER='${cfg.username or "admin"}'
        # Load password from /etc/neo/settings.toml or Neo UI — do not paste into chat
        BASE_INTERNAL="http://qbittorrent:${webPort}"
        ```

        Public URL `${publicUrl}` works for humans through tinyauth; for pure API prefer internal docker network.

        ## WebAPI v2 (agent playbook)

        Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)

        After login, reuse cookie jar (`-b` / `-c`).

        | Goal | Request |
        |------|---------|
        | Version | `GET /api/v2/app/version` |
        | Preferences | `GET /api/v2/app/preferences` |
        | Transfer info | `GET /api/v2/transfer/info` |
        | List torrents | `GET /api/v2/torrents/info` |
        | Filter by category | `GET /api/v2/torrents/info?category=…` |
        | Torrent properties | `GET /api/v2/torrents/properties?hash=` |
        | Contents / files | `GET /api/v2/torrents/files?hash=` |
        | Pause / resume | `POST /api/v2/torrents/pause` `hashes=` |
        | Delete | `POST /api/v2/torrents/delete` `hashes=` `deleteFiles=` |
        | Add magnet/url | `POST /api/v2/torrents/add` `urls=` |
        | Categories | `GET /api/v2/torrents/categories` |

        ```bash
        # After login cookie available as $COOKIE_JAR on a network that can reach qbit:
        curl -fsS -b "$COOKIE_JAR" "$BASE_INTERNAL/api/v2/app/version"
        curl -fsS -b "$COOKIE_JAR" "$BASE_INTERNAL/api/v2/transfer/info" | jq .
        curl -fsS -b "$COOKIE_JAR" "$BASE_INTERNAL/api/v2/torrents/info" \
          | jq '[.[] | {name, state, progress, category, dlspeed, upspeed}]'
        ```

        ### One-shot docker helper pattern

        ```bash
        QBIT_USER=… QBIT_PASS=…  # from Neo settings
        docker run --rm --network internal curlimages/curl:latest \
          -fsS -c /tmp/q.jar -b /tmp/q.jar \
          -d "username=$QBIT_USER&password=$QBIT_PASS" \
          "http://qbittorrent:${webPort}/api/v2/auth/login"
        ```

        (cookie file inside ephemeral container won't persist — chain with `sh -c` multi-step.)

        Better multi-step:

        ```bash
        docker run --rm --network internal curlimages/curl:latest \
          sh -c '
            jar=$(mktemp)
            curl -fsS -c "$jar" -b "$jar" \
              --data-urlencode "username='"$QBIT_USER"'" \
              --data-urlencode "password='"$QBIT_PASS"'" \
              http://qbittorrent:${webPort}/api/v2/auth/login
            curl -fsS -b "$jar" http://qbittorrent:${webPort}/api/v2/torrents/info
          ' | jq '[.[] | {name, state, progress}]'
        ```

        ## Procedures

        1. `systemctl status docker-qbittorrent qbittorrent-portcheck`
        2. WebAPI transfer/info + torrents list for stuck states (`error`, `missingFiles`, `stalledDL`)
        3. *arr import issues: category/save path must match Sonarr/Radarr remote paths
        4. No peers / port closed → VPN + `journalctl -u qbittorrent-portcheck` + listen port ${listenPort}

        ## Pitfalls

        - Default passwords are a security footgun — change via Neo settings + activate.
        - Deleting torrents with `deleteFiles=true` destroys data — confirm with user.
        - Host cannot always resolve `qbittorrent` without docker network join.

        ## Verification

        - Login returns `Ok.`
        - `app/version` prints version string
        - `journalctl -u qbittorrent-portcheck` stays quiet when port open; restarts `docker-qbittorrent` when closed
      '';
    };
  };
}
