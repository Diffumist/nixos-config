{ pkgs, lib, ... }:
{
  imports = [
    ./sshd.nix
    ./nixconfig.nix
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

  # ntp
  time.timeZone = "Asia/Shanghai";
  services.timesyncd.enable = false;
  services.ntpd-rs.enable = true;

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
    };
    oci-containers.backend = "podman";
  };
}
