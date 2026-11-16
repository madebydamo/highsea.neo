# declarr dashboard and alerts: its runs and errors (host setup units, no
# container, no web page). Builder: _lib.nix basicMonitoring.
{...}: {
  neoPlugin.modules.declarr-monitoring = {
    config,
    lib,
    plugin,
    ...
  }: let
    hs = import ../../_lib.nix {inherit lib;};
    name = plugin.name "declarr";
    units = [name "${name}-seerr"];
  in {
    config = hs.basicMonitoring {
      inherit config plugin units;
      svc = "declarr";
      label = "Media apps setup";
      description = "The runs that connect the media apps to each other, and what went wrong in them.";
      filter = hs.filters.declarr;
      containers = [];
      web = false;
      headline = with lib.neo.grafana; [
        (row "Runs" null)
        (bars {
          title = "Finished runs";
          w = 24;
          datasource = loki;
          interval = "1h";
          targets = [(lqLegend ''sum by (unit) (count_over_time({job="journal", host=~"$host", unit=~"${lib.concatMapStringsSep "|" (u: "${u}[.]service") units}"} |= "sync complete" [$__interval]))'' "{{unit}}")];
        })
        (logs {
          title = "Last runs";
          w = 24;
          targets = [(lq ''{job="journal", host=~"$host", unit=~"${lib.concatMapStringsSep "|" (u: "${u}[.]service") units}"}'')];
        })
      ];
    };
  };
}
