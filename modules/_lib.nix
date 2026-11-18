# Helpers shared by the high_sea modules (not a module: import-tree skips
# files starting with `_`). Use: `hs = import ../../_lib.nix {inherit lib;};`
{lib}: let
  self = {
    # qBittorrent's Web UI password: the setting, or a key the machine
    # generates (neo.core.secrets.generated."<qbittorrent>-password", declared
    # by qbittorrent/default.nix) that only the apps know.
    qbitPassword = config: qbitName: let
      pw = config.neo.services.${qbitName}.password or null;
    in
      if lib.neo.isSet pw
      then pw
      else lib.neo.secrets.mkPlaceholder "generated/${qbitName}-password";

    # JSON text of `value` in which the secret strings in `secrets` (setting
    # values or their placeholders) are filled in at activation, JSON-escaped:
    # for a secrets template's `content`.
    secretJSON = secrets: value: let
      ss = lib.unique (lib.filter builtins.isString secrets);
    in
      builtins.replaceStrings (map builtins.toJSON ss) (map lib.neo.secrets.jsonString ss) (builtins.toJSON value);

    # LogQL pipelines that keep the error lines of each app's own log format
    # (third-party images do not log JSON with `level`).
    filters = {
      # Sonarr, Radarr, Lidarr, Prowlarr: "[Error] DownloadService: …"
      servarr = ''|~ `\[(Error|Fatal)\]` '';
      # Bazarr, FlareSolverr (Python logging): "… ERROR …"
      python = ''|~ `\b(ERROR|CRITICAL)\b` '';
      # Jellyfin: "[12:00:00] [ERR] [12] Emby.Server…"
      jellyfin = ''|~ `\[(ERR|FTL)\]` '';
      # Seerr (winston): "2026-…Z [error][Jobs]: …"
      # Not "Unable to find TMDb ID": logged on every Jellyfin sync (5 minutes)
      # for each film in the library that is not on TMDb, e.g. a home video.
      seerr = ''|~ `\[(error|crit|alert|emerg)\]` !~ `Unable to find TMDb ID` '';
      # Audiobookshelf: "[2026-… 12:00:00.000] ERROR: …"
      audiobookshelf = ''|~ `\] (ERROR|FATAL):` '';
      # Tdarr: "[2026-…] [ERROR] Tdarr_Server - …"
      tdarr = ''|~ `\[(ERROR|FATAL)\]` '';
      # declarr (Python logging): "[ERROR] declarr.arr: …"
      declarr = ''|~ `\[(ERROR|CRITICAL)\]` '';
      # qBittorrent, Listenarr, Deemix: no fixed format.
      generic = ''|~ `(?i)\b(error|fatal|exception)\b` '';
    };

    # Exporter images, pinned (the docker updater pulls the configured tag).
    images = {
      exportarr = "ghcr.io/onedr0p/exportarr:v2.3.0";
      qbittorrentExporter = "ghcr.io/esanchezm/prometheus-qbittorrent-exporter:v1.8.0";
    };

    # Memory and processor of an app's containers (no app code needed).
    resources = containers: let
      re = lib.concatStringsSep "|" containers;
    in
      with lib.neo.grafana; [
        (row "Resources" null)
        (timeseries {
          title = "Memory";
          unit = "bytes";
          targets = [(pq ''sum by (name) (container_memory_working_set_bytes{host=~"$host", name=~"${re}"})'' "{{name}}")];
        })
        (timeseries {
          title = "Processor";
          unit = "percentunit";
          targets = [(pq ''sum by (name) (rate(container_cpu_usage_seconds_total{host=~"$host", name=~"${re}"}[$__rate_interval]))'' "{{name}}")];
        })
      ];

    # Monitoring of a Servarr-family app (Sonarr, Radarr, Lidarr, Prowlarr,
    # Bazarr) through an exportarr sidecar on the app's own network, not
    # VPN-routed: it reaches the app by name (gluetun answers for a routed
    # app). The sidecar exists only while a monitoring agent runs here.
    # Returns the module's `config`.
    arrMonitoring = {
      config,
      plugin,
      svc,
      label,
      description,
      port,
      # sel: panels shown first (app-specific headline)
      headline,
      # rules merged over the standard ones
      alerts ? {},
      exporterEnv ? {},
      # the app's own key reaches exportarr as API_KEY
      apiKey,
    }: let
      name = plugin.name svc;
      cfg = config.neo.services.${name};
      exporter = "${name}-exporter";
      collecting = config.neo.monitoring.collecting;
      sel = lib.neo.grafana.appSelector name;
      asel = lib.neo.grafana.alertSelector name;
      title = "${label}${plugin.label}";
      filter =
        self.filters.${
          if svc == "bazarr"
          then "python"
          else "servarr"
        };
    in
      lib.mkMerge [
        # Outside `mkIf cfg.enabled`: a definition of neo.services.<name>
        # cannot depend on its own `enabled`.
        {neo.services.${name}.systemdUnits = lib.mkIf collecting (lib.mkOptionDefault ["docker-${exporter}"]);}
        (lib.mkIf (cfg.enabled && collecting) {
          # exportarr refuses to start with a key that is not 20 to 32 letters
          # or digits, although the app itself takes longer ones. Say so at
          # build time instead of a restart loop. An encrypted key is a
          # placeholder here and cannot be measured.
          assertions = [
            {
              assertion =
                !lib.neo.isSet apiKey
                || lib.neo.secrets.isPlaceholder apiKey
                || builtins.match "[A-Za-z0-9]{20,32}" apiKey != null;
              message = "neo.services.${name}: apiKey must be 20 to 32 letters or digits while Monitoring collects (its metrics exporter accepts nothing else). Use the Generate helper for a new key; apps you connected to ${label} by hand need the new key.";
            }
          ];
          virtualisation.oci-containers.containers.${exporter} = {
            image = self.images.exportarr;
            cmd = [svc];
            environment =
              {
                PORT = "9707";
                URL = "http://${name}:${toString port}";
                LOG_LEVEL = "info";
              }
              // exporterEnv;
            networks = [(lib.neo.docker.serviceNetwork name)];
            dependsOn = [name];
          };
          neo.core.secrets.containerEnv.${exporter}.API_KEY = apiKey;
        })
        (lib.mkIf cfg.enabled {
          neo.monitoring.apps.${name} = {
            metrics.arr = {
              container = exporter;
              port = 9707;
            };
            dashboards.overview = {
              inherit title description;
              time = "now-7d";
              panels =
                headline sel
                ++ lib.neo.grafana.app.web {service = name;}
                ++ lib.neo.grafana.app.errors {
                  service = name;
                  containers = [name];
                  inherit filter;
                  metrics = false;
                }
                ++ self.resources [name exporter];
            };
            alerts =
              lib.neo.monitoring.appAlerts {
                service = name;
                label = title;
                containers = [name];
                errorFilter = filter;
              }
              // {
                health = {
                  title = "${title}: reports a problem";
                  # Warnings and errors from the app's own health check
                  # (indexer down, download client unreachable, folder missing).
                  # "> 0": a healthy app is one series with value 0 and no
                  # labels of a problem; Bazarr's has no `type` to filter on.
                  expr = ''count by (host) (${svc}_system_health_issues{${asel}${lib.optionalString (svc != "bazarr") '', type=~"warning|error"''}} > 0)'';
                  above = 0;
                  for = "1h";
                  summary = "${title} on {{ $labels.host }} reports {{ printf \"%.0f\" $values.B.Value }} problems on its System → Status page for an hour.";
                };
              }
              // alerts;
          };
        })
      ];

    # Dashboard and alerts of an app without a metrics endpoint: web
    # requests (SWAG), error lines in its own log format, resources.
    basicMonitoring = {
      config,
      plugin,
      svc,
      label,
      description,
      filter,
      units ? [],
      # the app's containers; default: the one named after the service
      containers ? [(plugin.name svc)],
      web ? true,
      headline ? [],
    }: let
      name = plugin.name svc;
      title = "${label}${plugin.label}";
    in
      lib.mkIf config.neo.services.${name}.enabled {
        neo.monitoring.apps.${name} = {
          dashboards.overview = {
            inherit title description;
            time = "now-7d";
            panels =
              headline
              ++ lib.optionals web (lib.neo.grafana.app.web {service = name;})
              ++ lib.neo.grafana.app.errors {
                service = name;
                inherit containers units filter;
                metrics = false;
              }
              ++ lib.optionals (containers != []) (self.resources containers);
          };
          alerts = lib.neo.monitoring.appAlerts {
            service = name;
            label = title;
            inherit containers units;
            errorFilter = filter;
          };
        };
      };

    # Free space of an app's root folders (Sonarr, Radarr, Lidarr): the media
    # disk running full stops imports.
    diskAlert = {
      svc,
      name,
      title,
      gib ? 50,
    }: {
      disk-low = {
        title = "${title}: media disk almost full";
        expr = ''min by (host, path) (${svc}_rootfolder_freespace_bytes{${lib.neo.grafana.alertSelector name}})'';
        below = gib * 1024 * 1024 * 1024;
        for = "30m";
        summary = "Only {{ humanize1024 $values.B.Value }}B are free in {{ $labels.path }} for ${title} on {{ $labels.host }}; imports stop when it is full.";
      };
    };
  };
in
  self
