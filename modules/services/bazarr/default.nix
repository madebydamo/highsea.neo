# Bazarr service implementation.
# Bazarr reads its settings from config/config.yaml only (no environment
# overrides), so bazarr-setup writes its API key there, and the address and
# API key of Sonarr and Radarr (over the subtitles link) when they are on.
# It restarts Bazarr only when something changed.
{...}: {
  neoPlugin.modules.bazarr = {
    config,
    lib,
    pkgs,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "bazarr";
      cfg = config.neo.services.${name};
      appdata = "${config.neo.core.volumes.appdata}/${name}";
      vols = config.neo.core.volumes;
      settingsFile = "${appdata}/config/config/config.yaml";
      peer = s: let
        n = plugin.name s;
      in
        config.neo.services.${n}
        // {
          name = n;
          on = config.neo.services.${n}.enabled or false;
        };
      sonarr = peer "sonarr";
      radarr = peer "radarr";
      envTemplate = "${name}-setup.env";
      # Sets one connection: yq with the values in the environment.
      connect = app: keyVar: ''
        yq -i '.general.use_${app} = true
          | .${app}.ip = strenv(HOST) | .${app}.port = env(PORT)
          | .${app}.apikey = strenv(${keyVar}) | .${app}.ssl = false
          | .${app}.base_url = "/"' "$tmp"
      '';
    in {
      config = mkIf cfg.enabled {
        assertions = lib.neo.requireSecrets name cfg ["apiKey"];

        systemd.services."docker-${name}".preStart = lib.neo.mkEnsureDirs config [
          "${vols.media}/TV"
          "${vols.media}/Movies"
          "${vols.data}/Downloads"
          appdata
          "${appdata}/config"
        ];

        neo.core.secrets.templates.${envTemplate} = {
          env =
            {BAZARR_APIKEY = cfg.apiKey;}
            // optionalAttrs sonarr.on {SONARR_APIKEY = sonarr.apiKey;}
            // optionalAttrs radarr.on {RADARR_APIKEY = radarr.apiKey;};
          restartUnits = ["${name}-setup.service"];
        };

        systemd.services."${name}-setup" = lib.neo.mkSetupService {
          inherit pkgs;
          name = "${name}-setup";
          description = "Set the API key and the Sonarr/Radarr connection of Bazarr${plugin.label}";
          containers = [name];
          path = [pkgs.yq-go pkgs.coreutils pkgs.systemd];
          retryInterval = 15;
          serviceConfig.EnvironmentFile = config.neo.core.secrets.templates.${envTemplate}.path;
          script = ''
            SETTINGS="${settingsFile}"
            if [ ! -s "$SETTINGS" ]; then
              echo "Bazarr has not written config.yaml yet"
              exit 1
            fi
            tmp="$(mktemp)"
            trap 'rm -f "$tmp"' EXIT
            cp "$SETTINGS" "$tmp"
            yq -i '.auth.apikey = strenv(BAZARR_APIKEY)' "$tmp"
            ${optionalString sonarr.on ''
                HOST=${sonarr.name} PORT=8989 ${connect "sonarr" "SONARR_APIKEY"}''}
            ${optionalString radarr.on ''
                HOST=${radarr.name} PORT=7878 ${connect "radarr" "RADARR_APIKEY"}''}
            # Compare content, not formatting: Bazarr rewrites the file its own way.
            if [ "$(yq -o=json '.' "$tmp")" = "$(yq -o=json '.' "$SETTINGS")" ]; then
              echo "Bazarr settings up to date"
              exit 0
            fi
            # Write through the existing file: keeps its owner and mode.
            cat "$tmp" > "$SETTINGS"
            echo "Bazarr settings changed, restarting Bazarr"
            systemctl restart --no-block docker-${name}.service
          '';
        };

        virtualisation.oci-containers.containers.${name} = {
          image = cfg.containers.${name};
          environment = lib.neo.linuxserverEnv config;
          volumes = [
            "${appdata}/config:/config"
            "${vols.media}/TV:/tv"
            "${vols.media}/Movies:/movies"
            "${vols.data}/Downloads:/downloads"
          ];
          networks = [(lib.neo.docker.serviceNetwork name)];
        };
      };
    };
}
