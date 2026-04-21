{
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./dev.nix
    ./shell.nix
    ./xdgdir.nix
  ];
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  # services
  systemd.user.services.cli-proxy-api = {
    Unit = {
      Description = "CLIProxyAPI Service";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.cli-proxy-api}/bin/cli-proxy-api --config %h/.local/share/cli-proxy-api/config.yaml";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  systemd.user.services.aria2 = {
    Unit = {
      Description = "aria2 daemon";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      ExecStart = "${pkgs.aria2}/bin/aria2c --conf-path=%h/.config/aria2/aria2.conf";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  services.system76-scheduler-niri.enable = true;
  # programs
  programs = {
    home-manager.enable = true;
    fastfetch.enable = true;
    aria2 = {
      enable = true;
      settings = {
        dir = "/home/diffumist/Downloads";
        continue = true;
        always-resume = false;
        remote-time = true;
        disk-cache = "64M";
        file-allocation = "none";
        max-concurrent-downloads = 5;
        max-connection-per-server = 16;
        split = 64;
        min-split-size = "4M";
        allow-piece-length-change = true;
        http-accept-gzip = true;
        content-disposition-default-utf8 = true;
        enable-rpc = true;
        rpc-listen-all = false;
        rpc-allow-origin-all = false;
        rpc-listen-port = 6800;
      };
    };
    chromium = {
      enable = true;
      commandLineArgs = [
        "--ozone-platform=wayland"
        "--enable-features=VaapiVideoDecodeLinuxGL"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-wayland-ime"
        "--wayland-text-input-version=3"
      ];
    };
  };
  home.packages = with pkgs; [
    # CLI
    sing-box
    bubblewrap
    steam-run
    android-tools
    # TUI
    codex-cli
    # opencode
    # claude-code
    # GUI
    qq
    wemeet
    kazumi
    splayer
    vesktop
    gapless
    clapper
    piliplus
    localsend
    fluffychat
    antigravity-fhs
    ayugram-desktop
    qbittorrent-enhanced
    netease-cloud-music-gtk
    # uncategorized.dingtalk
  ];
  home.shell.enableFishIntegration = true;
  home.preferXdgDirectories = true;
  home.stateVersion = "25.11";
}
