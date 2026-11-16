# declarr: configures the high_sea apps from Neo settings. It runs on the
# host and reaches every app through its public URL (SWAG); the addresses it
# writes into the apps (download client, Prowlarr app sync, FlareSolverr) are
# container names, reached over the plugin's Docker links (links.nix).
#   declarr        syncs Sonarr, Radarr, Lidarr and Prowlarr (setup unit)
#   declarr-seerr  pre-configures Seerr's settings.json until Seerr is set up
{inputs, ...}: {
  neoPlugin.modules.declarr = {
    config,
    lib,
    pkgs,
    plugin,
    ...
  }:
    with lib; let
      name = plugin.name "declarr";
      cfg = config.neo.services.${name};
      hs = config.neo.services;
      # Names of this copy's services (prefixed when the plugin has a prefix).
      N = genAttrs ["sonarr" "radarr" "lidarr" "prowlarr" "qbittorrent" "flaresolverr" "seerr" "jellyfin"] plugin.name;
      on = s: (hs.${N.${s}} or {}).enabled or false;
      declarrPkg = inputs.declarr.packages.${pkgs.stdenv.hostPlatform.system}.declarr;
      lib' = import ../../_lib.nix {inherit lib;};
      qbit = hs.${N.qbittorrent};
      qbitUser = qbit.username;
      qbitPass = lib'.qbitPassword config N.qbittorrent;
      qbitPort = qbit.webPort;
      # Only read for enabled apps, whose modules assert the key is set.
      keyOf = s: hs.${N.${s}}.apiKey;
      sonarrApiKey = keyOf "sonarr";
      radarrApiKey = keyOf "radarr";
      lidarrApiKey = keyOf "lidarr";
      prowlarrApiKey = keyOf "prowlarr";

      # declarr runs on the host and cannot resolve container names: it uses the
      # public HTTPS URLs (subdomain + swag.domain) for every app it talks to
      # itself, including the Seerr lookups. Addresses the apps use to reach each
      # other stay container names.
      swag = config.neo.services.swag or {};
      domain = swag.domain or null;
      radarrSub = (hs.${N.radarr} or {}).subdomain or N.radarr;
      sonarrSub = (hs.${N.sonarr} or {}).subdomain or N.sonarr;
      lidarrSub = (hs.${N.lidarr} or {}).subdomain or N.lidarr;
      prowlarrSub = (hs.${N.prowlarr} or {}).subdomain or N.prowlarr;
      seerrSub = (hs.${N.seerr} or {}).subdomain or N.seerr;
      jellyfinSub = (hs.${N.jellyfin} or {}).subdomain or N.jellyfin;
      externalUrlFor = sub:
        if domain != null
        then "https://${sub}.${domain}"
        else null;

      # Servarr rejects PUT /config/host when authenticationRequired is not
      # Enabled and allowedHosts is blank (follow-up to CVE-2026-30975).
      # Declarr writes this block every sync, so a rejection fails the unit,
      # restarts it, and re-tests FlareSolverr. Names are how this service is
      # reached: the SWAG hostname (proxy and declarr send that Host header),
      # the docker DNS name (other containers), and localhost. Not a setting.
      allowedHostsFor = name: sub:
        concatStringsSep "," (
          optional (domain != null) "${sub}.${domain}"
          ++ [name "localhost"]
        );

      appdata = "${config.neo.core.volumes.appdata}/${name}";
      # Rendered at activation with the API keys and the qBittorrent password
      # filled in (root only, never in the store on an encrypted config).
      arrTemplate = "${name}-config.json";
      seerrTemplate = "${name}-seerr-config.json";
      arrConfigFile = config.neo.core.secrets.templates.${arrTemplate}.path;
      seerrConfigFile = config.neo.core.secrets.templates.${seerrTemplate}.path;
      secretValues =
        map keyOf (filter on ["sonarr" "radarr" "lidarr" "prowlarr"])
        ++ optional (on "qbittorrent") qbitPass;

      arrConfig =
        {
          declarr = {
            stateDir = cfg.stateDir;
            formatDbRepo = "https://github.com/Dictionarry-Hub/Database";
            formatDbBranch = "stable";
            globalResolvePaths = [];
          };
        }
        // optionalAttrs (on "sonarr") {
          sonarr = {
            declarr = {
              type = "sonarr";
              url = let
                u = externalUrlFor sonarrSub;
              in
                if u != null
                then u
                else "http://${N.sonarr}:8989";
            };
            rootFolder = ["/tv"];
            downloadClient = optionalAttrs (on "qbittorrent") {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = N.qbittorrent;
                  port = qbitPort;
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
                allowedHosts = allowedHostsFor N.sonarr sonarrSub;
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
                logLevel = "info";
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
        // optionalAttrs (on "radarr") {
          radarr = {
            declarr = {
              type = "radarr";
              url = let
                u = externalUrlFor radarrSub;
              in
                if u != null
                then u
                else "http://${N.radarr}:7878";
            };
            rootFolder = ["/movies"];
            downloadClient = optionalAttrs (on "qbittorrent") {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = N.qbittorrent;
                  port = qbitPort;
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
                allowedHosts = allowedHostsFor N.radarr radarrSub;
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
                logLevel = "info";
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
        // optionalAttrs (on "lidarr") {
          lidarr = {
            declarr = {
              type = "lidarr";
              url = let
                u = externalUrlFor lidarrSub;
              in
                if u != null
                then u
                else "http://${N.lidarr}:8686";
            };
            # Lidarr root folders require quality/metadata profile names (not path lists).
            # "Standard" is Lidarr's built-in default for both profile types.
            # customFormat/qualityProfile are not yet supported by declarr for lidarr.
            rootFolder = {
              Music = {
                path = "/music";
                defaultMetadataProfileId = "Standard";
                defaultQualityProfileId = "Standard";
                defaultMonitorOption = "all";
                defaultNewItemMonitorOption = "all";
                defaultTags = [];
              };
            };
            downloadClient = optionalAttrs (on "qbittorrent") {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = N.qbittorrent;
                  port = qbitPort;
                  username = qbitUser;
                  password = qbitPass;
                  sequentialOrder = true;
                };
              };
            };
            config = {
              ui = {
                firstDayOfWeek = 1;
                theme = "dark";
                timeFormat = "HH:mm";
              };
              host = {
                apiKey = lidarrApiKey;
                analyticsEnabled = false;
                authenticationMethod = "external";
                # "DisabledForLocalAddresses" so that when reached via the SWAG/tinyauth reverse proxy (appears local)
                # there is no *arr built-in login prompt (avoids double auth); API key still works for declarr etc.
                authenticationRequired = "DisabledForLocalAddresses";
                allowedHosts = allowedHostsFor N.lidarr lidarrSub;
                backupInterval = 7;
                backupRetention = 28;
                port = 8686;
                urlBase = "";
                bindAddress = "*";
                proxyEnabled = false;
                sslCertPath = "";
                sslCertPassword = "";
                instanceName = "Lidarr";
                branch = "master";
                logLevel = "info";
                consoleLogLevel = "";
                logSizeLimit = 1;
                updateScriptPath = "";
              };
              naming = {
                renameTracks = true;
                replaceIllegalCharacters = true;
                colonReplacementFormat = 4;
                artistFolderFormat = "{Artist Name}";
                standardTrackFormat = "{Album Title} ({Release Year})/{Artist Name} - {Album Title} - {track:00} - {Track Title}";
                multiDiscTrackFormat = "{Album Title} ({Release Year})/{Medium Format} {medium:00}/{Artist Name} - {Album Title} - {track:00} - {Track Title}";
                includeArtistName = false;
                includeAlbumTitle = false;
                includeQuality = false;
                replaceSpaces = false;
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
        // optionalAttrs (on "prowlarr") {
          prowlarr = {
            declarr = {
              type = "prowlarr";
              url = let
                u = externalUrlFor prowlarrSub;
              in
                if u != null
                then u
                else "http://${N.prowlarr}:9696";
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
                allowedHosts = allowedHostsFor N.prowlarr prowlarrSub;
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
                logLevel = "info";
                consoleLogLevel = "";
                logSizeLimit = 1;
                updateScriptPath = "";
              };
            };
            downloadClient = optionalAttrs (on "qbittorrent") {
              qBittorrent = {
                implementation = "QBittorrent";
                fields = {
                  host = N.qbittorrent;
                  port = qbitPort;
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
              (optionalAttrs (on "sonarr") {
                Sonarr = {
                  syncLevel = "fullSync";
                  implementation = "Sonarr";
                  fields = {
                    prowlarrUrl = "http://${N.prowlarr}:9696";
                    baseUrl = "http://${N.sonarr}:8989";
                    apiKey = sonarrApiKey;
                  };
                };
              })
              // (optionalAttrs (on "radarr") {
                Radarr = {
                  syncLevel = "fullSync";
                  implementation = "Radarr";
                  fields = {
                    prowlarrUrl = "http://${N.prowlarr}:9696";
                    baseUrl = "http://${N.radarr}:7878";
                    apiKey = radarrApiKey;
                  };
                };
              })
              // (optionalAttrs (on "lidarr") {
                Lidarr = {
                  syncLevel = "fullSync";
                  implementation = "Lidarr";
                  fields = {
                    prowlarrUrl = "http://${N.prowlarr}:9696";
                    baseUrl = "http://${N.lidarr}:8686";
                    apiKey = lidarrApiKey;
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
            indexerProxy = optionalAttrs (on "flaresolverr") {
              FlareSolverr = {
                fields = {
                  host = "http://${N.flaresolverr}:8191/";
                  requestTimeout = 60;
                };
                implementation = "FlareSolverr";
                tags = ["FlareSolverr"];
              };
            };
          };
        };
      seerrConfig = optionalAttrs (on "seerr") {
        # jellyseerr under seerr key for declarr
        jellyseerr = {
          declarr = {
            type = "jellyseerr";
            url = externalUrlFor seerrSub;
            port = 443;
            stateDir = "${config.neo.core.volumes.appdata}/${N.seerr}/config";
          };
          # declarr's sync_jellyseerr deletes jellyfin.{ip,username,email,password}
          # before writing settings.json (they are only for its `--run` mode), so
          # they must exist but carry nothing. port/useSsl/externalHostname stay
          # and point Seerr at Jellyfin's public URL: Jellyfin and Seerr have no
          # Docker link. defaultPermissions must be a dict (declarr turns it into
          # Seerr's bit mask).
          main = {
            defaultPermissions = {
              autoApprove = true;
              autoApprove4k = true;
              autoRequest = true;
              request = true;
              request4k = true;
            };
          };
          jellyfin =
            {
              ip =
                if domain != null
                then "${jellyfinSub}.${domain}"
                else "";
              username = "";
              email = "";
              password = "";
            }
            // optionalAttrs (domain != null && on "jellyfin") {
              port = 443;
              useSsl = true;
              externalHostname = "https://${jellyfinSub}.${domain}";
            };
          sonarr = lib.optionals (on "sonarr") [
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
                else N.sonarr;
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
          radarr = lib.optionals (on "radarr") [
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
                else N.radarr;
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

      # Containers declarr talks to (through SWAG): it runs after them, and
      # again whenever one of them restarts.
      arrContainers = filter on ["sonarr" "radarr" "lidarr" "prowlarr" "qbittorrent"];
      swagAfter = optional (config.neo.services.swag.enabled or false) "docker-swag.service";

      # Older versions kept the generated JSON, keys included, in appdata.
      prepare = ''
        ${lib.neo.mkEnsureDirs config [appdata cfg.stateDir]}
        rm -f ${appdata}/config.json ${appdata}/seerr-config.json
      '';
      seerrSettings = "${config.neo.core.volumes.appdata}/${N.seerr}/config/settings.json";
      # settings.json without the parts declarr regenerates on every run.
      settingsDigest = ''${pkgs.jq}/bin/jq -S 'del(.clientId)' "$SETTINGS_FILE" 2>/dev/null | sha256sum'';
    in {
      config = mkIf cfg.enabled {
        neo.core.secrets.templates = {
          ${arrTemplate} = {
            content = lib'.secretJSON secretValues fullConfig;
            restartUnits = ["${name}.service"];
          };
          ${seerrTemplate} = mkIf (on "seerr") {
            content = lib'.secretJSON secretValues seerrConfig;
            restartUnits = ["${name}-seerr.service"];
          };
        };

        systemd.services.${name} = lib.neo.mkSetupService {
          inherit pkgs name;
          description = "Configure the media apps${plugin.label} (declarr)";
          containers = map (s: N.${s}) arrContainers;
          after = swagAfter;
          wants = swagAfter;
          wantedBy = ["multi-user.target"];
          retryInterval = 30;
          script = ''
            ${prepare}
            echo "Running declarr sync for the media apps"
            ${declarrPkg}/bin/declarr --sync ${arrConfigFile}
            echo "declarr sync complete"
          '';
        };

        # Not bound to docker-seerr: restarting Seerr below must not run this
        # again. Seerr writes settings.json on its first start; until then
        # this retries. Once Seerr is set up (media server chosen) it leaves
        # the file alone.
        systemd.services."${name}-seerr" = lib.mkIf (on "seerr") (lib.neo.mkSetupService {
          inherit pkgs;
          name = "${name}-seerr";
          description = "Pre-configure Seerr${plugin.label} (declarr)";
          after = ["docker-${N.seerr}.service"] ++ swagAfter ++ map (s: "docker-${N.${s}}.service") arrContainers;
          wants = ["docker-${N.seerr}.service"];
          wantedBy = ["multi-user.target"];
          retryInterval = 15;
          path = [pkgs.jq pkgs.coreutils pkgs.systemd];
          script = ''
            ${prepare}
            SETTINGS_FILE="${seerrSettings}"
            if [ ! -f "$SETTINGS_FILE" ]; then
              echo "Seerr has not written $SETTINGS_FILE yet"
              exit 1
            fi
            MEDIA_SERVER_TYPE=$(jq -r '.main.mediaServerType // "null"' "$SETTINGS_FILE" 2>/dev/null || echo "null")
            if [ "$MEDIA_SERVER_TYPE" != "4" ]; then
              echo "Seerr is already set up"
              exit 0
            fi
            before=$(${settingsDigest})
            echo "Running declarr sync for Seerr"
            ${declarrPkg}/bin/declarr --sync ${seerrConfigFile}
            after=$(${settingsDigest})
            if [ "$before" != "$after" ]; then
              echo "Seerr settings changed, restarting Seerr"
              systemctl restart --no-block docker-${N.seerr}.service
            fi
          '';
        });
      };
    };
}
