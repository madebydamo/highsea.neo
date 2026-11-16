# Jellyfin service implementation.
{...}: {
  neoPlugin.modules.jellyfin = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "jellyfin";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      # Transcodes are scratch space: /tmp, not appdata.
      transcodes = "/tmp/${name}-cache/transcodes";
    in {
      config = mkIf cfg.enabled {
        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          config.neo.core.volumes.media
          appdata
          "${appdata}/config"
          "${appdata}/cache"
          transcodes
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment = lib.neo.linuxserverEnv config;
          devices = ["/dev/dri:/dev/dri"];
          volumes = [
            "${appdata}/config:/config"
            "${appdata}/cache:/cache"
            "${transcodes}:/config/cache/transcodes"
            "${config.neo.core.volumes.media}:/media"
          ];
          networks = ["host"];
        };
      };
    };
}
