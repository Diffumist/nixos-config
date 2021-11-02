{ lib, config, pkgs, ... }:
with lib;
let cfg = config.dmist.base; in
{
  options = {
    dmist.base = {
      enable = mkOption {
        type = types.bool;
        default = true;
      };
    };
  };
  config = mkIf cfg.enable {
    programs.neovim = {
      enable = true;
      vimAlias = true;
      defaultEditor = true;
    };
    sops = {
      defaultSopsFile = ./secrets.yaml;
      age = {
        keyFile = "/var/lib/sops.key";
      };
    };
    networking.firewall.enable = true;
    system.stateVersion = "20.09";
  };
}
