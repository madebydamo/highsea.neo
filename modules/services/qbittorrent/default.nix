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
          image = "lscr.io/linuxserver/qbittorrent:latest";
          autoStart = true;
          volumes = [
            "${config.neo.core.volumes.appdata}/qbittorrent/config:/config"
            "${config.neo.core.volumes.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
