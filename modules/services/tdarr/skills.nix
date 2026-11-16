# Hermes skill for tdarr — transcoding library automation.
{...}: {
  neoPlugin.modules.tdarr-skills = {
    config,
    lib,
    plugin,
    ...
  }: let
    name = plugin.name "tdarr";
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
      description = "Tdarr transcode queues, libraries, node API";
      tags = ["neo" "high_sea" "tdarr" "transcode" "api"];
      title = "Neo · Tdarr${plugin.label}";
      body = ''
        ## When to Use

        Library transcode/remux jobs, node health, plugin stacks, GPU/`/dev/dri` issues.

        ## Architecture notes

        - Web UI port **8265**, server **8266** (see container env).
        - `internalNode = true` — server runs a local node in-container.
        - Media mounted at `/media`; cache `/temp`.
        - Module sets `auth = "false"` for the container (edge tinyauth still gates public UI).
        - No `/api/` publicPath: call it from SWAG's container, which sits on Tdarr's network.

        ```bash
        # Web UI base
        BASE="${publicUrl}"
        # Internal API-ish endpoints often on server port 8266
        docker exec swag curl -fsS "http://${name}:8265/api/v2/status" || true
        ```

        ## API notes

        Tdarr exposes HTTP APIs used by the UI (versioned under `/api/v2/…` on many builds).
        Exact routes change; discover:

        ```bash
        # Common probes
        for p in \
          "http://${name}:8265/api/v2/status" \
          "http://${name}:8266/api/v2/status" \
          "http://${name}:8265/api/v2/cruddb" \
          ; do
          docker exec swag curl -fsS -o /dev/null -w "%{http_code} $p\n" "$p" || echo "fail $p"
        done
        ```

        Docs/community: https://tdarr.io/docs/ · GitHub HaveAGitGat/Tdarr

        Typical agent tasks via UI or confirmed API:

        - List libraries / queue / successful-transcode stats
        - Pause/resume node
        - Trigger library scan / requeue failures

        Prefer **read-only** API exploration; mass re-queue can burn CPU/GPU for days — confirm with user.

        ## Procedures

        1. `systemctl status docker-${name}` + logs
        2. UI: nodes online, library paths under `/media/...`
        3. HW transcode failures → `ls -l /dev/dri`, container devices, ffmpeg logs
        4. Disk: cache `/tmp/${name}-cache` on host; free space matters

        ## Pitfalls

        - Transcoding rewrites media — confirm codecs/plugins before large libraries.
        - Clearing appdata loses libraries/history; media files may already be replaced.
        - VPN path can add fragility for UI; media IO is local mounts.

        ## Verification

        - UI shows node online
        - One test file transcodes successfully
        - Status endpoint returns 200 on internal port when available
      '';
    };
  };
}
