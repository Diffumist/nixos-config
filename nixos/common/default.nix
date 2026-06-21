{
  pkgs,
  lib,
  config,
  ...
}:
{
  imports = [
    ./nixconfig.nix
    ./kernel.nix
    ./services/sshd.nix
    ./services/fail2ban.nix
    ./services/caddy.nix
    ./services/sing-box.nix
    ./services/sema.nix
    ./services/postgresql.nix
    # ./services/komari.nix # TODO: REPLACE sema and vnstat + webhook
    ./services/dn42/default.nix
    ./services/dn42/peer.nix
    ./services/dn42/flap-damping.nix
  ];

  sops = {
    age.sshKeyPaths = lib.mkDefault [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      user_passwd_hash = {
        neededForUsers = true;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    fd
    xsz
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
    fastfetch.minimal
    libarchive
    ssh-to-age
    wireguard-tools
  ];

  time.timeZone = lib.mkDefault "Asia/Shanghai";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "zh_CN.UTF-8/UTF-8"
    ];
  };

  programs.nexttrace.enable = true;
  users.defaultUserShell = pkgs.fish;
  programs.fish.enable = true;
  programs.fish.useBabelfish = true;

  services.vnstat.enable = true;
  environment.etc."vnstat.conf".text = lib.mkDefault ''
    MonthRotate 1
  '';
  systemd.services.vnstat.restartTriggers = [
    config.environment.etc."vnstat.conf".source
  ];

  virtualisation = {
    podman = {
      enable = lib.mkDefault true;
      dockerCompat = true;
      dockerSocket.enable = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    oci-containers.backend = "podman";
  };
  # Enable podman auto update
  systemd.timers.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
    wantedBy = [ "timers.target" ];
  };
  systemd.services.podman-auto-update = lib.mkIf config.virtualisation.podman.enable {
    serviceConfig.ExecStartPost = lib.mkIf config.services.caddy.enable "${pkgs.systemd}/bin/systemctl try-restart caddy.service";
  };
}
