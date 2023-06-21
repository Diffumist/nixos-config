{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ../../home/config/git.nix
    ../../home/config/neovim
    ../../home/config/shell
  ];

  home.packages = with pkgs; map lib.lowPrio [
    wgcf
    cloudflared
  ];

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "22.11";
}
