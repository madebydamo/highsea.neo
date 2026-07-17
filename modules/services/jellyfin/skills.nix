# Hermes skill for jellyfin — library + REST API (Emby-compatible).
{...}: {
  flake.modules.nixos.jellyfin-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.jellyfin;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://jellyfin.<domain>";
  in {
    config.neo.services.jellyfin.skill.conf = lib.neo.mkServiceSkill {
      service = "jellyfin";
      inherit cfg domain;
      description = "Jellyfin media server, users, library, REST API";
      tags = ["neo" "high_sea" "jellyfin" "media" "api"];
      title = "Neo · Jellyfin (high_sea)";
      body = ''
        ## When to Use

        Playback issues, library scans, users/plugins, hardware transcode, or **Jellyfin REST API**
        (clients, Seerr, automation).

        ## Architecture notes

        - Container uses **host network** (not only `internal`) for discovery/DLNA-friendly binding.
        - Media: host media volume → `/media` in container (see Live config / Neo volumes).
        - **tinyauth disabled** for this service (`auth.available = false`) — Jellyfin owns auth for clients.
        - declarr can configure plugins/libraries when enabled (Jellyfin user API key still app-created).
        - `/dev/dri` mounted for HW encode when available.

        ## Credentials (API)

        - Neo does **not** store a Jellyfin API key.
        - Create: Dashboard → Administration → API Keys (or user → profile).
        - Auth headers (either style works on modern Jellyfin):

        ```bash
        BASE="${publicUrl}"
        # Preferred modern:
        AUTH=(-H "Authorization: MediaBrowser Token=$JELLYFIN_API_KEY")
        # Also widely supported:
        # AUTH=(-H "X-Emby-Token: $JELLYFIN_API_KEY")
        ```

        Persist the key in Hermes MEMORY (not chat) if the operator approves automation.

        ## REST API (agent playbook)

        Docs: https://api.jellyfin.org/ · OpenAPI often at `$BASE/api-docs/openapi.json`

        ```bash
        curl -fsS "''${AUTH[@]}" "$BASE/System/Info/Public" | jq .
        curl -fsS "''${AUTH[@]}" "$BASE/System/Info" | jq .
        curl -fsS "''${AUTH[@]}" "$BASE/Users" | jq '[.[] | {Id, Name}]'
        curl -fsS "''${AUTH[@]}" "$BASE/Library/VirtualFolders" | jq .
        curl -fsS "''${AUTH[@]}" "$BASE/Items/Counts" | jq .
        ```

        ### High-value endpoints

        | Goal | Request |
        |------|---------|
        | Public info (no auth) | `GET /System/Info/Public` |
        | System info | `GET /System/Info` |
        | Users | `GET /Users` |
        | Libraries | `GET /Library/VirtualFolders` |
        | Item counts | `GET /Items/Counts` |
        | Search | `GET /Items?searchTerm=…&Recursive=true` |
        | Sessions | `GET /Sessions` |
        | Scheduled tasks | `GET /ScheduledTasks` |
        | Start library scan | `POST /Library/Refresh` |
        | Restart | `POST /System/Restart` (admin; confirm first) |

        ```bash
        # Search movies/shows
        curl -fsS "''${AUTH[@]}" --get "$BASE/Items" \
          --data-urlencode "searchTerm=Dune" \
          --data-urlencode "Recursive=true" \
          --data-urlencode "IncludeItemTypes=Movie,Series" \
          | jq '.Items[] | {Name, Type, Id}'

        # Trigger library scan
        curl -fsS "''${AUTH[@]}" -X POST "$BASE/Library/Refresh"
        ```

        ### User-scoped requests

        Many item queries need `UserId`:

        ```bash
        USER_ID=$(curl -fsS "''${AUTH[@]}" "$BASE/Users" | jq -r '.[0].Id')
        curl -fsS "''${AUTH[@]}" "$BASE/Users/$USER_ID/Items?Recursive=true&IncludeItemTypes=Movie&Limit=5" | jq .
        ```

        ## Procedures

        1. `systemctl status docker-jellyfin` + `docker logs jellyfin --tail 100`
        2. API `System/Info` before UI deep-dives
        3. Playback/transcode: check Sessions + `/dev/dri` + logs for ffmpeg errors
        4. Empty libraries: path under `/media/...` must match VirtualFolders
        5. Seerr integration: Seerr needs Jellyfin URL + admin credentials/API (see `/neo-seerr`)

        ## Pitfalls

        - Host networking → port conflicts if something else binds Jellyfin's ports.
        - Clearing appdata loses users/config; media on volume remains.
        - Never invent admin passwords; reset via official Jellyfin recovery if locked out.

        ## Verification

        ```bash
        curl -fsS "$BASE/System/Info/Public" | jq -r .ServerName
        curl -fsS "''${AUTH[@]}" "$BASE/System/Info" | jq -r .Version
        ```
      '';
    };
  };
}
