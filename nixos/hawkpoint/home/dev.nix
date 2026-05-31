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
      includes = [ config.sops.secrets.sshosts.path ];
      extraOptionOverrides = {
        SetEnv = {
          TERM = "xterm-256color";
        };
        Compression = true;
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
    vscodium = {
      enable = true;
      profiles.default.extensions = with pkgs.open-vsx-release; [
        golang.go
        mkhl.direnv
        docker.docker
        oxc.oxc-vscode
        jinxcappa.sopsie
        jnoortheen.nix-ide
        antfu.file-nesting
        oscarotero.vento-syntax
        thegeeklab.yamlfmt-ng
        tamasfe.even-better-toml
        rust-lang.rust-analyzer
        astro-build.astro-vscode
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
    yaml-language-server
    gdb
    gcc
    cmake
    gnumake
    ninja
    gopls
    deno
    typst
    oxfmt
    oxlint
    tsgolint
    typescript-language-server
    yarn-berry
    pnpm
    typescript
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
