_:

{
  programs.home-manager.enable = true;

  imports = [
    ./config/common-pkgs.nix
    ./config/git.nix
    ./config/chromium.nix
    ./config/video.nix
    ./config/services.nix
    ./config/xdg
    ./config/helix
    ./config/vscode
    ./config/shell

  ];

  fonts.fontconfig.enable = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.09";
}
