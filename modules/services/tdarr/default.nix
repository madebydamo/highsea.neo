# Tdarr service implementation.
{...}: {
  flake.modules.nixos.tdarr = {
    config,
    lib,
    ...
  }:
    with lib; let
      cfg = config.neo.services.tdarr;
    in {
      config = mkIf cfg.enabled {
        systemd.services.docker-tdarr.preStart = lib.concatStringsSep "\n" [
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/tdarr";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/tdarr/config";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/tdarr/server";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/tdarr/logs";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.appdata}/tdarr/temp";
          })
          (lib.neo.mkActivationScriptForDir config {
            dirPath = "${config.neo.core.volumes.media}";
          })
        ];

        virtualisation.oci-containers.containers.tdarr = {
          environment = {
            PUID = toString config.neo.core.uid;
            PGID = toString config.neo.core.gid;
            TZ = config.neo.core.timeZone;
            UMASK_SET = "002";
            serverIP = "0.0.0.0";
            serverPort = "8266";
            webUIPort = "8265";
            internalNode = "true";
            inContainer = "true";
            ffmpegVersion = "7";
            nodeName = "TdarrNode";
            auth = "false";
          };
          image = "ghcr.io/haveagitgat/tdarr:latest";
          autoStart = true;
          devices = ["/dev/dri:/dev/dri"];
          volumes = [
            "${config.neo.core.volumes.appdata}/tdarr/config:/app/configs"
            "${config.neo.core.volumes.appdata}/tdarr/server:/app/server"
            "${config.neo.core.volumes.appdata}/tdarr/logs:/app/logs"
            "${config.neo.core.volumes.appdata}/tdarr/temp:/temp"
            "${config.neo.core.volumes.media}:/media"
          ];
          networks = ["internal"];
        };
      };
    };
}
