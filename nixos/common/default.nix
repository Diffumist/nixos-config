{ pkgs, lib, ... }:
{
  imports = [
    ./nixconfig.nix
    ./kernel.nix
    ./services/fail2ban.nix
    ./services/sshd.nix
  ];

  environment.systemPackages = with pkgs; [
    fd
    bat
    eza
    duf
    ncdu
    btop
    ripgrep
    binutils
    dnsutils
    pciutils
    tealdeer
    man-pages
    libarchive
  ];

  time.timeZone = "Asia/Shanghai";

  i18n = {
    defaultLocale = "zh_CN.UTF-8";
    supportedLocales = [
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };
}
