# qBittorrent service implementation.
# preStart writes qBittorrent.conf on every start (ports, paths, Web UI login).
# qbittorrent-portcheck dials the listen port from the container's network
# namespace (gluetun's when routed) and restarts qBittorrent when it is closed.
{...}: {
  neoPlugin.modules.qbittorrent = {
    config,
    lib,
    pkgs,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "qbittorrent";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      confPath = "${appdata}/config/qBittorrent/qBittorrent.conf";
      hs = import ../../_lib.nix {inherit lib;};
      # Rendered at activation (root only); preStart hashes it there.
      passwordTemplate = "${name}-webui-password";
      passwordFile = config.neo.core.secrets.templates.${passwordTemplate}.path;
    in {
      # Two copies behind the VPN share gluetun's ports: both are settings.
      # Outside mkIf: a definition of neo.services.<name> cannot depend on
      # its own `enabled`.
      config = mkMerge [
        {neo.services.${name}.vpn.ports = [cfg.webPort cfg.listenPort];}
        (mkIf cfg.enabled {
          neo.core.secrets.generated."${name}-password" = {};
          neo.core.secrets.templates.${passwordTemplate} = {
            content = hs.qbitPassword config name;
            restartUnits = ["docker-${name}.service"];
          };

          systemd.services."docker-${name}".preStart = lib.concatStringsSep "\n" [
            (lib.neo.mkEnsureDirs config [
              "${config.neo.core.volumes.data}/Downloads"
              appdata
              "${appdata}/downloads"
              "${appdata}/config"
              "${appdata}/config/qBittorrent"
            ])
            ''
              u=${escapeShellArg cfg.username}
              wp=${toString cfg.webPort}
              lp=${toString cfg.listenPort}
              h=$(${pkgs.python3}/bin/python3 ${./passwordhashing.py} < ${passwordFile})
              cat << ACTEOF | sed "s/^[[:space:]]*//" > ${confPath}
              [AutoRun]
              enabled=false
              program=

              [BitTorrent]
              Session\AddTorrentStopped=false
              Session\DefaultSavePath=/downloads
              Session\ExcludedFileNames=
              Session\GlobalMaxInactiveSeedingMinutes=1440
              Session\GlobalMaxRatio=1.5
              Session\GlobalMaxSeedingMinutes=1440
              Session\Port=$lp
              Session\QueueingSystemEnabled=true
              Session\ShareLimitAction=Stop
              Session\TempPath=/downloads/incomplete/

              [LegalNotice]
              Accepted=true

              [Preferences]
              IPFilter\BannedIPs=
              Connection\PortRange=$lp
              Connection\PortRangeMin=$lp
              Connection\UPnP=false
              Downloads\DefaultSavePath=/downloads
              Downloads\SavePath=/downloads
              Downloads\ScanDirsV2=@Variant(\0\0\0\x1c\0\0\0\0)
              Downloads\TempPath=/downloads/incomplete/
              WebUI\Address=*
              WebUI\CSRFProtection=false
              WebUI\HostHeaderValidation=false
              WebUI\ServerDomains=*
              WebUI\Username=$u
              WebUI\Password_PBKDF2="@ByteArray($h)"
              WebUI\Port=$wp
              WebUI\LocalHostAuth=false
              ACTEOF
              chown ${toString config.neo.core.uid}:${toString config.neo.core.gid} ${confPath}
              chmod 0600 ${confPath}
            ''
          ];

          virtualisation.oci-containers.containers.${name} = {
            environment =
              lib.neo.linuxserverEnv config
              // {
                UMASK_SET = "022";
                WEBUI_PORT = toString cfg.webPort;
                TORRENTING_PORT = toString cfg.listenPort;
              };
            image = cfg.containers.${name};
            volumes = [
              "${appdata}/config:/config"
              "${config.neo.core.volumes.data}/Downloads:/downloads"
            ];
            networks = [(lib.neo.docker.serviceNetwork name)];
          };

          # Detects a closed torrent listen port (from inside the container/VPN
          # netns) and restarts the container. Listed in extraUnits (option.nix).
          systemd.services."${name}-portcheck" = {
            description = "Restart qBittorrent${plugin.label} when its torrent listen port is closed";
            after = ["docker-${name}.service"];
            wants = ["docker-${name}.service"];
            wantedBy = ["multi-user.target"];
            path = with pkgs; [
              bash
              coreutils
              docker
              gawk
              iproute2
              systemd
              util-linux
            ];
            serviceConfig = {
              Type = "simple";
              Restart = "always";
              RestartSec = "10s";
            };
            script = ''
              set -uo pipefail

              LISTEN_PORT=${toString cfg.listenPort}
              INTERVAL=300
              DIAL_TIMEOUT=5

              log() {
                echo "$(date -Iseconds) $*"
              }

              get_container_pid() {
                docker inspect -f '{{.State.Pid}}' ${name} 2>/dev/null || true
              }

              # Source address used for outbound traffic in the container netns
              # (gluetun/VPN interface when vpn.enabled).
              get_outbound_ip() {
                local pid=$1
                nsenter -t "$pid" -n ip -4 route get 1.1.1.1 2>/dev/null \
                  | awk '{for (i = 1; i <= NF; i++) if ($i == "src") { print $(i+1); exit }}'
              }

              # TCP dial from the container network namespace (same idea as the old Go portcheck).
              port_is_open() {
                local pid=$1 ip=$2 port=$3
                nsenter -t "$pid" -n timeout "$DIAL_TIMEOUT" \
                  bash -c "echo >/dev/tcp/''${ip}/''${port}" 2>/dev/null
              }

              first=1
              while true; do
                if [[ "$first" -eq 0 ]]; then
                  sleep "$INTERVAL"
                fi
                first=0

                if ! systemctl is-active --quiet docker-${name}; then
                  log "docker-${name} is not active; skipping check"
                  continue
                fi

                pid=$(get_container_pid)
                if [[ -z "$pid" || "$pid" == "0" ]]; then
                  log "could not get ${name} container pid; skipping check"
                  continue
                fi

                ip=$(get_outbound_ip "$pid" || true)
                if [[ -z "$ip" ]]; then
                  log "could not determine outbound IP; skipping check"
                  continue
                fi

                if port_is_open "$pid" "$ip" "$LISTEN_PORT"; then
                  continue
                fi

                log "listen port ''${LISTEN_PORT} closed on ''${ip}; restarting docker-${name}"
                systemctl restart docker-${name} || log "restart of docker-${name} failed"
              done
            '';
          };
        })
      ];
    };
}
