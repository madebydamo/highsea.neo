# Helpers shared by the high_sea modules (not a module: import-tree skips
# files starting with `_`). Use: `hs = import ../../_lib.nix {inherit lib;};`
{lib}: {
  # qBittorrent's Web UI password: the setting, or a key the machine
  # generates (neo.core.secrets.generated."<qbittorrent>-password", declared
  # by qbittorrent/default.nix) that only the apps know.
  qbitPassword = config: qbitName: let
    pw = config.neo.services.${qbitName}.password or null;
  in
    if lib.neo.isSet pw
    then pw
    else lib.neo.secrets.mkPlaceholder "generated/${qbitName}-password";

  # JSON text of `value` in which the secret strings in `secrets` (setting
  # values or their placeholders) are filled in at activation, JSON-escaped:
  # for a secrets template's `content`.
  secretJSON = secrets: value: let
    ss = lib.unique (lib.filter builtins.isString secrets);
  in
    builtins.replaceStrings (map builtins.toJSON ss) (map lib.neo.secrets.jsonString ss) (builtins.toJSON value);
}
