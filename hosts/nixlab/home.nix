{ pkgs, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ../../home/config/git.nix
    ../../home/config/neovim
    ../../home/config/shell
  ];

  home.packages = with pkgs; map lib.lowPrio [
    # CLI
    xh
    dnsutils
    fd
    duf
    ripgrep
    man-pages
    libarchive
    nixpkgs-fmt
    nixpkgs-review
    wgcf
    cloudflared
    # Env
    patchelf
    binutils
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
