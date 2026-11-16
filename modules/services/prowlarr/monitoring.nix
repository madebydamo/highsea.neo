# Prowlarr metrics (exportarr sidecar), dashboard and alerts. Builder: _lib.nix arrMonitoring.
# Prowlarr's indexer numbers are gauges of cumulative counts: delta(), not increase().
{...}: {
  neoPlugin.modules.prowlarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "prowlarr";
    title = "Prowlarr${plugin.label}";
    asel = lib.neo.grafana.alertSelector name;
  in {
    config = hs.arrMonitoring {
      inherit config plugin;
      svc = "prowlarr";
      label = "Prowlarr";
      description = "The search sites behind your media apps: searches, grabs, failing sites and which app searches most.";
      port = 9696;
      apiKey = config.neo.services.${name}.apiKey;
      # Counts from Prowlarr's history, not only since the exporter started.
      exporterEnv.PROWLARR__BACKFILL = "true";
      alerts.indexer-failing = {
        title = "${title}: a search site keeps failing";
        # Share of failed searches per site in the last hour, once there were 5.
        expr = ''(sum by (host, indexer) (delta(prowlarr_indexer_failed_queries_total{${asel}}[1h])) / sum by (host, indexer) (delta(prowlarr_indexer_queries_total{${asel}}[1h]))) and on (host, indexer) sum by (host, indexer) (delta(prowlarr_indexer_queries_total{${asel}}[1h])) >= 5'';
        above = 0.5;
        for = "1h";
        summary = "{{ humanizePercentage $values.B.Value }} of searches on {{ $labels.indexer }} failed in the last hour (${title} on {{ $labels.host }}): the site may be down, blocked or need FlareSolverr.";
      };
      headline = sel:
        with lib.neo.grafana; [
          (row "Search sites" null)
          (stat {
            title = "Sites in use";
            w = 4;
            h = 4;
            targets = [(pq "max(prowlarr_indexer_enabled_total{${sel}})" "")];
          })
          (stat {
            title = "Searches";
            w = 4;
            h = 4;
            description = "Searches sent to the sites in the chosen time range.";
            decimals = 0;
            targets = [(pq "sum(delta(prowlarr_indexer_queries_total{${sel}}[$__range]))" "")];
          })
          (stat {
            title = "Grabs";
            w = 4;
            h = 4;
            description = "Releases the apps took from a search in the chosen time range.";
            decimals = 0;
            targets = [(pq "sum(delta(prowlarr_indexer_grabs_total{${sel}}[$__range]))" "")];
          })
          (stat {
            title = "Failed searches";
            w = 4;
            h = 4;
            decimals = 0;
            targets = [(pq "sum(delta(prowlarr_indexer_failed_queries_total{${sel}}[$__range])) or vector(0)" "")];
            thresholds = thresholdsGreenRed [
              {
                color = "orange";
                value = 1;
              }
            ];
          })
          (stat {
            title = "Problems";
            w = 4;
            h = 4;
            description = "Warnings and errors on Prowlarr's System → Status page (sites that stopped working, apps it cannot reach).";
            targets = [(pq ''count(prowlarr_system_health_issues{${sel}, type=~"warning|error"}) or vector(0)'' "")];
            thresholds = thresholdsGreenRed [
              {
                color = "red";
                value = 1;
              }
            ];
          })
          (bars {
            title = "Searches, grabs and failures";
            interval = "1h";
            targets = [
              (pq "clamp_min(sum(delta(prowlarr_indexer_queries_total{${sel}}[$__interval])), 0)" "searches")
              (pq "clamp_min(sum(delta(prowlarr_indexer_grabs_total{${sel}}[$__interval])), 0)" "grabs")
              (pq "clamp_min(sum(delta(prowlarr_indexer_failed_queries_total{${sel}}[$__interval])), 0)" "failed")
            ];
          })
          (bargauge {
            title = "Searches per site";
            targets = [(pq "sort_desc(sum by (indexer) (delta(prowlarr_indexer_queries_total{${sel}}[$__range])))" "{{indexer}}")];
          })
          (bargauge {
            title = "Failed searches per site";
            targets = [(pq "sort_desc(sum by (indexer) (delta(prowlarr_indexer_failed_queries_total{${sel}}[$__range])) > 0)" "{{indexer}}")];
          })
          (bargauge {
            title = "Searches per app";
            description = "Which app searches (Sonarr, Radarr, Lidarr, …).";
            targets = [(pq "sort_desc(sum by (user_agent) (delta(prowlarr_user_agent_queries_total{${sel}}[$__range])))" "{{user_agent}}")];
          })
          (table {
            title = "Problems Prowlarr reports";
            targets = [(pqInstant "max by (type, source, message) (prowlarr_system_health_issues{${sel}})" "")];
          })
        ];
    };
  };
}
