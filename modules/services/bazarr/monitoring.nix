# Bazarr metrics (exportarr sidecar), dashboard and alerts. Builder: _lib.nix arrMonitoring.
{...}: {
  neoPlugin.modules.bazarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "bazarr";
  in {
    config = hs.arrMonitoring {
      inherit config plugin;
      svc = "bazarr";
      label = "Bazarr";
      description = "Subtitles: what is missing, what was found, from which providers and in which languages.";
      port = 6767;
      apiKey = config.neo.services.${name}.apiKey;
      headline = sel:
        with lib.neo.grafana; [
          (row "Subtitles" null)
          (stat {
            title = "Missing for episodes";
            w = 6;
            h = 4;
            targets = [(pq "max(bazarr_episode_subtitles_missing_total{${sel}})" "")];
          })
          (stat {
            title = "Missing for films";
            w = 6;
            h = 4;
            targets = [(pq "max(bazarr_movie_subtitles_missing_total{${sel}})" "")];
          })
          (stat {
            title = "Downloaded";
            w = 6;
            h = 4;
            targets = [(pq "max(bazarr_subtitles_downloaded_total{${sel}})" "")];
          })
          (stat {
            title = "Problems";
            w = 6;
            h = 4;
            description = "Problems Bazarr reports on its System → Status page.";
            targets = [(pq "count(bazarr_system_health_issues{${sel}} > 0) or vector(0)" "")];
            thresholds = thresholdsGreenRed [
              {
                color = "red";
                value = 1;
              }
            ];
          })
          (timeseries {
            title = "Missing subtitles";
            targets = [
              (pq "max(bazarr_episode_subtitles_missing_total{${sel}})" "episodes")
              (pq "max(bazarr_movie_subtitles_missing_total{${sel}})" "films")
            ];
          })
          (bargauge {
            title = "Subtitles by provider";
            targets = [(pq "sort_desc(max by (provider) (bazarr_subtitles_provider_total{${sel}}))" "{{provider}}")];
          })
          (bargauge {
            title = "Subtitles by language";
            targets = [(pq "sort_desc(max by (language) (bazarr_subtitles_language_total{${sel}}))" "{{language}}")];
          })
        ];
    };
  };
}
