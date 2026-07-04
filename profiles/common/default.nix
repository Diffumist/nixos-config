{
  pkgs,
  lib,
  config,
  self,
  ...
}:
{
  imports = [
    ./nixconfig.nix
    ./kernel.nix
    "${self}/modules/system/sops.nix"
    ./services/sshd.nix
    ./services/fail2ban.nix
    "${self}/modules/services/caddy.nix"
    "${self}/modules/services/prometheus-node.nix"
    ./services/wg-mgmt.nix
    "${self}/modules/services/sing-box.nix"
    "${self}/modules/services/sema.nix"
    "${self}/modules/services/postgresql.nix"
    # "${self}/modules/services/komari.nix" # TODO: REPLACE sema and vnstat + webhook
    "${self}/modules/services/dn42/mesh.nix"
    ./services/dn42.nix
    ./services/dn42-peers.nix
    "${self}/modules/services/dn42/peer.nix"
    "${self}/modules/services/dn42/flap-damping.nix"
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
    microfetch
    libarchive
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

  networking = {
    nftables.enable = true;
    useNetworkd = true;
    networkmanager.enable = false;
  };
  systemd.network.wait-online.enable = false;

  users.users.root.hashedPasswordFile = config.sops.secrets.user_passwd_hash.path;

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
