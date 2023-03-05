{ lib, config, pkgs, ... }:

with lib;
let
  cfg = config.modules.base;
in
{
  options = {
    modules.base = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.enable = true;
    system.stateVersion = "21.11";
  };
}
