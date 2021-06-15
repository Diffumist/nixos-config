{ pkgs, config, ... }:

{
  programs.home-manager.enable = true;

  imports = [
    ./modules/alacritty.nix
    ./modules/common-pkgs.nix
    ./modules/direnv.nix
    ./modules/firefox.nix
    ./modules/git.nix
    ./modules/gpg.nix
    ./modules/fcitx5.nix
    ./modules/mpv.nix
    ./modules/firefox.nix
    # ./modules/rust.nix
    ./modules/shell
    ./modules/trash.nix
    ./modules/user-dirs.nix
    ./modules/vscode

  ];

  fonts.fontconfig.enable = true;

  # FIXME: sddm doesn't respect `home.sessionVariables`.
  # systemd.user.sessionVariables = {
  #   inherit (config.home.sessionVariables) CARGO_HOME GNUPGHOME;
  # };

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
