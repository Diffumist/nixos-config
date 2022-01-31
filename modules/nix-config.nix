{ pkgs, inputs, self, lib, config, secrets, ... }: {

  nixpkgs.config.allowUnfree = true;

  nix = {
    package = pkgs.nixFlakes;
    settings.trusted-users = [ "root" "diffumist" ];

    settings.substituters = lib.mkBefore [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://diffumist.cachix.org"
      "https://cache.nixos.org"
    ];
    settings.trusted-public-keys = [ "diffumist.cachix.org-1:MtOScqYJitYQ6A8Py53l1/hzM1t18TWkkfVwi/kqlHk=" ];

    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 20d";
    };

    settings.auto-optimise-store = true;

    extraOptions = ''
      experimental-features = nix-command flakes
      flake-registry = /etc/nix/registry.json

      keep-outputs = true
      keep-derivations = true

      access-tokens = github.com=${secrets.github-token}
    '';

    registry.p.flake = self;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
