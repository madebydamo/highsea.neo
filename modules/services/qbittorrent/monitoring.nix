# qBittorrent metrics (prometheus-qbittorrent-exporter sidecar), its
# dashboard, the "Media pipeline" overview and alerts.
#
# The exporter sits on qBittorrent's network, not VPN-routed, and signs in
# with the Web UI user and password (rendered env file). It reports whether
# qBittorrent is connected and whether incoming connections reach it
# (firewalled = the VPN's forwarded port does not arrive), which is what
# qbittorrent-portcheck guesses at.
#
# Media pipeline: one overview across the plugin's apps (searches → grabs →
# downloads → imports, problems, free space). It lives here because every
# download goes through qBittorrent; its server list comes from qBittorrent's
# metrics, its queries name each app's service.
{...}: {
  neoPlugin.modules.qbittorrent-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "qbittorrent";
    cfg = config.neo.services.${name};
    exporter = "${name}-exporter";
    collecting = config.neo.monitoring.collecting;
    title = "qBittorrent${plugin.label}";
    sel = lib.neo.grafana.appSelector name;
    asel = lib.neo.grafana.alertSelector name;
    N = lib.genAttrs ["sonarr" "radarr" "lidarr" "prowlarr" "bazarr" "flaresolverr" "listenarr" "seerr" "jellyfin"] plugin.name;
    svcSel = svcs: ''service=~"${lib.concatStringsSep "|" (map (s: N.${s} or name) svcs)}", host=~"$host"'';
    arrs = svcSel ["sonarr" "radarr" "lidarr"];
    stalled = ''status=~"stalledDL"'';
    downloading = ''status=~"downloading|forcedDL|metaDL|checkingDL|queuedDL"'';
  in {
    config = lib.mkMerge [
      {neo.services.${name}.systemdUnits = lib.mkIf collecting (lib.mkOptionDefault ["docker-${exporter}"]);}
      (lib.mkIf (cfg.enabled && collecting) {
        virtualisation.oci-containers.containers.${exporter} = {
          image = hs.images.qbittorrentExporter;
          environment = {
            QBITTORRENT_HOST = name;
            QBITTORRENT_PORT = toString cfg.webPort;
            QBITTORRENT_USER = cfg.username;
            EXPORTER_PORT = "8000";
            EXPORTER_LOG_LEVEL = "INFO";
          };
          networks = [(lib.neo.docker.serviceNetwork name)];
          dependsOn = [name];
        };
        neo.core.secrets.containerEnv.${exporter}.QBITTORRENT_PASS = hs.qbitPassword config name;
      })
      (lib.mkIf cfg.enabled {
        neo.monitoring.apps.${name} = {
          metrics.main = {
            container = exporter;
            port = 8000;
            network = lib.neo.docker.serviceNetwork name;
          };

          dashboards.overview = {
            inherit title;
            description = "Downloads: what is running, stuck or done, speed, and whether other peers can reach qBittorrent through the VPN.";
            time = "now-7d";
            panels = with lib.neo.grafana;
              [
                (row "Downloads" null)
                (stat {
                  title = "Incoming connections";
                  w = 4;
                  h = 4;
                  description = "Open: peers reach qBittorrent through the VPN's forwarded port. Blocked: downloads are slow; check the VPN's port forwarding and the incoming connections port.";
                  targets = [(pq "min(qbittorrent_connected{${sel}} * (1 - qbittorrent_firewalled{${sel}}))" "")];
                  mappings = [
                    {
                      type = "value";
                      options = {
                        "0".text = "Blocked";
                        "1".text = "Open";
                      };
                    }
                  ];
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
                  title = "Downloading";
                  w = 4;
                  h = 4;
                  targets = [(pq "sum(qbittorrent_torrents_count{${sel}, ${downloading}}) or vector(0)" "")];
                })
                (stat {
                  title = "Stuck";
                  w = 4;
                  h = 4;
                  description = "Downloads that find no one to download from.";
                  targets = [(pq "sum(qbittorrent_torrents_count{${sel}, ${stalled}}) or vector(0)" "")];
                  thresholds = thresholdsGreenRed [
                    {
                      color = "orange";
                      value = 1;
                    }
                  ];
                })
                (stat {
                  title = "Downloaded";
                  w = 4;
                  h = 4;
                  unit = "bytes";
                  description = "Data downloaded in the chosen time range.";
                  targets = [(pq "sum(increase(qbittorrent_dl_info_data_total{${sel}}[$__range]))" "")];
                })
                (stat {
                  title = "Share ratio";
                  w = 4;
                  h = 4;
                  decimals = 2;
                  description = "Uploaded divided by downloaded, all time.";
                  targets = [(pq "max(qbittorrent_alltime_ul_total{${sel}}) / clamp_min(max(qbittorrent_alltime_dl_total{${sel}}), 1)" "")];
                })
                (stat {
                  title = "Peers";
                  w = 4;
                  h = 4;
                  targets = [(pq "max(qbittorrent_total_peer_connections{${sel}})" "")];
                })
                (timeseries {
                  title = "Speed";
                  unit = "Bps";
                  targets = [
                    (pq "sum(rate(qbittorrent_dl_info_data_total{${sel}}[$__rate_interval]))" "download")
                    (pq "sum(rate(qbittorrent_up_info_data_total{${sel}}[$__rate_interval]))" "upload")
                  ];
                })
                (timeseries {
                  title = "Torrents by state";
                  targets = [(pq "sum by (status) (qbittorrent_torrents_count{${sel}})" "{{status}}")];
                })
                (bargauge {
                  title = "Torrents by app";
                  description = "By category: the media apps each use their own.";
                  targets = [(pq "sort_desc(sum by (category) (qbittorrent_torrents_count{${sel}}))" "{{category}}")];
                })
                (stateTimeline {
                  title = "Connection";
                  targets = [
                    (pq "min(qbittorrent_connected{${sel}})" "connected")
                    (pq "max(qbittorrent_firewalled{${sel}})" "blocked from outside")
                  ];
                })
                (bars {
                  title = "Restarts by the port check";
                  datasource = loki;
                  interval = "1h";
                  description = "qBittorrent was restarted because its incoming connections port was closed.";
                  targets = [(lqLegend ''sum(count_over_time({job="journal", host=~"$host", unit="${name}-portcheck.service"} |= "closed" [$__interval]))'' "restarts")];
                })
                (timeseries {
                  title = "Traffic through the VPN";
                  unit = "Bps";
                  description = "All VPN-routed apps share this tunnel.";
                  targets = [
                    (pq ''sum(rate(container_network_receive_bytes_total{host=~"$host", name="vpn"}[$__rate_interval]))'' "in")
                    (pq ''sum(rate(container_network_transmit_bytes_total{host=~"$host", name="vpn"}[$__rate_interval]))'' "out")
                  ];
                })
              ]
              ++ lib.neo.grafana.app.web {service = name;}
              ++ lib.neo.grafana.app.errors {
                service = name;
                containers = [name];
                units = ["${name}-portcheck"];
                filter = hs.filters.generic;
                metrics = false;
              }
              ++ hs.resources [name exporter];
          };

          dashboards.pipeline = {
            title = "Media pipeline${plugin.label}";
            description = "From wish to library across the media apps: searches, grabs, downloads, imports, problems and free space.";
            time = "now-7d";
            panels = with lib.neo.grafana; [
              (row "At a glance" null)
              (stat {
                title = "Missing";
                w = 4;
                h = 4;
                description = "Episodes, films and albums the apps are still looking for.";
                targets = [(pq "(sum(max by (service) (sonarr_episode_missing_total{${arrs}})) or vector(0)) + (sum(max by (service) (radarr_movie_missing_total{${arrs}})) or vector(0)) + (sum(max by (service) (lidarr_albums_missing_total{${arrs}})) or vector(0))" "")];
              })
              (stat {
                title = "Searches";
                w = 4;
                h = 4;
                decimals = 0;
                targets = [(pq "sum(delta(prowlarr_indexer_queries_total{${svcSel ["prowlarr"]}}[$__range])) or vector(0)" "")];
              })
              (stat {
                title = "Grabs";
                w = 4;
                h = 4;
                decimals = 0;
                targets = [(pq "sum(delta(prowlarr_indexer_grabs_total{${svcSel ["prowlarr"]}}[$__range])) or vector(0)" "")];
              })
              (stat {
                title = "Downloading";
                w = 4;
                h = 4;
                targets = [(pq "sum(qbittorrent_torrents_count{${sel}, ${downloading}}) or vector(0)" "")];
              })
              (stat {
                title = "Stuck downloads";
                w = 4;
                h = 4;
                targets = [(pq "sum(qbittorrent_torrents_count{${sel}, ${stalled}}) or vector(0)" "")];
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
                description = "Warnings and errors the apps report on their System → Status pages.";
                targets = [(pq ''count({__name__=~"(sonarr|radarr|lidarr|prowlarr)_system_health_issues", ${svcSel ["sonarr" "radarr" "lidarr" "prowlarr"]}, type=~"warning|error"}) or vector(0)'' "")];
                thresholds = thresholdsGreenRed [
                  {
                    color = "red";
                    value = 1;
                  }
                ];
              })
              (row "Flow" null)
              (bars {
                title = "Searches and grabs";
                interval = "1h";
                targets = [
                  (pq "clamp_min(sum(delta(prowlarr_indexer_queries_total{${svcSel ["prowlarr"]}}[$__interval])), 0)" "searches")
                  (pq "clamp_min(sum(delta(prowlarr_indexer_grabs_total{${svcSel ["prowlarr"]}}[$__interval])), 0)" "grabs")
                ];
              })
              (bars {
                title = "Added to the library";
                interval = "1h";
                targets = [
                  (pq "clamp_min(sum(delta(sonarr_episode_downloaded_total{${arrs}}[$__interval])), 0)" "episodes")
                  (pq "clamp_min(sum(delta(radarr_movie_downloaded_total{${arrs}}[$__interval])), 0)" "films")
                  (pq "clamp_min(sum(delta(lidarr_songs_downloaded_total{${arrs}}[$__interval])), 0)" "songs")
                ];
              })
              (timeseries {
                title = "Queues of the apps";
                targets = [(pq ''sum by (service) ({__name__=~"(sonarr|radarr|lidarr)_queue_total", ${arrs}})'' "{{service}}")];
              })
              (timeseries {
                title = "Download speed";
                unit = "Bps";
                targets = [(pq "sum(rate(qbittorrent_dl_info_data_total{${sel}}[$__rate_interval]))" "download")];
              })
              (row "Sites and bot checks" null)
              (bargauge {
                title = "Failed searches per site";
                targets = [(pq "sort_desc(sum by (indexer) (delta(prowlarr_indexer_failed_queries_total{${svcSel ["prowlarr"]}}[$__range])) > 0)" "{{indexer}}")];
              })
              (bargauge {
                title = "Bot checks by result";
                targets = [(pq "sum by (result) (increase(flaresolverr_request_total{${svcSel ["flaresolverr"]}}[$__range]))" "{{result}}")];
              })
              (row "Library and space" null)
              (bargauge {
                title = "Free space";
                unit = "bytes";
                targets = [(pq ''min by (path) ({__name__=~"(sonarr|radarr|lidarr)_rootfolder_freespace_bytes", ${arrs}})'' "{{path}}")];
                thresholds = {
                  mode = "absolute";
                  steps = [
                    {
                      color = "red";
                      value = null;
                    }
                    {
                      color = "orange";
                      value = 53687091200;
                    }
                    {
                      color = "green";
                      value = 214748364800;
                    }
                  ];
                };
              })
              (bargauge {
                title = "Missing subtitles";
                targets = [
                  (pq "max(bazarr_episode_subtitles_missing_total{${svcSel ["bazarr"]}})" "episodes")
                  (pq "max(bazarr_movie_subtitles_missing_total{${svcSel ["bazarr"]}})" "films")
                ];
              })
              (table {
                title = "Problems the apps report";
                w = 24;
                targets = [(pqInstant ''max by (service, type, source, message) ({__name__=~"(sonarr|radarr|lidarr|prowlarr)_system_health_issues", ${svcSel ["sonarr" "radarr" "lidarr" "prowlarr"]}})'' "")];
              })
              (logs {
                title = "Errors across the apps";
                w = 24;
                targets = [(lq ''{job="journal", host=~"$host", unit=~"docker-(${lib.concatStringsSep "|" (map (s: N.${s}) ["sonarr" "radarr" "lidarr" "prowlarr"])})[.]service"} ${hs.filters.servarr}'')];
              })
            ];
          };

          alerts =
            lib.neo.monitoring.appAlerts {
              service = name;
              label = title;
              containers = [name];
              units = ["${name}-portcheck"];
              errorFilter = hs.filters.generic;
            }
            // {
              port-closed = {
                title = "${title}: incoming connections blocked";
                expr = ''max by (host) (qbittorrent_firewalled{${asel}})'';
                above = 0;
                for = "30m";
                summary = "Peers cannot reach ${title} on {{ $labels.host }} for 30 minutes: the VPN's forwarded port does not match the incoming connections port, so downloads are slow.";
              };
              disconnected = {
                title = "${title}: not connected";
                expr = ''min by (host) (qbittorrent_connected{${asel}})'';
                below = 1;
                for = "15m";
                severity = "critical";
                summary = "${title} on {{ $labels.host }} has no connection to the torrent network for 15 minutes; downloads stopped (VPN down?).";
              };
              stalled = {
                title = "${title}: downloads stuck";
                expr = ''sum by (host) (qbittorrent_torrents_count{${asel}, ${stalled}})'';
                above = 0;
                for = "24h";
                summary = "{{ printf \"%.0f\" $values.B.Value }} downloads in ${title} on {{ $labels.host }} found no one to download from for a day; remove them or search for another release.";
              };
              portcheck-restarts = {
                title = "${title}: restarted often by the port check";
                datasource = "loki";
                expr = ''sum by (host) (count_over_time({job="journal", unit="${name}-portcheck.service"} |= "closed" [24h]))'';
                above = 3;
                for = "0s";
                summary = "The port check restarted ${title} on {{ $labels.host }} {{ printf \"%.0f\" $values.B.Value }} times in a day: the VPN keeps losing the forwarded port.";
              };
            };
        };
      })
    ];
  };
}
