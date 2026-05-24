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
    ./services/postgresql.nix
    ./services/komari.nix
  ];

  sops = {
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      user_passwd_hash = {
        neededForUsers = true;
      };
      komari_token = { };
    };
  };

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
    fastfetchMinimal
    libarchive
    ssh-to-age
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
