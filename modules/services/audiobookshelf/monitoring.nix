# Audiobookshelf dashboard and alerts: web requests, errors from its log, resources.
# No metrics endpoint (third-party image without one). Builder: _lib.nix basicMonitoring.
{...}: {
  neoPlugin.modules.audiobookshelf-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
  in {
    config = hs.basicMonitoring {
      inherit config plugin;
      svc = "audiobookshelf";
      label = "Audiobookshelf";
      description = "Listening from the browser and the phone apps: visits, errors in Audiobookshelf's log and its resources.";
      filter = hs.filters.audiobookshelf;
    };
  };
}
