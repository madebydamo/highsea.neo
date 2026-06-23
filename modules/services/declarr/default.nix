# declarr service implementation. Generates config from enabled high_sea *arr services and auto-wires qbittorrent + prowlarr apps + seerr.
{inputs, ...}: {
  flake.modules.nixos.declarr = {
    config,
    lib,
    pkgs,
    ...
  }:
    with lib; let
      cfg = config.neo.services.declarr;
      hs = config.neo.services;
      declarrPkg = inputs.declarr.packages.${pkgs.stdenv.hostPlatform.system}.declarr;
      defaultApiKey = "d3c1arrh0m3s3rv3r4p1k3y32ch4rsabcd";
      qbitUser = hs.qbittorrent.username or "admin";
      qbitPass = hs.qbittorrent.password or "adminadmin";
      sonarrApiKey =
        if (hs.sonarr.enabled or false) && (hs.sonarr.apiKey or null) != null
        then hs.sonarr.apiKey
        else defaultApiKey;
      radarrApiKey =
        if (hs.radarr.enabled or false) && (hs.radarr.apiKey or null) != null
        then hs.radarr.apiKey
        else defaultApiKey;
      prowlarrApiKey =
        if (hs.prowlarr.enabled or false) && (hs.prowlarr.apiKey or null) != null
        then hs.prowlarr.apiKey
        else defaultApiKey;

      # Declarr runs as a host systemd service (not in the "internal" docker network),
      # so it cannot resolve docker container hostnames like "radarr". Use the public
      # HTTPS URLs exposed via SWAG (subdomain + swag.domain) for all URLs that declarr
      # itself uses to connect to services (the "declarr.url" entries and the jellyseerr
      # radarr/sonarr/fix lookup entries). Inter-container references that the *arr apps
      # themselves use (e.g. sonarr's download client host, prowlarr app baseUrls) stay
      # as internal docker names so containers can reach each other directly on the
      # internal network without going through the reverse proxy.
      swag = config.neo.services.swag or {};
      domain = swag.domain or null;
      radarrSub = (hs.radarr or {}).subdomain or "radarr";
      sonarrSub = (hs.sonarr or {}).subdomain or "sonarr";
      prowlarrSub = (hs.prowlarr or {}).subdomain or "prowlarr";
      seerrSub = (hs.seerr or {}).subdomain or "seerr";
      jellyfinSub = (hs.jellyfin or {}).subdomain or "jellyfin";
      externalUrlFor = sub:
        if domain != null
        then "https://${sub}.${domain}"
        else null;

      appdata = "${config.neo.core.volumes.appdata}/declarr";
      arrConfigFile = "${appdata}/config.json";
      seerrConfigFile = "${appdata}/seerr-config.json";

      arrConfig =
        {
          declarr = {
            stateDir = cfg.stateDir;
            formatDbRepo = "https://github.com/Dictionarry-Hub/Database";
            formatDbBranch = "stable";
            globalResolvePaths = [];
          };
        }
        // optionalAttrs hs.sonarr.enabled {
          sonarr = {
            declarr = {
              type = "sonarr";
              url = let
                u = externalUrlFor sonarrSub;
              in
                if u != null
                then u
                else "http://sonarr:8989";
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
                apiKey = sonarrApiKey;
                analyticsEnabled = false;
                authenticationMethod = "external";
                # "DisabledForLocalAddresses" so that when reached via the SWAG/tinyauth reverse proxy (appears local)
                # there is no *arr built-in login prompt (avoids double auth); API key still works for declarr/seerr etc.
                authenticationRequired = "DisabledForLocalAddresses";
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
              url = let
                u = externalUrlFor radarrSub;
              in
                if u != null
                then u
                else "http://radarr:7878";
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
                apiKey = radarrApiKey;
                analyticsEnabled = false;
                authenticationMethod = "external";
                # "DisabledForLocalAddresses" so that when reached via the SWAG/tinyauth reverse proxy (appears local)
                # there is no *arr built-in login prompt (avoids double auth); API key still works for declarr/seerr etc.
                authenticationRequired = "DisabledForLocalAddresses";
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
              url = let
                u = externalUrlFor prowlarrSub;
              in
                if u != null
                then u
                else "http://prowlarr:9696";
            };
            config = {
              ui = {
                firstDayOfWeek = 1;
                theme = "dark";
                timeFormat = "HH:mm";
              };
              host = {
                apiKey = prowlarrApiKey;
                analyticsEnabled = false;
                authenticationMethod = "external";
                # "DisabledForLocalAddresses" so that when reached via the SWAG/tinyauth reverse proxy (appears local)
                # there is no *arr built-in login prompt (avoids double auth); API key still works for declarr/seerr etc.
                authenticationRequired = "DisabledForLocalAddresses";
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
                    apiKey = sonarrApiKey;
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
                    apiKey = radarrApiKey;
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
                appProfileId = "Standard";
              };
              "The Pirate Bay" = {
                indexerName = "The Pirate Bay";
                implementation = "Cardigann";
                priority = 30;
                fields = {
                  definitionFile = "thepiratebay";
                  "torrentBaseSettings.seedRatio" = 10;
                };
                appProfileId = "Standard";
              };
              "YTS" = {
                indexerName = "YTS";
                implementation = "Cardigann";
                priority = 30;
                fields = {
                  definitionFile = "yts";
                  "torrentBaseSettings.seedRatio" = 10;
                };
                appProfileId = "Standard";
              };
            };
            # Provide key (as null) so declarr's prowlarr sync doesn't KeyError on cfg["indexerProxy"].
            # (declarr always does self.sync_contracts("/indexerProxy", self.cfg["indexerProxy"]) for prowlarr type,
            # even if no proxies. User can populate via extraConfig or add FlareSolverr etc. if desired.)
            indexerProxy = null;
          };
        };
      seerrConfig = optionalAttrs (hs.seerr.enabled or false) {
        # jellyseerr under seerr key for declarr
        jellyseerr = {
          declarr = {
            type = "jellyseerr";
            url = externalUrlFor seerrSub;
            port = 443;
            stateDir = "${config.neo.core.volumes.appdata}/seerr/config";
          };
          # main + public + fuller jellyfin ensure declarr's sync_jellyseerr succeeds:
          # - defaultPermissions must be dict (not int from declarr's jellyseerr-settings.json) so perms_to_int doesn't get int
          # - username/email/password must exist (dummies ok) to avoid KeyError on del in sync_jellyseerr
          #   (they are removed before writing the final seerr settings.json)
          # - public.initialized avoids re-running first-time wizard
          # declarr's deep_merge(user_prio, its_default) + perms conversion + library id gen + profileId lookup will fill the rest.
          # radarr/sonarr links are the key auto-wiring provided here.
          main = {
            defaultPermissions = {
              autoApprove = true;
              autoApprove4k = true;
              autoRequest = true;
              request = true;
              request4k = true;
            };
          };
          # public = {
          #   initialized = false;
          # };
          jellyfin = {
            ip = "jellyfin";
            username = "admin";
            email = "admin@example.com";
            password = "admin";
          };
          sonarr = lib.optionals (hs.sonarr.enabled or false) [
            {
              # Fields for declarr's fix() (which does quality profile ID lookup via *arr API from the host)
              # + fields for the final Seerr settings.json (seerr container will reach sonarr via the public
              # HTTPS URL through SWAG, since declarr host cannot use docker-internal hostnames).
              # Adapted from declarr repo's example jellyseerr configs.
              activeDirectory = "/tv";
              activeProfileName = "1080p Balanced";
              animeTags = [];
              apiKey = sonarrApiKey;
              baseUrl = "";
              enableSeasonFolders = true;
              externalUrl = let
                u = externalUrlFor sonarrSub;
              in
                if u != null
                then u
                else "";
              hostname =
                if domain != null
                then "${sonarrSub}.${domain}"
                else "sonarr";
              id = 0;
              is4k = false;
              isDefault = true;
              name = "sonarr";
              port =
                if domain != null
                then 443
                else 8989;
              preventSearch = false;
              syncEnabled = true;
              tagRequests = false;
              tags = [];
              useSsl = domain != null;
              # placeholders overwritten by declarr during sync (fix() does the /api/v3/qualityprofile lookup)
              activeProfileId = 0;
              activeServerId = 0;
            }
          ];
          radarr = lib.optionals (hs.radarr.enabled or false) [
            {
              activeDirectory = "/movies";
              activeProfileName = "1080p Balanced";
              apiKey = radarrApiKey;
              baseUrl = "";
              externalUrl = let
                u = externalUrlFor radarrSub;
              in
                if u != null
                then u
                else "";
              hostname =
                if domain != null
                then "${radarrSub}.${domain}"
                else "radarr";
              id = 0;
              is4k = false;
              isDefault = true;
              minimumAvailability = "inCinemas";
              name = "radarr";
              port =
                if domain != null
                then 443
                else 7878;
              preventSearch = false;
              syncEnabled = true;
              tagRequests = false;
              tags = [];
              useSsl = domain != null;
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
          filePath = arrConfigFile;
          content = builtins.toJSON fullConfig;
          mode = "0644";
        })
        (lib.neo.mkActivationScriptForFile config {
          filePath = seerrConfigFile;
          content = builtins.toJSON seerrConfig;
          mode = "0644";
        })
      ];
    in {
      config = mkIf cfg.enabled {
        systemd.services.declarr = {
          after =
            (optionals (config.neo.services.swag.enabled or false) ["docker-swag.service"])
            ++ (optionals hs.sonarr.enabled ["docker-sonarr.service"])
            ++ (optionals hs.radarr.enabled ["docker-radarr.service"])
            ++ (optionals hs.prowlarr.enabled ["docker-prowlarr.service"])
            ++ (optionals hs.qbittorrent.enabled ["docker-qbittorrent.service"])
            ++ (optionals (hs.jellyfin.enabled or false) ["docker-jellyfin.service"]);
          # We intentionally do not list docker-seerr here (to avoid dep cycle, since
          # docker-seerr after/wants declarr when declarr enabled). Instead, on successful
          # finish of declarr we use ExecStartPost to restart docker-seerr.service so it
          # picks up any config changes from the sync (e.g. *arr connections, libraries).
          wants = ["docker.service"];
          wantedBy = ["multi-user.target"];
          inherit preStart;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "root";
            Restart = "on-failure";
            RestartSec = 5;
            StartLimitBurst = 3;
            StartLimitIntervalSec = 300;
          };
          script = ''
            echo "Running declarr sync for high_sea *arr stack..."
            ${declarrPkg}/bin/declarr --sync ${arrConfigFile}
            echo "declarr sync complete."
          '';
        };
        systemd.services.declarr-seerr = lib.mkIf hs.seerr.enabled {
          after =
            (optionals (config.neo.services.swag.enabled or false) ["docker-swag.service"])
            ++ (optionals hs.sonarr.enabled ["docker-sonarr.service"])
            ++ (optionals hs.radarr.enabled ["docker-radarr.service"])
            ++ (optionals hs.prowlarr.enabled ["docker-prowlarr.service"])
            ++ (optionals hs.qbittorrent.enabled ["docker-qbittorrent.service"])
            ++ (optionals (hs.jellyfin.enabled or false) ["docker-jellyfin.service"]);
          wants = ["docker.service"];
          wantedBy = ["multi-user.target"];
          inherit preStart;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            User = "root";
            Restart = "on-failure";
            RestartSec = 5;
            StartLimitBurst = 3;
            StartLimitIntervalSec = 300;
            ExecStartPost = ''
              ${pkgs.systemd}/bin/systemctl restart docker-seerr.service --no-block
            '';
          };
          script = ''
            SETTINGS_FILE="${config.neo.core.volumes.appdata}/seerr/config/settings.json"

            while [ ! -f "$SETTINGS_FILE" ]; do
              echo "Seerr settings file not found at $SETTINGS_FILE — waiting 10 seconds..."
              sleep 10
            done

            MEDIA_SERVER_TYPE=$(${pkgs.jq}/bin/jq -r '.main.mediaServerType // "null"' "$SETTINGS_FILE" 2>/dev/null || echo "null")

            if [ "$MEDIA_SERVER_TYPE" = "4" ]; then
              echo "Running declarr sync for high_sea seerr docker container"
              ${declarrPkg}/bin/declarr --sync ${seerrConfigFile}
              echo "declarr sync complete."
            else
              echo "seerr already set up"
            fi
          '';
        };
      };
    };
}
