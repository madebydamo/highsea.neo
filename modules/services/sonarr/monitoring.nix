# Sonarr metrics (exportarr sidecar), dashboard and alerts. Builder: _lib.nix arrMonitoring.
{...}: {
  neoPlugin.modules.sonarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "sonarr";
    title = "Sonarr${plugin.label}";
    s = sel: m: "${m}{${sel}}";
  in {
    config = hs.arrMonitoring {
      inherit config plugin;
      svc = "sonarr";
      label = "Sonarr";
      description = "Your shows: what is on disk, what is missing, what is downloading, free space, and Sonarr's errors.";
      port = 8989;
      apiKey = config.neo.services.${name}.apiKey;
      exporterEnv.ENABLE_ADDITIONAL_METRICS = "true";
      alerts = hs.diskAlert {
        svc = "sonarr";
        inherit name title;
      };
      headline = sel:
        with lib.neo.grafana; [
          (row "Library" null)
          (stat {
            title = "Shows";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "sonarr_series_total"})" "")];
          })
          (stat {
            title = "Episodes on disk";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "sonarr_episode_downloaded_total"})" "")];
          })
          (stat {
            title = "Missing episodes";
            w = 4;
            h = 4;
            description = "Episodes that aired and that Sonarr is still looking for.";
            targets = [(pq "max(${s sel "sonarr_episode_missing_total"})" "")];
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
            targets = [(pq "max(${s sel "sonarr_episode_cutoff_unmet_total"})" "")];
          })
          (stat {
            title = "Downloading";
            w = 4;
            h = 4;
            targets = [(pq "sum(${s sel "sonarr_queue_total"}) or vector(0)" "")];
          })
          (stat {
            title = "Problems";
            w = 4;
            h = 4;
            description = "Warnings and errors on Sonarr's System → Status page.";
            targets = [(pq ''count(sonarr_system_health_issues{${sel}, type=~"warning|error"}) or vector(0)'' "")];
            thresholds = thresholdsGreenRed [
              {
                color = "red";
                value = 1;
              }
            ];
          })
          (bars {
            title = "Episodes added to the library";
            interval = "1h";
            targets = [(pq "clamp_min(max(delta(${s sel "sonarr_episode_downloaded_total"}[$__interval])), 0)" "episodes")];
          })
          (timeseries {
            title = "Download queue by state";
            targets = [(pq "sum by (download_state) (${s sel "sonarr_queue_total"})" "{{download_state}}")];
          })
          (bargauge {
            title = "Free space";
            unit = "bytes";
            targets = [(pq "min by (path) (${s sel "sonarr_rootfolder_freespace_bytes"})" "{{path}}")];
          })
          (table {
            title = "Problems Sonarr reports";
            targets = [
              (pqInstant "max by (type, source, message) (${s sel "sonarr_system_health_issues"})" "")
            ];
          })
        ];
    };
  };
}
