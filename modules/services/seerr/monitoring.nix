# Seerr dashboard and alerts: web requests, errors from its log, resources.
# No metrics endpoint (third-party image without one). Builder: _lib.nix basicMonitoring.
{...}: {
  neoPlugin.modules.seerr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
  in {
    config = hs.basicMonitoring {
      inherit config plugin;
      svc = "seerr";
      label = "Seerr";
      description = "Requests for films and shows: visits, errors in Seerr's log and its resources.";
      filter = hs.filters.seerr;
    };
  };
}
