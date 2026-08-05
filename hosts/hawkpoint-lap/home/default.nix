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
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  # services
  systemd.user.services.cli-proxy-api = {
    Unit = {
      Description = "CLIProxyAPI Service";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.llm-agents.cli-proxy-api}/bin/cli-proxy-api --config %h/.local/share/cli-proxy-api/config.yaml";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  systemd.user.services.bluetooth-mpris-proxy = {
    Unit = {
      Description = "MPRIS controlling proxy for bluetooth connections";
      After = [ "sound.target" ];
    };
    Service = {
      ExecStart = "${pkgs.bluez}/bin/mpris-proxy";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  systemd.user.services.aria2 = {
    Unit = {
      Description = "Aria2 daemon";
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
        "--ozone-platform-hint=auto"
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
    fff
    mosh
    sing-box
    # nix-alien
    microfetch
    bubblewrap
    steam-run
    android-tools
    (pkgs.writeShellApplication {
      name = "niri-single-monitor-game";
      runtimeInputs = [ pkgs.niri ];
      text = ''
        output="eDP-1"
        # shellcheck disable=SC2329
        restore_output() {
          niri msg output "$output" on >/dev/null 2>&1 || true
        }
        trap restore_output EXIT HUP INT TERM
        niri msg output "$output" off || exit 1
        "$@"
        status=$?
        exit "$status"
      '';
    })
    # mcp
    mcp-nixos
    playwright
    context7-mcp
    playwright-mcp
    github-mcp-server
    llm-agents.agent-browser
    # TUI
    llm-agents.rtk
    llm-agents.codex
    llm-agents.omp
    llm-agents.herdr
    llm-agents.crush
    llm-agents.opencode2
    llm-agents.codex-auth
    llm-agents.claude-code
    llm-agents.antigravity-cli
    # GUI
    qq
    pods
    tuba
    papers
    gitte
    wemeet
    vesktop
    gapless
    clapper
    fractal
    localsend
    fragments
    apostrophe
    typesetter
    distroshelf
    thunderbird
    field-monitor
    ayugram-desktop
    uncategorized.dingtalk
    netease-cloud-music-gtk
  ];
  home.shell.enableFishIntegration = true;
  home.shell.enableBashIntegration = true;
  home.preferXdgDirectories = true;
  home.stateVersion = "25.11";
}
