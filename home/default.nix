_:

{
  programs.home-manager.enable = true;

  imports = [
    ./profile/common-pkgs.nix
    ./profile/git.nix
    ./profile/chromium.nix
    ./profile/video.nix
    ./profile/services.nix
    ./profile/shell/wezterm.nix
    ./profile/xdg
    ./profile/neovim
    ./profile/vscode
    ./profile/shell

  ];

  fonts.fontconfig.enable = true;

  # sops = {
  #   defaultSopsFile = ../secrets/onix.yaml;
  #   age = {
  #     keyFile = "/var/lib/sops.key";
  #     sshKeyPaths = [ ];
  #   };
  #   gnupg.sshKeyPaths = [ ];
  # };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "24.05";
}
