# Qbittorrent service implementation.
{...}: {
  flake.modules.nixos.qbittorrent = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.neo.services.qbittorrent;
      confPath = "${config.neo.core.volumes.appdata}/qbittorrent/config/qBittorrent/qBittorrent.conf";
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-qbittorrent.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.data}/Downloads";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/qbittorrent";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/qbittorrent/downloads";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/qbittorrent/config";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/qbittorrent/config/qBittorrent";
          })
          ''
            pw=${escapeShellArg cfg.password}
            u=${escapeShellArg cfg.username}
            wp=${toString cfg.webPort}
            lp=${toString cfg.listenPort}
            h=$(${pkgs.python3}/bin/python3 ${./passwordhashing.py} "$pw")
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
            chmod 0644 ${confPath}
          ''
        ];

        virtualisation.oci-containers.containers.qbittorrent = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            UMASK_SET = "022";
            WEBUI_PORT = toString cfg.webPort;
            TORRENTING_PORT = toString cfg.listenPort;
          };
          image = cfg.containers.qbittorrent;
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/qbittorrent/config:/config"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };

        # Replaces the former portcheck container: detect closed torrent listen port
        # (from inside the container/VPN netns) and restart docker-qbittorrent.
        systemd.services.qbittorrent-portcheck = {
          description = "Restart qBittorrent when torrent listen port is closed";
          after = ["docker-qbittorrent.service"];
          wants = ["docker-qbittorrent.service"];
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
              docker inspect -f '{{.State.Pid}}' qbittorrent 2>/dev/null || true
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

              if ! systemctl is-active --quiet docker-qbittorrent; then
                log "docker-qbittorrent is not active; skipping check"
                continue
              fi

              pid=$(get_container_pid)
              if [[ -z "$pid" || "$pid" == "0" ]]; then
                log "could not get qbittorrent container pid; skipping check"
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

              log "listen port ''${LISTEN_PORT} closed on ''${ip}; restarting docker-qbittorrent"
              systemctl restart docker-qbittorrent || log "restart of docker-qbittorrent failed"
            done
          '';
        };
      };
    };
}
