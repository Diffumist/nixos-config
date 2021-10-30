{ system, nixpkgs, inputs, self, ... }:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.ss
    self.nixosModules.nix-config
    self.nixosModules.sops-nix
    {
      nixpkgs.overlays = [
        inputs.rust-overlay.overlay
      ];
    }
  ];
}
