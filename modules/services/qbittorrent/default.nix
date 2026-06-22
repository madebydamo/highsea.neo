# Qbittorrent service implementation.
{...}: {
  flake.modules.nixos.qbittorrent = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.qbittorrent;
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
          (lib.neo.mkActivationScriptForFile config {
            filePath = "${config.neo.core.volumes.appdata}/qbittorrent/config/qBittorrent/qBittorrent.conf";
            content = ''
              [AutoRun]
              enabled=false
              program=

              [LegalNotice]
              Accepted=true

              [Preferences]
              IPFilter\BannedIPs=
              Connection\PortRange=${toString cfg.listenPort}
              Connection\PortRangeMin=${toString cfg.listenPort}
              Connection\UPnP=false
              Downloads\DefaultSavePath=/downloads
              Downloads\SavePath=/downloads
              Downloads\ScanDirsV2=@Variant(\0\0\0\x1c\0\0\0\0)
              Downloads\TempPath=/downloads/incomplete/
              WebUI\Address=*
              WebUI\ServerDomains=*
              WebUI\Username=${cfg.username}
              WebUI\Password_PBKDF2="@ByteArray(ARQ77eY1NUZaQsuDHbIMCA==:0WMRkYTUWVT9wVvdDtHAjU9b3b7uB8NR1Gur2hmQCvCDpm39Q+PsJRJPaCU51dEiz+dTzh8qbPsL8WkFljQYFQ==)"
              WebUI\Port=${toString cfg.webPort}
              WebUI\LocalHostAuth=false
            '';
            mode = "0644";
          })
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
