{ pkgs, lib, ... }:
{
  imports = [
    ./nixconfig.nix
    ./kernel.nix
    ./services/fail2ban.nix
    ./services/sshd.nix
    ./services/sing-box.nix
  ];

  environment.systemPackages = with pkgs; [
    fd
    bat
    eza
    duf
    dua
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
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  programs.nexttrace.enable = true;
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  virtualisation = {
    podman = {
      enable = lib.mkDefault true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };
}
