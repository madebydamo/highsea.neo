# Radarr metrics (exportarr sidecar), dashboard and alerts. Builder: _lib.nix arrMonitoring.
{...}: {
  neoPlugin.modules.radarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "radarr";
    title = "Radarr${plugin.label}";
    s = sel: m: "${m}{${sel}}";
  in {
    config = hs.arrMonitoring {
      inherit config plugin;
      svc = "radarr";
      label = "Radarr";
      description = "Your films: what is on disk, what is missing, what is downloading, free space, and Radarr's errors.";
      port = 7878;
      apiKey = config.neo.services.${name}.apiKey;
      exporterEnv.ENABLE_ADDITIONAL_METRICS = "true";
      alerts = hs.diskAlert {
        svc = "radarr";
        inherit name title;
      };
      headline = sel:
        with lib.neo.grafana; [
          (row "Library" null)
          (stat {
            title = "Films";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "radarr_movie_total"})" "")];
          })
          (stat {
            title = "Films on disk";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "radarr_movie_downloaded_total"})" "")];
          })
          (stat {
            title = "Missing films";
            w = 4;
            h = 4;
            description = "Films that are out and that Radarr is still looking for.";
            targets = [(pq "max(${s sel "radarr_movie_missing_total"})" "")];
            thresholds = thresholdsGreenRed [
              {
                color = "orange";
                value = 1;
              }
            ];
          })
          (stat {
            title = "Waiting for a better copy";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "radarr_movie_cutoff_unmet_total"})" "")];
          })
          (stat {
            title = "Downloading";
            w = 4;
            h = 4;
            targets = [(pq "sum(${s sel "radarr_queue_total"}) or vector(0)" "")];
          })
          (stat {
            title = "Problems";
            w = 4;
            h = 4;
            description = "Warnings and errors on Radarr's System → Status page.";
            targets = [(pq ''count(radarr_system_health_issues{${sel}, type=~"warning|error"}) or vector(0)'' "")];
            thresholds = thresholdsGreenRed [
              {
                color = "red";
                value = 1;
              }
            ];
          })
          (bars {
            title = "Films added to the library";
            interval = "1h";
            targets = [(pq "clamp_min(max(delta(${s sel "radarr_movie_downloaded_total"}[$__interval])), 0)" "films")];
          })
          (timeseries {
            title = "Download queue by state";
            targets = [(pq "sum by (download_state) (${s sel "radarr_queue_total"})" "{{download_state}}")];
          })
          (bargauge {
            title = "Free space";
            unit = "bytes";
            targets = [(pq "min by (path) (${s sel "radarr_rootfolder_freespace_bytes"})" "{{path}}")];
          })
          (table {
            title = "Problems Radarr reports";
            targets = [
              (pqInstant "max by (type, source, message) (${s sel "radarr_system_health_issues"})" "")
            ];
          })
        ];
    };
  };
}
