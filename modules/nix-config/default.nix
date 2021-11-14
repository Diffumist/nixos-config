{ pkgs, inputs, lib, ... }: {
  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nixFlakes;
    trustedUsers = [ "root" "diffumist" ];

    binaryCaches = lib.mkBefore [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://diffumist.cachix.org"
      "https://cache.nixos.org"
    ];
    binaryCachePublicKeys = [ "diffumist.cachix.org-1:MtOScqYJitYQ6A8Py53l1/hzM1t18TWkkfVwi/kqlHk=" ];

    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 20d";
    };

    autoOptimiseStore = true;

    extraOptions = ''
      experimental-features = nix-command flakes ca-references
      flake-registry = /etc/nix/registry.json
      keep-outputs = true
      keep-derivations = true
    '';

    registry.p.flake = inputs.nixpkgs;
    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
}
