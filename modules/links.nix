# Docker links between the high_sea services: every service has its own
# network (app-<name>), and these links let exactly the containers that call
# each other meet. Declared as if there were no VPN: for a VPN-routed member
# gluetun joins the link under the member's name (Neo's vpn module), so the
# same addresses work with the VPN on or off.
#
#   downloads   Sonarr, Radarr, Lidarr, Prowlarr, Listenarr → qBittorrent (download client)
#   indexers    Prowlarr ↔ Sonarr, Radarr, Lidarr (app sync, Torznab searches)
#   cloudflare  Prowlarr → FlareSolverr (no login of its own: never public)
#   subtitles   Bazarr → Sonarr, Radarr
#
# A link is built from the enabled members only, and only when one side can
# talk to the other (it needs its hub plus at least one more member). Seerr
# and declarr use the apps' public URLs instead; Seerr → Jellyfin too.
{...}: {
  neoPlugin.modules.links = {
    config,
    lib,
    plugin,
    ...
  }: let
    on = s: config.neo.services.${plugin.name s}.enabled or false;
    links = {
      downloads = {
        hub = "qbittorrent";
        members = ["sonarr" "radarr" "lidarr" "prowlarr" "listenarr"];
      };
      indexers = {
        hub = "prowlarr";
        members = ["sonarr" "radarr" "lidarr"];
      };
      cloudflare = {
        hub = "flaresolverr";
        members = ["prowlarr"];
      };
      subtitles = {
        hub = "bazarr";
        members = ["sonarr" "radarr"];
      };
    };
    # What lib.neo.docker.mkLink does, written out: mkLink's attribute names
    # depend on which services are on, and a top-level mkMerge over them
    # would recurse into `config`. Each link sits under mkIf instead.
    members = l: map plugin.name ([l.hub] ++ lib.filter on l.members);
    active = l: on l.hub && lib.any on l.members;
  in {
    config = {
      virtualisation.oci-containers.containers = lib.mkMerge (lib.mapAttrsToList (link: l:
        lib.mkIf (active l) (lib.genAttrs (members l) (_: {
          networks = lib.mkAfter [(lib.neo.docker.linkNetwork (plugin.name link))];
        })))
      links);
      neo.core.docker.links = lib.mkMerge (lib.mapAttrsToList (link: l:
        lib.mkIf (active l) {${plugin.name link} = members l;})
      links);
    };
  };
}
