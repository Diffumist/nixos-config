{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ./dev.nix
    ./shell.nix
    ./xdgdir.nix
    ./desktop.nix
  ];
  sops.age.sshKeyPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
  # services
  # systemd.user.services.cli-proxy-api = {
  #   Unit = {
  #     Description = "CLIProxyAPI Service";
  #     After = [ "network-online.target" ];
  #     Wants = [ "network-online.target" ];
  #   };
  #   Service = {
  #     Type = "simple";
  #     ExecStart = "${pkgs.llm-agents.cli-proxy-api}/bin/cli-proxy-api --config %h/.local/share/cli-proxy-api/config.yaml";
  #     Restart = "on-failure";
  #     RestartSec = 5;
  #   };
  #   Install = {
  #     WantedBy = [ "default.target" ];
  #   };
  # };
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
  home.packages =
    with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
    with pkgs;
    [
      # CLI
      fff
      # mosh
      sing-box
      # nix-alien
      microfetch
      bubblewrap
      steam-run
      android-tools
      (pkgs.writeShellApplication {
        name = "umbriel-single-monitor";
        runtimeInputs = [ config.programs.umbriel.package ];
        text = ''
          output="eDP-1"
          # shellcheck disable=SC2329
          restore_output() {
            env -u LD_LIBRARY_PATH -u LD_PRELOAD umbriel msg output-enable "$output" >/dev/null 2>&1 || true
          }
          trap restore_output EXIT HUP INT TERM
          env -u LD_LIBRARY_PATH -u LD_PRELOAD umbriel msg output-disable "$output"
          if "$@"; then
            status=0
          else
            status=$?
          fi
          exit "$status"
        '';
      })
      (pkgs.writeShellApplication {
        name = "game-force-1440p";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.wlr-randr
        ];
        text = ''
          output="HDMI-A-1"

          set_output() {
            env -u LD_LIBRARY_PATH -u LD_PRELOAD wlr-randr --output "$output" "$@"
          }

          # shellcheck disable=SC2329
          restore_output() {
            set_output --mode "3840x2160@59.997Hz" --scale 1.5 >/dev/null 2>&1 || true
          }

          trap restore_output EXIT HUP INT TERM
          set_output --mode "2560x1440@59.951Hz" --scale 1

          if "$@"; then
            status=0
          else
            status=$?
          fi
          exit "$status"
        '';
      })
      # mcp
      # mcp-nixos
      playwright
      context7-mcp
      playwright-mcp
      github-mcp-server
      llm-agents.agent-browser
      # TUI
      llm-agents.rtk
      llm-agents.codex
      llm-agents.pi
      llm-agents.herdr
      llm-agents.crush
      llm-agents.opencode2
      llm-agents.codex-auth
      llm-agents.claude-code
      llm-agents.antigravity-cli
      # GUI
      qq
      wu
      pods
      tuba
      papers
      gitte
      wemeet
      azahar
      vesktop
      gapless
      clapper
      fractal
      rimsort
      ryubing
      localsend
      fragments
      apostrophe
      typesetter
      distroshelf
      thunderbird
      field-monitor
      ayugram-desktop
      netease-cloud-music-gtk
    ];
  home.shell.enableFishIntegration = true;
  home.shell.enableBashIntegration = true;
  home.preferXdgDirectories = true;
  home.stateVersion = "26.05";
}
