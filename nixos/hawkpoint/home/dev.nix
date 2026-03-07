{
  pkgs,
  config,
  ...
}:
{
  services.gpg-agent = {
    enable = true;
    enableScDaemon = true;
    enableExtraSocket = true;
    pinentry.package = pkgs.pinentry-gnome3;
  };
  programs = {
    uv.enable = true;
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
        jnoortheen.nix-ide
        rust-lang.rust-analyzer
        piousdeer.adwaita-theme
        pkief.material-icon-theme
        pkief.material-product-icons
        ms-python.python
        ms-python.debugpy
        ms-python.vscode-python-envs
        ms-ceintl.vscode-language-pack-zh-hans
      ];
    };
    lazygit.enable = true;
  };
  home.packages = with pkgs; [
    xh
    tokei
    age
    sops
    nixd
    nixfmt
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
