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
  };
}
