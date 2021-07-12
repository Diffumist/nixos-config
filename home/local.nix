{ ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ./modules/alacritty.nix
    ./modules/common-pkgs.nix
    ./modules/direnv.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/video.nix
    ./modules/chromium.nix
    # ./modules/rust.nix
    ./modules/shell/default.nix
    ./modules/trash.nix
    ./modules/user-dirs.nix
    ./modules/vscode

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
  home.stateVersion = "20.03";
}
