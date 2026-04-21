{
  pkgs,
  config,
  ...
}:
{
  sops.secrets.sshosts = {
    sopsFile = ./sshosts.keytab;
    format = "binary";
  };
  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableExtraSocket = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  programs = {
    uv.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      extraConfig = ''
        Include ${config.sops.secrets.sshosts.path}
      '';
      matchBlocks."*" = {
        compression = true;
      };
      extraOptionOverrides = {
        SetEnv = "TERM=xterm-256color";
        UpdateHostKeys = "no";
        StrictHostKeyChecking = "no";
        ControlMaster = "auto";
        ControlPath = "~/.ssh/master-%r@%h:%p";
        ControlPersist = "10m";
        HostKeyAlgorithms = "ssh-ed25519-cert-v01@openssh.com,ssh-ed25519";
        KexAlgorithms = "mlkem768x25519-sha256,sntrup761x25519-sha512@openssh.com";
        MACs = "hmac-sha2-512-etm@openssh.com";
        Ciphers = "chacha20-poly1305@openssh.com";
      };
    };
    go = {
      enable = true;
      env = {
        GOPATH = "${config.xdg.cacheHome}/go";
        GOBIN = "${config.home.homeDirectory}/.local/bin";
      };
    };
    git = {
      enable = true;
      ignores = [
        ".vscode"
        ".DS_store"
      ];
      settings = {
        user.name = "Diffumist";
        user.email = "git@diffumist.me";
      };
      signing = {
        signByDefault = true;
        key = "8BA330B49A5694A6";
      };
    };
    lazygit.enable = true;
    gpg = {
      enable = true;
      homedir = "${config.xdg.dataHome}/gnupg";
      settings.default-key = "8BA330B49A5694A6";
      scdaemonSettings.deny-admin = true;
    };
    vscode = {
      enable = true;
      package = pkgs.vscodium;
      profiles.default.extensions = with pkgs.vscode-marketplace; [
        golang.go
        mkhl.direnv
        docker.docker
        oxc.oxc-vscode
        jinxcappa.sopsie
        jnoortheen.nix-ide
        antfu.file-nesting
        thegeeklab.yamlfmt-ng
        tamasfe.even-better-toml
        rust-lang.rust-analyzer
        piousdeer.adwaita-theme
        pkief.material-icon-theme
        pkief.material-product-icons
        ms-ceintl.vscode-language-pack-zh-hans
      ];
    };
    zed-editor = {
      enable = true;
      extensions = [ "nix" ];
    };
  };
  home.packages = with pkgs; [
    xh
    age
    sops
    nixd
    nixfmt
    taplo
    yamlfmt
    gdb
    gcc
    cmake
    gnumake
    ninja
    deno
    oxfmt
    oxlint
    tsgolint
    nodejs
    rustup
    python3
    pyright
    nix-init
    patchelf
    hyperfine
    pkg-config
    nixpkgs-review
    nix-output-monitor
  ];
}
