# Deemix dashboard and alerts: web requests, errors from its log, resources.
# No metrics endpoint (third-party image without one). Builder: _lib.nix basicMonitoring.
{...}: {
  neoPlugin.modules.deemix-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
  in {
    config = hs.basicMonitoring {
      inherit config plugin;
      svc = "deemix";
      label = "Deemix";
      description = "Deezer downloads: visits, errors in Deemix's log and its resources.";
      filter = hs.filters.generic;
    };
  };
}
