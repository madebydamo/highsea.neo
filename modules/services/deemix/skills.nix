# Hermes skill for deemix — Deezer downloader UI.
{...}: {
  flake.modules.nixos.deemix-skills = {
    config,
    lib,
    ...
  }: let
    cfg = config.neo.services.deemix;
    domain = config.neo.services.swag.domain or null;
    publicUrl =
      if domain != null && domain != "" && (cfg.subdomain or null) != null
      then "https://${cfg.subdomain}.${domain}"
      else "https://deemix.<domain>";
  in {
    config.neo.services.deemix.skill.conf = lib.neo.mkServiceSkill {
      service = "deemix";
      inherit cfg domain;
      description = "Deemix Deezer downloads to music library";
      tags = ["neo" "high_sea" "deemix" "music"];
      title = "Neo · Deemix (high_sea)";
      body = ''
        ## When to Use

        Manual Deezer downloads into the music library, ARL/login issues, download path problems.

        ## Architecture notes

        - Web UI port **6595**; music dir `/downloads` → media `Music` volume.
        - `DEEMIX_SINGLE_USER=true`.
        - Often behind VPN (outbound to Deezer).
        - Edge tinyauth; limited first-class public API compared to *arr.

        Public URL: `${publicUrl}`

        ## Credentials

        - Deezer **ARL cookie** / account is configured inside Deemix UI — not a Neo setting.
        - Do not paste ARL tokens into chat; treat like a password.
        - Neo: no app password option by default.

        ## API / automation

        Deemix web builds vary; some expose internal HTTP for the SPA only.
        Agent-friendly approach:

        1. Health: container up + UI loads
        2. Confirm files appear under media Music volume after a UI download
        3. Optional: inspect reverse-engineered endpoints only if present (`/api/*`) — probe carefully:

        ```bash
        docker run --rm --network internal curlimages/curl:latest \
          -fsS "http://deemix:6595/" -I
        ```

        Prefer UI operations over fragile undocumented APIs. For library management after download,
        use Lidarr (`/neo-lidarr`) if the collection is tracked there.

        ## Procedures

        1. `systemctl status docker-deemix` + logs
        2. Re-auth ARL if downloads fail with auth errors
        3. Disk permissions on Music volume (PUID/PGID = neo.core uid/gid)
        4. VPN health if outbound to Deezer fails

        ## Pitfalls

        - Account/ToS risk — operator responsibility.
        - Clearing appdata loses Deemix config/ARL; music files on volume remain.

        ## Verification

        - UI reachable after tinyauth
        - Test download writes files under Music volume
      '';
    };
  };
}
