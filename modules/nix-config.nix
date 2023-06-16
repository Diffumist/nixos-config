{ inputs, self, lib, secrets, pkgs, ... }: {

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "openssl-1.1.1u"
    "openssl-1.1.1t"
  ];
  documentation.doc.enable = false;

  nix = {
    package = pkgs.nixVersions.unstable;
    settings = {
      trusted-users = [ "root" "@wheel" ];
      experimental-features = [
        "nix-command"
        "flakes"
        "auto-allocate-uids"
        "cgroups"
      ];
      auto-allocate-uids = true;
      use-cgroups = true;
      builders-use-substitutes = true;
      substituters = lib.mkBefore [
        "https://mirror.sjtu.edu.cn/nix-channels/store"
        "https://cache.nixos.org"
        "https://ilya-fedin.cachix.org"
        "https://berberman.cachix.org"
      ];
      trusted-public-keys = [
        "ilya-fedin.cachix.org-1:QveU24a5ePPMh82mAFSxLk1P+w97pRxqe9rh+MJqlag="
        "berberman.cachix.org-1:UHGhodNXVruGzWrwJ12B1grPK/6Qnrx2c3TjKueQPds="
      ];
      auto-optimise-store = true;
    };

    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 20d";
    };

    extraOptions = ''
      flake-registry = /etc/nix/registry.json
      access-tokens = github.com=${secrets.github-token}
    '';

    registry = {
      nixpkgs = {
        from = { id = "nixpkgs"; type = "indirect"; };
        flake = inputs.nixpkgs;
      };
      p.flake = self;
    };
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
