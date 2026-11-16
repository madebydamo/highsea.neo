# Jellyfin metrics, dashboard and alerts.
#
# Jellyfin serves /metrics (prometheus-net: HTTP requests, .NET runtime) on
# its public port 8096 only with <EnableMetrics> in system.xml, which
# belongs to Jellyfin (no environment setting). jellyfin-metrics sets that one
# element with xmlstarlet: true while a monitoring agent runs here, false
# otherwise, and restarts Jellyfin when it changed. SWAG answers /metrics with
# 404 (hidePaths); the agent scrapes jellyfin:8096 on its Docker network.
{...}: {
  neoPlugin.modules.jellyfin-monitoring = {
    config,
    lib,
    pkgs,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "jellyfin";
    cfg = config.neo.services.${name};
    collecting = config.neo.monitoring.collecting;
    title = "Jellyfin${plugin.label}";
    sel = lib.neo.grafana.appSelector name;
    systemXml = "${config.neo.core.volumes.appdata}/${name}/config/system.xml";
  in {
    config = lib.mkIf cfg.enabled {
      systemd.services."${name}-metrics" = lib.neo.mkSetupService {
        inherit pkgs;
        name = "${name}-metrics";
        description = "Turn Jellyfin's metrics${plugin.label} on or off for the monitoring agent";
        containers = [name];
        path = [pkgs.xmlstarlet pkgs.systemd];
        retryInterval = 15;
        script = ''
          XML="${systemXml}"
          if [ ! -s "$XML" ]; then
            echo "Jellyfin has not written system.xml yet"
            exit 1
          fi
          want=${lib.boolToString collecting}
          have=$(xmlstarlet sel -t -v '/ServerConfiguration/EnableMetrics' "$XML" 2>/dev/null || true)
          if [ "$have" = "$want" ]; then
            echo "EnableMetrics already $want"
            exit 0
          fi
          if [ -z "$have" ]; then
            xmlstarlet ed -L -s /ServerConfiguration -t elem -n EnableMetrics -v "$want" "$XML"
          else
            xmlstarlet ed -L -u /ServerConfiguration/EnableMetrics -v "$want" "$XML"
          fi
          echo "EnableMetrics set to $want, restarting Jellyfin"
          systemctl restart --no-block docker-${name}.service
        '';
      };

      neo.monitoring.apps.${name} = {
        hidePaths = ["/metrics"];
        metrics.main = {
          container = name;
          port = 8096;
        };
        dashboards.overview = {
          inherit title;
          description = "Watching: requests from the apps and browsers, answer times, errors in Jellyfin's log, and the server's work (memory, processor for conversions).";
          time = "now-7d";
          panels = with lib.neo.grafana;
            [
              (row "Jellyfin" null)
              (stat {
                title = "Running";
                w = 6;
                h = 4;
                targets = [(pq "min(up{${sel}})" "")];
                mappings = upDown;
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "red";
                      value = null;
                    }
                    {
                      color = "green";
                      value = 1;
                    }
                  ];
                };
              })
              (stat {
                title = "Requests";
                w = 6;
                h = 4;
                decimals = 0;
                description = "Requests Jellyfin answered in the chosen time range (apps, browsers, streams).";
                targets = [(pq "sum(increase(http_requests_received_total{${sel}}[$__range]))" "")];
              })
              (stat {
                title = "Server errors";
                w = 6;
                h = 4;
                decimals = 0;
                targets = [(pq ''sum(increase(http_requests_received_total{${sel}, code=~"5.."}[$__range])) or vector(0)'' "")];
                thresholds = thresholdsGreenRed [
                  {
                    color = "red";
                    value = 1;
                  }
                ];
              })
              (stat {
                title = "Memory";
                w = 6;
                h = 4;
                unit = "bytes";
                targets = [(pq "max(process_working_set_bytes{${sel}})" "")];
              })
              (timeseries {
                title = "Requests by part of Jellyfin";
                unit = "reqps";
                targets = [(pq "topk(8, sum by (controller) (rate(http_requests_received_total{${sel}}[$__rate_interval])))" "{{controller}}")];
              })
              (timeseries {
                title = "Answer time (95th percentile)";
                unit = "s";
                targets = [(pq "histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{${sel}}[$__rate_interval])))" "p95")];
              })
            ]
            ++ lib.neo.grafana.app.web {service = name;}
            ++ lib.neo.grafana.app.errors {
              service = name;
              containers = [name];
              units = ["${name}-metrics"];
              filter = hs.filters.jellyfin;
              metrics = false;
            }
            ++ hs.resources [name];
        };
        alerts = lib.neo.monitoring.appAlerts {
          service = name;
          label = title;
          containers = [name];
          errorFilter = hs.filters.jellyfin;
        };
      };
    };
  };
}
