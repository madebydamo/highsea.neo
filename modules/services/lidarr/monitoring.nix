# Lidarr metrics (exportarr sidecar), dashboard and alerts. Builder: _lib.nix arrMonitoring.
{...}: {
  neoPlugin.modules.lidarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "lidarr";
    title = "Lidarr${plugin.label}";
    s = sel: m: "${m}{${sel}}";
  in {
    config = hs.arrMonitoring {
      inherit config plugin;
      svc = "lidarr";
      label = "Lidarr";
      description = "Your music: artists, albums, what is missing, what is downloading, free space, and Lidarr's errors.";
      port = 8686;
      apiKey = config.neo.services.${name}.apiKey;
      alerts = hs.diskAlert {
        svc = "lidarr";
        inherit name title;
      };
      headline = sel:
        with lib.neo.grafana; [
          (row "Library" null)
          (stat {
            title = "Artists";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "lidarr_artists_total"})" "")];
          })
          (stat {
            title = "Songs on disk";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "lidarr_songs_downloaded_total"})" "")];
          })
          (stat {
            title = "Missing albums";
            w = 4;
            h = 4;
            description = "Albums that are out and that Lidarr is still looking for.";
            targets = [(pq "max(${s sel "lidarr_albums_missing_total"})" "")];
            thresholds = thresholdsGreenRed [
              {
                color = "orange";
                value = 1;
              }
            ];
          })
          (stat {
            title = "Albums";
            w = 4;
            h = 4;
            targets = [(pq "max(${s sel "lidarr_albums_total"})" "")];
          })
          (stat {
            title = "Downloading";
            w = 4;
            h = 4;
            targets = [(pq "sum(${s sel "lidarr_queue_total"}) or vector(0)" "")];
          })
          (stat {
            title = "Problems";
            w = 4;
            h = 4;
            description = "Warnings and errors on Lidarr's System → Status page.";
            targets = [(pq ''count(lidarr_system_health_issues{${sel}, type=~"warning|error"}) or vector(0)'' "")];
            thresholds = thresholdsGreenRed [
              {
                color = "red";
                value = 1;
              }
            ];
          })
          (bars {
            title = "Songs added to the library";
            interval = "1h";
            targets = [(pq "clamp_min(max(delta(${s sel "lidarr_songs_downloaded_total"}[$__interval])), 0)" "songs")];
          })
          (timeseries {
            title = "Download queue by state";
            targets = [(pq "sum by (download_state) (${s sel "lidarr_queue_total"})" "{{download_state}}")];
          })
          (bargauge {
            title = "Free space";
            unit = "bytes";
            targets = [(pq "min by (path) (${s sel "lidarr_rootfolder_freespace_bytes"})" "{{path}}")];
          })
          (table {
            title = "Problems Lidarr reports";
            targets = [
              (pqInstant "max by (type, source, message) (${s sel "lidarr_system_health_issues"})" "")
            ];
          })
        ];
    };
  };
}
