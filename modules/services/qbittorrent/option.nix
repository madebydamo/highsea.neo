# qBittorrent service options.
{...}: {
  neoPlugin.modules.qbittorrent-option = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib;
    with {inherit (lib.neo) mkOption mkEnableOption;}; let
      name = plugin.name "qbittorrent";
    in {
      options.neo.services.${name} = mkOption {
        type = types.submodule {
          options =
            {
              enabled = mkEnableOption "The downloader your media apps send their downloads to${plugin.label}" {rank = 0;};
              username = mkOption {
                type = types.str;
                default = "admin";
                description = "Name to sign in to qBittorrent's page with. The media apps use it too.";
                rank = 5;
                ui = lib.neo.ui.mkUi {label = "User name";};
              };
              # Empty: a password the machine generates, known only to the apps
              # (Sonarr & co. through declarr, the monitoring exporter).
              password = lib.neo.mkSecretOption {
                type = types.nullOr types.str;
                default = null;
                description = "Password to sign in to qBittorrent's page with; the media apps use it too. Leave empty and Neo picks one only the apps know.";
                helper = lib.neo.helpers.randomToken;
                rank = 6;
              };
              webPort = mkOption {
                type = types.port;
                default = 8082;
                description = "Port of qBittorrent's web page inside Docker. Change it only when another app behind the VPN uses the same port.";
                rank = 10;
                ui = lib.neo.ui.mkUi {
                  label = "Web page port";
                  group = lib.neo.ui.groups.advanced;
                };
              };
              listenPort = mkOption {
                type = types.port;
                default = 8342;
                description = "Port other torrent users connect to. It must be the port your VPN forwards to you, or downloads stay slow.";
                rank = 11;
                ui = lib.neo.ui.mkUi {
                  label = "Incoming connections port";
                  group = lib.neo.ui.groups.advanced;
                };
              };
            }
            // lib.neo.mkReverseProxyOptions {
              subdomain = name;
            }
            # vpn.ports follows webPort and listenPort (default.nix).
            // lib.neo.mkVpnOptions {
              enabled = true;
              containers = [name];
              networks = [(lib.neo.docker.serviceNetwork name)];
              ports = [8082 8342];
            }
            // lib.neo.mkContainerDefinitions {
              ${name} = "lscr.io/linuxserver/qbittorrent:latest";
              extraUnits = ["${name}-portcheck"];
            }
            // lib.neo.mkAppdata "${config.neo.core.volumes.appdata}/${name}"
            // lib.neo.mkServiceMeta {
              category = "Media";
              icon = ./icon.svg;
              tagline = "Downloads files for your media apps${plugin.label}";
              description = ''
                qBittorrent does the downloading for Sonarr, Radarr, Lidarr and Listenarr and hands the finished files back to them.
                Its page shows what is downloading, how fast and what is waiting.
              '';
              notes = ''
                Sends its traffic through your VPN by default. For fast downloads the VPN must forward the incoming connections port to you (add it to the VPN's input ports); a check every 5 minutes restarts qBittorrent when that port is closed.
                Neo rewrites qBittorrent's settings file on every start, so changes to downloads paths, ports or the sign-in on its page are reset; seeding stops after a ratio of 1.5 or one day.
                Downloads land in Downloads, unfinished ones in Downloads/incomplete.
              '';
              projectUrl = "https://www.qbittorrent.org/";
              githubUrl = "https://github.com/qbittorrent/qBittorrent";
              releaseUrl = "https://github.com/qbittorrent/qBittorrent/releases";
              license = {
                spdx = "GPL-2.0-or-later";
                url = "https://github.com/qbittorrent/qBittorrent/blob/master/COPYING";
              };
              iframeCompatible = false;
            }
            // lib.neo.mkSkillOptions {};
        };
        default = {};
        description = "qBittorrent: the downloader of the media apps";
      };
    };
}
