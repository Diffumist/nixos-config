{ system, nixpkgs, inputs, ... }:
let this = import ./../../../pkgs; in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        inputs.rust-overlay.overlay
        this.overlay
      ];
    }
  ];
}


