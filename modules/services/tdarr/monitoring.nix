# Tdarr dashboard and alerts: web requests, errors from its log, resources.
# No metrics endpoint (third-party image without one). Builder: _lib.nix basicMonitoring.
{...}: {
  neoPlugin.modules.tdarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
  in {
    config = hs.basicMonitoring {
      inherit config plugin;
      svc = "tdarr";
      label = "Tdarr";
      description = "Video conversions: visits, errors in Tdarr's log and the processor and memory the conversions use.";
      filter = hs.filters.tdarr;
    };
  };
}
