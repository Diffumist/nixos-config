{ pkgs, inputs, lib, ... }:
{
  nixpkgs.config.allowUnfree = true;
  nix = {
    # Ensure that flake support is enabled.
    package = pkgs.nixFlakes;

    useSandbox = true;

    trustedUsers = [ "root" "diffumist" ];

    binaryCaches = lib.mkBefore [
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://diffumist.cachix.org"
    ];
    binaryCachePublicKeys = [ "diffumist.cachix.org-1:MtOScqYJitYQ6A8Py53l1/hzM1t18TWkkfVwi/kqlHk=" ];
    gc = {
      automatic = true;
      dates = "Wed";
      options = "--delete-older-than 8d";
    };

    autoOptimiseStore = true;
    # optimise = {
    #   automatic = true;
    #   dates = [ "Thu" ];
    # };

    extraOptions = ''
      experimental-features = nix-command flakes
      flake-registry = /etc/nix/registry.json

      download-attempts = 5
      connect-timeout = 15
      stalled-download-timeout = 10

      keep-outputs = true
      keep-derivations = true
    '';

    registry = {
      nixpkgs = {
        from = { id = "nixpkgs"; type = "indirect"; };
        flake = inputs.nixpkgs;
      };
    };

    nixPath = [
      "nixpkgs=${inputs.nixpkgs}"
    ];
  };
}
