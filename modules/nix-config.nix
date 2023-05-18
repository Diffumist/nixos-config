{ inputs, self, lib, secrets, ... }: {

  nixpkgs.config.allowUnfree = true;
  documentation.doc.enable = false;

  nix = {
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
      substituters = lib.mkBefore [
        "https://cache.nixos.org"
        "https://ilya-fedin.cachix.org"
        "https://diffumist.cachix.org"
        "https://berberman.cachix.org"
      ];
      trusted-public-keys = [
        "diffumist.cachix.org-1:MtOScqYJitYQ6A8Py53l1/hzM1t18TWkkfVwi/kqlHk="
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
