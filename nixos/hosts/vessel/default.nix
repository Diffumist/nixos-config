{ system, nixpkgs, inputs, self, ... }:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.ss
    {
      nixpkgs.overlays = [
        inputs.rust-overlay.overlay
      ];
    }
  ];
}
