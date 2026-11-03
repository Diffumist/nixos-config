{ config, lib, ... }:
let
  cfg = config.my.networking;
  portType = lib.types.ints.between 1 65535;

  conflictingPorts =
    ports:
    lib.filterAttrs (_: owners: builtins.length owners > 1) (
      lib.groupBy (owner: toString ports.${owner}) (lib.attrNames ports)
    );

  formatConflicts =
    protocol: ports:
    lib.mapAttrsToList (port: owners: "${protocol} port ${port}: ${lib.concatStringsSep ", " owners}") (
      conflictingPorts ports
    );

  conflicts = formatConflicts "TCP" cfg.usedTCPPorts ++ formatConflicts "UDP" cfg.usedUDPPorts;
in
{
  options.my.networking = {
    usedTCPPorts = lib.mkOption {
      type = lib.types.attrsOf portType;
      default = { };
      description = "TCP ports reserved by services in the host network namespace";
    };

    usedUDPPorts = lib.mkOption {
      type = lib.types.attrsOf portType;
      default = { };
      description = "UDP ports reserved by services in the host network namespace";
    };
  };

  config.assertions = [
    {
      assertion = conflicts == [ ];
      message = ''
        Host port reservation conflicts detected:
        ${lib.concatMapStringsSep "\n" (conflict: "  - ${conflict}") conflicts}
      '';
    }
  ];
}
