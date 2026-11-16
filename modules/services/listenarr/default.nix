# Listenarr service implementation.
{...}: {
  neoPlugin.modules.listenarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "listenarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      vols = config.neo.core.volumes;
    in {
      config = mkIf cfg.enabled {
        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          "${vols.media}/Audiobooks"
          "${vols.data}/Downloads"
          appdata
          "${appdata}/config"
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment =
            lib.neo.linuxserverEnv config
            // {
              UMASK = "022";
            };
          volumes = [
            "${appdata}/config:/app/config"
            "${vols.media}/Audiobooks:/audiobooks"
            "${vols.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
