# FlareSolverr metrics (its own Prometheus exporter on 8192, switched on
# only while a monitoring agent runs here), dashboard and alerts.
# VPN-routed by default: the agent scrapes through gluetun (Neo does that on
# its own), and 8192 joins the ports claimed in gluetun's namespace.
#   flaresolverr_request_total{domain, result}   result: solved|not_detected|error|unknown
#   flaresolverr_request_duration_*{domain}      histogram, buckets 0/10/25/50 s
{...}: {
  neoPlugin.modules.flaresolverr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "flaresolverr";
    cfg = config.neo.services.${name};
    collecting = config.neo.monitoring.collecting;
    title = "FlareSolverr${plugin.label}";
    sel = lib.neo.grafana.appSelector name;
    asel = lib.neo.grafana.alertSelector name;
    metricsPort = 8192;
  in {
    config = lib.mkMerge [
      {neo.services.${name}.vpn.ports = lib.mkIf collecting (lib.mkOptionDefault [metricsPort]);}
      (lib.mkIf cfg.enabled {
        virtualisation.oci-containers.containers.${name}.environment = lib.mkIf collecting {
          PROMETHEUS_ENABLED = "true";
          PROMETHEUS_PORT = toString metricsPort;
        };

        neo.monitoring.apps.${name} = {
          metrics.main = {
            container = name;
            port = metricsPort;
          };
          dashboards.overview = {
            inherit title;
            description = "Bot checks FlareSolverr opens for Prowlarr: how many, how many worked, on which sites and how long they take.";
            time = "now-7d";
            panels = with lib.neo.grafana;
              [
                (row "Bot checks" null)
                (stat {
                  title = "Pages opened";
                  w = 6;
                  h = 4;
                  decimals = 0;
                  targets = [(pq "sum(increase(flaresolverr_request_total{${sel}}[$__range])) or vector(0)" "")];
                })
                (stat {
                  title = "Bot checks passed";
                  w = 6;
                  h = 4;
                  decimals = 0;
                  targets = [(pq ''sum(increase(flaresolverr_request_total{${sel}, result="solved"}[$__range])) or vector(0)'' "")];
                })
                (stat {
                  title = "Failed";
                  w = 6;
                  h = 4;
                  decimals = 0;
                  targets = [(pq ''sum(increase(flaresolverr_request_total{${sel}, result="error"}[$__range])) or vector(0)'' "")];
                  thresholds = thresholdsGreenRed [
                    {
                      color = "orange";
                      value = 1;
                    }
                  ];
                })
                (stat {
                  title = "Average time";
                  w = 6;
                  h = 4;
                  unit = "s";
                  targets = [(pq "sum(increase(flaresolverr_request_duration_sum{${sel}}[$__range])) / clamp_min(sum(increase(flaresolverr_request_duration_count{${sel}}[$__range])), 1)" "")];
                })
                (bars {
                  title = "Pages by result";
                  targets = [(pq "sum by (result) (increase(flaresolverr_request_total{${sel}}[$__interval]))" "{{result}}")];
                })
                (bargauge {
                  title = "Sites";
                  targets = [(pq "sort_desc(sum by (domain) (increase(flaresolverr_request_total{${sel}}[$__range])))" "{{domain}}")];
                })
              ]
              ++ lib.neo.grafana.app.errors {
                service = name;
                containers = [name];
                filter = hs.filters.python;
                metrics = false;
              }
              ++ hs.resources [name];
          };
          alerts =
            lib.neo.monitoring.appAlerts {
              service = name;
              label = title;
              containers = [name];
              errorFilter = hs.filters.python;
            }
            // {
              failing = {
                title = "${title}: bot checks failing";
                expr = ''(sum by (host) (increase(flaresolverr_request_total{${asel}, result="error"}[1h])) / sum by (host) (increase(flaresolverr_request_total{${asel}}[1h]))) and on (host) sum by (host) (increase(flaresolverr_request_total{${asel}}[1h])) >= 5'';
                above = 0.5;
                for = "30m";
                summary = "{{ humanizePercentage $values.B.Value }} of the bot checks ${title} opened on {{ $labels.host }} in the last hour failed: the sites behind them stop working in Prowlarr.";
              };
            };
        };
      })
    ];
  };
}
