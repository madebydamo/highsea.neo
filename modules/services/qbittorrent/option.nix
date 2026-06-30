# Qbittorrent service options.
{...}: {
  flake.modules.nixos.qbittorrent-option = {lib, ...}:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; {
      options.neo.services.qbittorrent = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "qbittorrent service" {rank = 0;};
              username = mkOption {
                type = types.str;
                default = "admin";
                description = "Username for qBittorrent WebUI (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
              };
              password = mkOption {
                type = types.str;
                default = "adminadmin";
                description = "Password for qBittorrent WebUI (enables declarr auto-configuration compatibility; overridable)";
                rank = 5;
              };
              webPort = mkOption {
                type = types.port;
                default = 8082;
                description = "Web UI listen port inside container (used by declarr and gluetun port publishing)";
                rank = 10;
              };
              listenPort = mkOption {
                type = types.port;
                default = 8342;
                description = "Incoming torrent listen port (used by gluetun firewall input ports)";
                rank = 10;
              };
            }
            // neo.mkReverseProxyOptions {
              subdomain = "qbittorrent";
            }
            // neo.mkVpnOptions {
              enabled = true;
              containers = ["qbittorrent"];
              networks = ["internal"];
              ports = [8082 8342];
            }
            // lib.neo.mkServiceMeta {
              icon = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/svg/qbittorrent.svg";
              description = ''
                qBittorrent is a bittorrent client programmed in C++ / Qt that uses libtorrent (sometimes called libtorrent-rasterbar) by Arvid Norberg.
                It aims to be a good alternative to all other bittorrent clients out there. qBittorrent is fast, stable and provides unicode support as well as many features.
              '';
              projectUrl = "https://www.qbittorrent.org/";
              githubUrl = "https://github.com/qbittorrent/qBittorrent";
              releaseUrl = "https://github.com/qbittorrent/qBittorrent/releases";
              iframeCompatible = false;
            };
        };
        default = {};
        description = "Qbittorrent service configuration";
      };
    };
}
