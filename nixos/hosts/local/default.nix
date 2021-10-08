{ system, nixpkgs, inputs, self, ... }:
let this = import ./../../../pkgs; in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    self.nixosModules.clash
    {
      nixpkgs.overlays = [
        (final: prev: import ./../../../overlays final prev)
        inputs.rust-overlay.overlay
        inputs.berberman.overlay
        this.overlay
      ];
    }
  ];
}

