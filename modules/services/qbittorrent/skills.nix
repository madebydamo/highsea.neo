# Hermes skill for qbittorrent — WebAPI automation.
{...}: {
  neoPlugin.modules.qbittorrent-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "qbittorrent";
    cfg = config.neo.services.${name};
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://${name}.<domain>";
    webPort = toString (cfg.webPort or 8082);
    listenPort = toString (cfg.listenPort or 8342);
  in {
    config.neo.services.${name}.skill.conf = lib.neo.mkServiceSkill {
      service = name;
      inherit config;
      description = "qBittorrent downloads, WebUI API, VPN ports";
      tags = ["neo" "high_sea" "qbittorrent" "torrent" "api"];
      title = "Neo · qBittorrent${plugin.label}";
      body = ''
        ## When to Use

        Transfer state, stuck torrents, categories/paths for *arr, WebAPI automation, VPN listen port.

        ## Architecture notes

        - WebUI port **${webPort}**, torrent listen **${listenPort}** (must be forwarded by the VPN provider and listed in the VPN's input ports).
        - Host unit **${name}-portcheck** dials the listen port from the container/VPN netns every 5m and restarts `docker-${name}` when closed.
        - Sonarr, Radarr, Lidarr, Prowlarr and Listenarr reach `http://${name}:${webPort}` over the plugin's `downloads` Docker link, with the Neo username/password (declarr wires the first four).
        - Edge: tinyauth on the public UI (no API publicPath). `qBittorrent.conf` is rewritten on every start.

        ## Credentials

        - **Neo**: `services.${name}.username` and `services.${name}.password` (a secret; empty = a password Neo generates that only the apps know). Never print or paste it.
        - qBittorrent skips its login for requests from localhost (`WebUI\LocalHostAuth=false`), so call the WebAPI from inside the container:

        ```bash
        # qb PATH [curl args]: WebAPI v2 from inside the container, no login needed
        qb() { p=$1; shift; docker exec -i ${name} curl -fsS "$@" "http://localhost:${webPort}/api/v2/$p"; }
        qb app/version
        ```

        ## WebAPI v2 (agent playbook)

        Docs: https://github.com/qbittorrent/qBittorrent/wiki/WebUI-API-(qBittorrent-4.1)

        | Goal | Request |
        |------|---------|
        | Version | `qb app/version` |
        | Preferences | `qb app/preferences` |
        | Transfer info (connection status, speeds) | `qb transfer/info` |
        | List torrents | `qb torrents/info` |
        | Filter by category | `qb "torrents/info?category=…"` |
        | Torrent properties | `qb "torrents/properties?hash=…"` |
        | Contents / files | `qb "torrents/files?hash=…"` |
        | Stop / start | `qb torrents/stop -d hashes=…` / `qb torrents/start -d hashes=…` |
        | Delete | `qb torrents/delete -d hashes=… -d deleteFiles=false` |
        | Add magnet/url | `qb torrents/add --data-urlencode urls=…` |
        | Categories | `qb torrents/categories` |

        ```bash
        qb transfer/info | jq '{connection_status, dl_info_speed, up_info_speed, dht_nodes}'
        qb torrents/info | jq '[.[] | {name, state, progress, category, dlspeed, upspeed}]'
        ```

        ## Procedures

        1. `systemctl status docker-${name} ${name}-portcheck`
        2. WebAPI transfer/info + torrents list for stuck states (`error`, `missingFiles`, `stalledDL`)
        3. *arr import issues: category/save path must match Sonarr/Radarr remote paths
        4. No peers / port closed → VPN + `journalctl -u ${name}-portcheck` + listen port ${listenPort}

        ## Pitfalls

        - Deleting torrents with `deleteFiles=true` destroys data — confirm with user.
        - The host cannot resolve `${name}`; use `qb` (docker exec).

        ## Verification

        - `qb app/version` prints the version; `qb transfer/info` shows `connection_status` `connected` (not `firewalled`)
        - `journalctl -u ${name}-portcheck` stays quiet when port open; restarts `docker-${name}` when closed
      '';
    };
  };
}
