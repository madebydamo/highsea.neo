# Listenarr dashboard and alerts: web requests, errors from its log, resources.
# No metrics endpoint (third-party image without one). Builder: _lib.nix basicMonitoring.
{...}: {
  neoPlugin.modules.listenarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
  in {
    config = hs.basicMonitoring {
      inherit config plugin;
      svc = "listenarr";
      label = "Listenarr";
      description = "Audiobook downloads: visits, errors in Listenarr's log and its resources.";
      filter = hs.filters.generic;
    };
  };
}
