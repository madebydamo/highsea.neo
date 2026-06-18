# declarr service implementation. Generates config from enabled high_sea *arr services and auto-wires qbittorrent + prowlarr apps + seerr.
{...}: {
  flake.modules.nixos.declarr = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.neo.services.declarr;
      hs = config.neo.services;

      # Stable defaults for auto-linking (override via settings if wanted)
      defaultApiKey = "d3c1arrh0m3s3rv3r4p1k3y32ch4rsabcd";
      qbitUser = "admin";
      qbitPass = "adminadmin";

      appdata = "${config.neo.core.volumes.appdata}/declarr";
      configFile = "${appdata}/config.json";

      # Build declarr config sections only for enabled relevant services
      arrConfig =
        {
          declarr = {
            stateDir = cfg.stateDir;
            formatDbRepo = "https://github.com/Dictionarry-Hub/Database";
            formatDbBranch = "stable";
            globalResolvePaths = [
              "$.*.config.host.password"
              "$.*.config.host.passwordConfirmation"
              "$.*.config.host.apiKey"
              "$.*.applications.*.fields.apiKey"
              "$.*.indexer.*.fields.password"
              "$.*.downloadClient.*.fields.password"
            ];
          };
        }
        // optionalAttrs hs.sonarr.enabled {
          sonarr = {
            declarr = {
              type = "sonarr";
              url = "http://sonarr:8989";
            };
            rootFolder = ["/tv"];
            downloadClient = optionalAttrs hs.qbittorrent.enabled {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = "qbittorrent";
                  port = 8082;
                  username = qbitUser;
                  password = qbitPass;
                  sequentialOrder = true;
                };
              };
            };
            customFormat = {};
            qualityProfile = {
              "1080p Balanced" = {};
              "1080p Quality" = {};
              "2160p Balanced" = {};
              "2160p Quality" = {};
            };
            qualityDefinition = {
              HDTV-720p = {
                minSize = 10;
                preferredSize = 995;
                maxSize = 1000;
              };
              HDTV-1080p = {
                minSize = 15;
                preferredSize = 995;
                maxSize = 1000;
              };
              WEBRip-720p = {
                minSize = 10;
                preferredSize = 995;
                maxSize = 1000;
              };
              WEBDL-720p = {
                minSize = 10;
                preferredSize = 995;
                maxSize = 1000;
              };
              Bluray-720p = {
                minSize = 17.1;
                preferredSize = 995;
                maxSize = 1000;
              };
              WEBRip-1080p = {
                minSize = 15;
                preferredSize = 995;
                maxSize = 1000;
              };
              WEBDL-1080p = {
                minSize = 15;
                preferredSize = 995;
                maxSize = 1000;
              };
              Bluray-1080p = {
                minSize = 50.4;
                preferredSize = 995;
                maxSize = 1000;
              };
              "Bluray-1080p Remux" = {
                minSize = 69.1;
                preferredSize = 995;
                maxSize = 1000;
              };
              HDTV-2160p = {
                minSize = 25;
                preferredSize = 995;
                maxSize = 1000;
              };
              WEBRip-2160p = {
                minSize = 25;
                preferredSize = 995;
                maxSize = 1000;
              };
              WEBDL-2160p = {
                minSize = 25;
                preferredSize = 995;
                maxSize = 1000;
              };
              Bluray-2160p = {
                minSize = 94.6;
                preferredSize = 995;
                maxSize = 1000;
              };
              "Bluray-2160p Remux" = {
                minSize = 187.4;
                preferredSize = 995;
                maxSize = 1000;
              };
            };
            config = {
              ui = {
                firstDayOfWeek = 1;
                theme = "dark";
                timeFormat = "HH:mm";
              };
              host = {
                apiKey = defaultApiKey;
                analyticsEnabled = false;
                authenticationMethod = "forms";
                authenticationRequired = "enabled";
                username = "admin";
                password = "adminadmin";
                passwordConfirmation = "adminadmin";
                backupInterval = 7;
                backupRetention = 28;
                port = 8989;
                urlBase = "";
                bindAddress = "*";
                proxyEnabled = false;
                sslCertPath = "";
                sslCertPassword = "";
                instanceName = "Sonarr";
                branch = "main";
                logLevel = "debug";
                consoleLogLevel = "";
                logSizeLimit = 1;
                updateScriptPath = "";
              };
              naming = {
                renameEpisodes = true;
                replaceIllegalCharacters = true;
                colonReplacementFormat = 4;
                multiEpisodeStyle = 5;
                standardEpisodeFormat = "s{season:00}e{episode:00} - {Episode Title} {Quality Title} {MediaInfo VideoCodec}";
                dailyEpisodeFormat = "{Air-Date} - {Episode Title} {Quality Title} {MediaInfo VideoCodec}";
                animeEpisodeFormat = "s{season:00}e{episode:00} - {Episode Title} {Quality Title} {MediaInfo VideoCodec}";
                seriesFolderFormat = "{Series Title}";
                seasonFolderFormat = "Season {season}";
                specialsFolderFormat = "Specials";
              };
              mediamanagement = {
                autoUnmonitorPreviouslyDownloadedEpisodes = false;
                setPermissionsLinux = false;
                chmodFolder = "755";
                chownGroup = "";
                createEmptySeriesFolders = true;
                deleteEmptyFolders = false;
                enableMediaInfo = true;
                episodeTitleRequired = "always";
                extraFileExtensions = "srt";
                fileDate = "none";
                recycleBin = "";
                recycleBinCleanupDays = 7;
                rescanAfterRefresh = "always";
                downloadPropersAndRepacks = "preferAndUpgrade";
                copyUsingHardlinks = true;
                minimumFreeSpaceWhenImporting = 100;
                skipFreeSpaceCheckWhenImporting = false;
                importExtraFiles = false;
                useScriptImport = false;
                scriptImportPath = "";
              };
            };
          };
        }
        // optionalAttrs hs.radarr.enabled {
          radarr = {
            declarr = {
              type = "radarr";
              url = "http://radarr:7878";
            };
            rootFolder = ["/movies"];
            downloadClient = optionalAttrs hs.qbittorrent.enabled {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = "qbittorrent";
                  port = 8082;
                  username = qbitUser;
                  password = qbitPass;
                  sequentialOrder = true;
                };
              };
            };
            customFormat = {};
            qualityProfile = {
              "1080p Balanced" = {};
              "1080p Quality" = {};
              "2160p Balanced" = {};
              "2160p Quality" = {};
            };
            qualityDefinition = {
              HDTV-720p = {
                minSize = 17.1;
                preferredSize = 1999;
                maxSize = 2000;
              };
              WEBDL-720p = {
                minSize = 12.5;
                preferredSize = 1999;
                maxSize = 2000;
              };
              WEBRip-720p = {
                minSize = 12.5;
                preferredSize = 1999;
                maxSize = 2000;
              };
              Bluray-720p = {
                minSize = 25.7;
                preferredSize = 1999;
                maxSize = 2000;
              };
              HDTV-1080p = {
                minSize = 33.8;
                preferredSize = 1999;
                maxSize = 2000;
              };
              WEBDL-1080p = {
                minSize = 12.5;
                preferredSize = 1999;
                maxSize = 2000;
              };
              WEBRip-1080p = {
                minSize = 12.5;
                preferredSize = 1999;
                maxSize = 2000;
              };
              Bluray-1080p = {
                minSize = 50.8;
                preferredSize = 1999;
                maxSize = 2000;
              };
              Remux-1080p = {
                minSize = 102;
                preferredSize = 1999;
                maxSize = 2000;
              };
              HDTV-2160p = {
                minSize = 85;
                preferredSize = 1999;
                maxSize = 2000;
              };
              WEBDL-2160p = {
                minSize = 34.5;
                preferredSize = 1999;
                maxSize = 2000;
              };
              WEBRip-2160p = {
                minSize = 34.5;
                preferredSize = 1999;
                maxSize = 2000;
              };
              Bluray-2160p = {
                minSize = 102;
                preferredSize = 1999;
                maxSize = 2000;
              };
              Remux-2160p = {
                minSize = 187.4;
                preferredSize = 1999;
                maxSize = 2000;
              };
            };
            config = {
              ui = {
                firstDayOfWeek = 1;
                theme = "dark";
                timeFormat = "HH:mm";
              };
              host = {
                apiKey = defaultApiKey;
                analyticsEnabled = false;
                authenticationMethod = "forms";
                authenticationRequired = "enabled";
                username = "admin";
                password = "adminadmin";
                passwordConfirmation = "adminadmin";
                backupInterval = 7;
                backupRetention = 28;
                port = 7878;
                urlBase = "";
                bindAddress = "*";
                proxyEnabled = false;
                sslCertPath = "";
                sslCertPassword = "";
                instanceName = "Radarr";
                branch = "main";
                logLevel = "debug";
                consoleLogLevel = "";
                logSizeLimit = 1;
                updateScriptPath = "";
              };
              naming = {
                renameMovies = true;
                replaceIllegalCharacters = true;
                standardMovieFormat = "{Movie Title} ({Release Year}) {Quality Title} {MediaInfo VideoCodec}";
                movieFolderFormat = "{Movie Title} ({Release Year})";
              };
              mediamanagement = {
                autoUnmonitorPreviouslyDownloadedEpisodes = false;
                chmodFolder = "755";
                chownGroup = "";
                copyUsingHardlinks = true;
                createEmptySeriesFolders = true;
                deleteEmptyFolders = false;
                downloadPropersAndRepacks = "preferAndUpgrade";
                enableMediaInfo = true;
                episodeTitleRequired = "always";
                extraFileExtensions = "srt";
                fileDate = "none";
                importExtraFiles = false;
                minimumFreeSpaceWhenImporting = 100;
                recycleBin = "";
                recycleBinCleanupDays = 7;
                rescanAfterRefresh = "always";
                scriptImportPath = "";
                setPermissionsLinux = false;
                skipFreeSpaceCheckWhenImporting = false;
                useScriptImport = false;
              };
            };
          };
        }
        // optionalAttrs hs.prowlarr.enabled {
          prowlarr = {
            declarr = {
              type = "prowlarr";
              url = "http://prowlarr:9696";
            };
            config = {
              ui = {
                firstDayOfWeek = 1;
                theme = "dark";
                timeFormat = "HH:mm";
              };
              host = {
                apiKey = defaultApiKey;
                analyticsEnabled = false;
                authenticationMethod = "forms";
                authenticationRequired = "enabled";
                backupInterval = 7;
                backupRetention = 28;
                port = 9696;
                urlBase = "";
                bindAddress = "*";
                proxyEnabled = false;
                sslCertPath = "";
                sslCertPassword = "";
                instanceName = "Prowlarr";
                branch = "main";
                logLevel = "debug";
                consoleLogLevel = "";
                logSizeLimit = 1;
                updateScriptPath = "";
              };
            };
            downloadClient = optionalAttrs hs.qbittorrent.enabled {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = "qbittorrent";
                  port = 8082;
                  username = qbitUser;
                  password = qbitPass;
                  sequentialOrder = true;
                };
              };
            };
            appProfile = {
              Standard = {
                enableAutomaticSearch = true;
                enableInteractiveSearch = true;
                enableRss = true;
                minimumSeeders = 1;
              };
              Automatic = {
                enableAutomaticSearch = true;
                enableInteractiveSearch = false;
                enableRss = true;
                minimumSeeders = 1;
              };
              "Interactive Search" = {
                enableAutomaticSearch = false;
                enableInteractiveSearch = true;
                enableRss = false;
                minimumSeeders = 1;
              };
            };
            applications =
              (optionalAttrs hs.sonarr.enabled {
                Sonarr = {
                  syncLevel = "fullSync";
                  implementation = "Sonarr";
                  fields = {
                    prowlarrUrl = "http://prowlarr:9696";
                    baseUrl = "http://sonarr:8989";
                    apiKey = defaultApiKey;
                  };
                };
              })
              // (optionalAttrs hs.radarr.enabled {
                Radarr = {
                  syncLevel = "fullSync";
                  implementation = "Radarr";
                  fields = {
                    prowlarrUrl = "http://prowlarr:9696";
                    baseUrl = "http://radarr:7878";
                    apiKey = defaultApiKey;
                  };
                };
              });
            # basic public indexers (no auth) for out-of-box; user can extend via extra
            indexer = {
              "LimeTorrents" = {
                indexerName = "LimeTorrents";
                implementation = "Cardigann";
                priority = 30;
                fields = {
                  definitionFile = "limetorrents";
                  downloadlink = 1;
                  downloadlink2 = 0;
                  "torrentBaseSettings.seedRatio" = 10;
                };
                appProfileId = "Interactive Search";
              };
              "The Pirate Bay" = {
                indexerName = "The Pirate Bay";
                implementation = "Cardigann";
                priority = 30;
                fields = {
                  definitionFile = "thepiratebay";
                  "torrentBaseSettings.seedRatio" = 10;
                };
                appProfileId = "Interactive Search";
              };
              "YTS" = {
                indexerName = "YTS";
                implementation = "Cardigann";
                priority = 30;
                fields = {
                  definitionFile = "yts";
                  "torrentBaseSettings.seedRatio" = 10;
                };
                appProfileId = "Interactive Search";
              };
            };
          };
        }
        // optionalAttrs (hs.seerr.enabled or false) {
          # jellyseerr under seerr key for declarr
          jellyseerr = {
            declarr = {
              type = "jellyseerr";
              url = "http://seerr:5055";
              port = 5055;
              stateDir = "${appdata}/jellyseerr";
            };
            # Minimal to link; declarr will init and sync
            jellyfin = {
              # Will be configured interactively or via extra; basic hook
              ip = "jellyfin";
              port = 8096;
              useSsl = false;
            };
            sonarr = lib.optionals (hs.sonarr.enabled or false) [
              {
                activeProfileName = "1080p Balanced";
                apiKey = defaultApiKey;
                hostname = "sonarr";
                port = 8989;
                baseUrl = "";
                activeDirectory = "/tv";
                activeProfileId = 0;
                activeServerId = 0;
              }
            ];
            radarr = lib.optionals (hs.radarr.enabled or false) [
              {
                activeProfileName = "1080p Balanced";
                apiKey = defaultApiKey;
                hostname = "radarr";
                port = 7878;
                baseUrl = "";
                activeDirectory = "/movies";
                activeProfileId = 0;
                activeServerId = 0;
              }
            ];
          };
        };

      fullConfig = recursiveUpdate arrConfig (cfg.extraConfig or {});

      preStart = lib.concatStringsSep "\n" [
        (lib.neo.mkActivationScriptForDir config {dirPath = appdata;})
        (lib.neo.mkActivationScriptForDir config {dirPath = cfg.stateDir;})
        (lib.neo.mkActivationScriptForFile config {
          filePath = configFile;
          content = builtins.toJSON fullConfig;
          mode = "0644";
        })
      ];
    in {
      config = mkIf cfg.enabled {
        systemd.services.declarr = {
          after =
            (optionals hs.sonarr.enabled ["docker-sonarr.service"])
            ++ (optionals hs.radarr.enabled ["docker-radarr.service"])
            ++ (optionals hs.prowlarr.enabled ["docker-prowlarr.service"])
            ++ (optionals hs.qbittorrent.enabled ["docker-qbittorrent.service"])
            ++ (optionals (hs.seerr.enabled or false) ["docker-seerr.service" "docker-jellyfin.service"]);
          wants = ["docker.service"];
          wantedBy = ["multi-user.target"];
          inherit preStart;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "root";
          };
          script = ''
            echo "Running declarr sync for high_sea *arr stack..."
            ${pkgs.nix}/bin/nix run github:upidapi/declarr -- --sync ${configFile}
            echo "declarr sync complete."
          '';
        };
      };
    };
}

