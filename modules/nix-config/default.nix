{ pkgs, inputs, lib, ... }: {
  nixpkgs.config.allowUnfree = true;
  nix = {
    package = pkgs.nixFlakes;
    useSandbox = true;
    trustedUsers = [ "root" "diffumist" ];

    binaryCaches = lib.mkBefore [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://diffumist.cachix.org"
      "https://cache.nixos.org"
    ];
    binaryCachePublicKeys =
      [ "diffumist.cachix.org-1:MtOScqYJitYQ6A8Py53l1/hzM1t18TWkkfVwi/kqlHk=" ];
    gc = {
      automatic = true;
      dates = "Sun";
      options = "--delete-older-than 14d";
    };

    autoOptimiseStore = true;

    extraOptions = ''
      experimental-features = nix-command flakes
      flake-registry = /etc/nix/registry.json

      # To protect nix-shell against garbage collection.
      keep-outputs = true
      keep-derivations = true
    '';

    registry = {
      nixpkgs = {
        from = {
          id = "nixpkgs";
          type = "indirect";
        };
        flake = inputs.nixpkgs;
      };
    };

    nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
  };
  documentation.nixos.enable = false;
}
