{ system, nixpkgs, inputs, ... }:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        inputs.rust-overlay.overlay
      ];
    }
  ];
}
