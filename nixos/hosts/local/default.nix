{ system, self, nixpkgs, inputs,this,... }:
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs.inputs = inputs;
  modules = [
    ./configuration.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (final: prev: import ./../../overlays.nix final prev)
        inputs.rust-overlay.overlay
        inputs.berberman.overlay
        this.overlay
      ];
    }
  ];
}

