# Bazarr service implementation.
# Bazarr reads its settings from config/config.yaml only (no environment
# overrides), so bazarr-setup writes the API key there.
{...}: {
  neoPlugin.modules.bazarr = {
    config,
    lib,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "bazarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      vols = config.neo.core.volumes;
    in {
      config = mkIf cfg.enabled {
        assertions = [
          {
            assertion = cfg.apiKey != null;
            message = "neo.services.${name}: set the API key (use Generate).";
          }
        ];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          "${vols.media}/TV"
          "${vols.media}/Movies"
          "${vols.data}/Downloads"
          appdata
          "${appdata}/config"
        ];

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment = lib.neo.linuxserverEnv config;
          volumes = [
            "${appdata}/config:/config"
            "${vols.media}/TV:/tv"
            "${vols.media}/Movies:/movies"
            "${vols.data}/Downloads:/downloads"
          ];
          networks = ["internal"];
        };
      };
    };
}
